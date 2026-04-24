# ADR-006: WireGuard as VPN Transport

**Status:** Accepted

## Context

The hostile-LAN threat model (ADR-005) requires that all traffic leaving the box traverses a trusted encrypted tunnel, with a killswitch that drops all non-loopback traffic when the tunnel is down. This provides:

1. Encryption of all traffic against LAN-level interception
2. A single egress point that can be monitored and allowlisted
3. Protection against captive portal TLS interception
4. IP address privacy from the local network

The VPN transport options considered:

- **WireGuard**: Kernel-native on Linux, minimal attack surface (~4,000 lines of code in-kernel), low CPU overhead, stateless reconnection, single UDP port.
- **OpenVPN**: Userspace, larger codebase, higher CPU overhead for crypto, TLS-based (more complex handshake), mature but heavier.
- **IPsec (strongSwan)**: Complex configuration, IKEv2 negotiation overhead, broad attack surface, enterprise-oriented.

## Decision

WireGuard is the VPN transport. The tunnel runs as a systemd service ordered before the user session. firewalld enforces the killswitch: when the WireGuard interface is down, all non-loopback egress is dropped.

The reasons:

1. **Kernel-native.** WireGuard is in-tree since Linux 5.6. No userspace daemon for the data plane. Lower latency, lower CPU, smaller attack surface.
2. **Simplicity.** Configuration is a single file. Key exchange is one command. There is no certificate infrastructure, no TLS negotiation, no session state to manage.
3. **Resource cost.** WireGuard's CPU overhead for encryption is negligible on a modern CPU with AES-NI/ChaCha20 acceleration. It fits within the 5% sustained CPU budget without measurable impact.
4. **Reconnection behavior.** WireGuard silently reconnects when the endpoint becomes reachable again. No session renegotiation, no handshake timeout. This matters for a workstation that sleeps, changes networks, and resumes.
5. **Killswitch integration.** firewalld zones make it straightforward to implement "drop everything except WireGuard and loopback" as the default policy.

**Endpoint class is a separate architectural decision.** This ADR selects WireGuard as the protocol. The choice of endpoint class — self-hosted VPS, commercial VPN provider, or split-tunnel to specific destinations — affects trust model, availability, and cost. It is deferred to ADR-008, which must be written before Phase 4 implementation begins. The Ansible role accepts the endpoint as a variable.

## Consequences

- **Single point of failure.** If the WireGuard endpoint is unreachable and the killswitch is active, the box has no network connectivity beyond loopback. This is by design (fail-closed), but means endpoint availability matters. The RUNBOOK documents the procedure for temporary killswitch override when the endpoint is down.
- **Pre-tunnel leak window.** Between NetworkManager bringing an interface up and firewalld applying zone rules, there is a race where traffic could egress unencrypted. Mitigation direction: set firewalld's default zone to `drop` so new interfaces inherit deny-all before any rules are evaluated. The WireGuard interface is promoted to its permitted zone only after the tunnel handshake succeeds. This ordering is enforced in the Ansible role and verified in the network posture test suite.
- **UDP only.** WireGuard uses UDP. Networks that block non-TCP traffic (some corporate firewalls, some captive portals) will prevent the tunnel from establishing. Mitigation: the RUNBOOK documents fallback procedures. Adding a TCP wrapper (e.g., udp2raw) would require an ADR.
- **No built-in obfuscation.** WireGuard traffic is identifiable by DPI. This is out of scope — the threat model does not include network-level censorship or traffic analysis by the network operator beyond what the hostile-LAN model covers.
- **Endpoint trust.** Traffic exits at the WireGuard endpoint, which must be trusted. The trust implications depend on the endpoint class selected in ADR-008.
