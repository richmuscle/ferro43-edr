# ADR-005: Hostile LAN Threat Model

**Status:** Accepted

## Context

Most personal workstation security setups implicitly trust the local network. Firewall rules allow LAN traffic, DNS uses whatever DHCP provides, mDNS and LLMNR are left enabled for convenience, and the assumption is that the home network is safe.

This assumption is wrong for a workstation that moves between networks (home, travel, coworking, conferences) and wrong even for a home network (compromised IoT devices, compromised routers, firmware backdoors, ISP-level interception).

## Decision

Every network this box connects to is treated as hostile. There is no trusted network tier. The security posture is identical whether the box is on the home LAN, a hotel wifi, or a conference network.

This means:

1. **Default-deny egress.** Only allowlisted destinations are reachable. Everything else is dropped and logged.
2. **Default-deny ingress.** Nothing listens on non-loopback interfaces. Every listener requires an ADR.
3. **DNS is pinned.** The system uses DNS-over-TLS via systemd-resolved with a pinned resolver. DHCP-provided DNS is ignored. If the pinned resolver is unreachable, DNS fails closed — it does not fall back to cleartext or DHCP DNS.
4. **LAN discovery protocols are disabled.** mDNS, LLMNR, NetBIOS Name Service, and WPAD are off. These are poisoning vectors.
5. **IPv6 RA is rejected.** accept_ra=0 on all interfaces unless an ADR explicitly exempts a specific interface.
6. **WireGuard with killswitch.** All non-loopback, non-WireGuard traffic is dropped when the tunnel is down. The tunnel comes up before the user session.
7. **NetworkManager is locked down.** No auto-connect to new networks, no silent auto-join, MAC address randomization per SSID.
8. **ARP is monitored.** ARP anomalies are detected via auditd and Falco rules, with weekly ARP table snapshots shipped to Loki.
9. **Container networking is restricted.** Docker/Podman bridges do not expose services beyond loopback. Any 0.0.0.0 bind requires an ADR.

## Consequences

- **Connectivity friction.** New networks require manual connection. Captive portals require a documented procedure (in RUNBOOK). Some LAN services (printers, NAS, casting) may not work without per-device ADR exceptions. Accepted: friction is the point.
- **DNS failure is visible.** If the DoT resolver is down and the WireGuard tunnel cannot reach an alternative, DNS stops. This is a feature: fail-closed is preferable to silently falling back to a poisonable resolver.
- **Debugging is harder.** Network troubleshooting on a box that drops most traffic by default requires understanding the allowlist. The RUNBOOK documents diagnostic procedures.
- **This is the most operationally expensive decision in the project.** Maintaining the egress allowlist, handling network changes, and debugging connectivity issues will consume ongoing operator time. Accepted: this is where the security value lives.
