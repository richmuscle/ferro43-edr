# ADR-007: Encrypted DNS via DoT (systemd-resolved)

**Status:** Accepted

## Context

The hostile-LAN threat model (ADR-005) requires that DNS queries cannot be intercepted, spoofed, or redirected by an on-path attacker. Cleartext DNS (UDP/53) is trivially interceptable and spoofable on any hostile LAN. The options:

1. **DNS-over-TLS (DoT, port 853)**: Encrypts DNS queries in a TLS session to a trusted resolver. Supported natively by systemd-resolved.
2. **DNS-over-HTTPS (DoH, port 443)**: Encrypts DNS queries as HTTPS requests. Blends with web traffic, harder to block. Not natively supported by systemd-resolved — requires a local proxy (e.g., dnscrypt-proxy).
3. **DNSCrypt**: Older encrypted DNS protocol. Smaller resolver ecosystem. Requires dnscrypt-proxy.

All three solve the core problem: encrypting DNS against LAN interception. The differences are in implementation complexity, tooling requirements, and network-level properties.

## Decision

Use DNS-over-TLS via systemd-resolved with a pinned resolver. DHCP-provided DNS is ignored. Cleartext DNS (UDP/53, TCP/53) to any destination other than localhost is dropped at the firewall. If the pinned DoT resolver is unreachable, DNS fails closed.

The resolver choice: **Quad9 (9.9.9.9, tls://dns.quad9.net)** as primary, **Cloudflare (1.1.1.1, tls://one.dot.one.one.one)** as fallback.

The reasons:

1. **Native support.** systemd-resolved supports DoT without additional software. No new daemon, no new dependency, no new attack surface. This aligns with the one-pillar-one-tool principle — DNS resolution is not a pillar, so it should not introduce a new component.
2. **Fail-closed behavior.** systemd-resolved with `DNSOverTLS=yes` (strict mode) refuses to fall back to cleartext. Combined with firewall rules dropping cleartext DNS, this creates a hard fail-closed posture.
3. **Simplicity over stealth.** DoH's advantage is that it blends with HTTPS traffic, making it harder for network operators to block DNS. This is a censorship-resistance property. The threat model does not include censorship resistance — it includes LAN interception. DoT solves the interception problem without the complexity of a local HTTPS proxy.
4. **Resolver choice rationale.** Quad9 primary: threat-intelligence-based blocking of known malicious domains, no logging policy, operated by a nonprofit. Cloudflare fallback: broad anycast availability, strong uptime record, DoT support. Both support DNSSEC validation.

**Note on naming:** The project spec originally named this ADR "DoH-resolver-choice." The implementation uses DoT, not DoH, because systemd-resolved supports DoT natively. If DoH is specifically needed (e.g., for networks that block port 853), that would require adding dnscrypt-proxy or a similar component, which would need its own ADR as a new dependency.

## Consequences

- **Port 853 can be blocked.** Some restrictive networks block DoT (port 853). When this happens and WireGuard is also blocked, DNS is unavailable. The RUNBOOK documents the procedure: temporary killswitch override with manual DNS configuration, or use a mobile hotspot. Adding DoH as a fallback would require a new ADR.
- **Two resolver dependencies.** Quad9 or Cloudflare outages could cause DNS failures. Mitigation: two resolvers with automatic fallback. Complete failure of both is extremely unlikely but would trigger fail-closed behavior.
- **No custom filtering.** Unlike Pi-hole or AdGuard Home (both on the cut list by implication — they are local DNS services), this provides encryption but not content filtering. Accepted: content filtering is not in the threat model.
- **DHCP DNS is ignored.** This may cause confusion on networks where DNS-based service discovery is expected (corporate networks, some hotel networks). Accepted: this is the hostile-LAN model working as intended.
