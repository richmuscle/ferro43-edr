# Threat Model

This document is load-bearing. Every design decision, detection rule, and network control in ferro43-edr traces back to the assumptions here. If a control does not map to a threat in this document, it needs justification. If a threat in this document has no control, it needs a plan or an explicit acceptance.

## Asset Under Protection

A single Fedora 43 workstation used for software development, gaming, and daily driver tasks. Contains:

- Source code (proprietary and open-source contributions)
- SSH keys, GPG keys, API tokens
- Browser sessions with authenticated state
- Personal files and credentials
- Development toolchains and dependencies

The operator is a single individual. There is no team, no SOC, no on-call rotation beyond one person.

## Core Assumption: Any LAN Is Hostile

This is the central, non-negotiable assumption. It applies uniformly to:

- Home network (compromised IoT, compromised router, roommate's infected machine)
- Travel network (hotel, airport, conference)
- Coworking space (shared infrastructure, unknown peers)
- Event wifi (DEF CON, meetups, hackathons)
- Mobile hotspot (carrier-level interception in adversarial jurisdictions)

There is no "trusted network." The box defends itself at every layer regardless of what network it is connected to. Any design decision that implicitly trusts the LAN is a bug.

## Threat Actors

### T1: On-Path LAN Attacker

**Capability:** Layer 2/3 access on the same broadcast domain. Can inject, intercept, and modify traffic. May control network infrastructure (rogue AP, compromised router, malicious DHCP server).

**Motivation:** Credential theft, session hijacking, lateral movement to this box, traffic interception, man-in-the-middle for supply chain attacks on package downloads.

**Techniques in scope:**

| Technique | ATT&CK | Control |
|-----------|--------|---------|
| ARP spoofing/poisoning | T1557.002 | Periodic `ip neigh` snapshots shipped to Loki; anomaly rules designed in Phase 6 |
| mDNS/LLMNR/NBT-NS poisoning | T1557.001 | Protocols disabled system-wide |
| Rogue DHCP (DNS hijack) | T1557.003 | DNS pinned to DoT resolver, DHCP DNS ignored, fail-closed |
| Rogue DNS server | T1557 | DoT with pinned resolver, cleartext DNS blocked at firewall |
| IPv6 Router Advertisement spoofing | T1557 | accept_ra=0 on all interfaces unless ADR-exempted |
| Captive portal TLS interception | No clean ATT&CK mapping | Documented procedure in RUNBOOK, WireGuard killswitch |
| SMB relay | T1557.001 | SMB client disabled, no outbound 445/139 |
| WPAD injection | T1557 | WPAD disabled, no proxy auto-detection |
| DNS spoofing (cleartext) | T1557 | All DNS over TLS, cleartext DNS dropped at firewall |
| Evil twin AP | T1557.004 | NetworkManager: no auto-connect to new networks, MAC randomization |

### T2: Remote-via-Application Attacker

**Capability:** Code execution through a legitimate application the operator runs. Does not require LAN access.

**Motivation:** Persistent access, credential theft, lateral movement, cryptocurrency mining, ransomware.

**Techniques in scope:**

| Technique | ATT&CK | Control |
|-----------|--------|---------|
| Browser exploit / drive-by | T1189 | Default-deny egress, Falco process monitoring |
| Malicious dependency (npm, pip, cargo) | T1195.002 | SBOM, Renovate, egress allowlist, Falco exec monitoring |
| Compromised dev tool / IDE extension | T1195.002 | Falco exec/file monitoring, egress allowlist |
| Malicious document (PDF, office) | T1204.002 | Falco process tree monitoring |
| Watering hole via dev resource | T1189 | Egress allowlist, DNS monitoring |
| Container escape | T1611 | Falco container monitoring, no privileged containers without ADR |

### T3: Lateral Movement Attacker

**Capability:** Has compromised another device on the same network. Attempting to reach this box.

**Motivation:** Expand foothold, access development credentials, pivot to cloud infrastructure.

**Techniques in scope:**

| Technique | ATT&CK | Control |
|-----------|--------|---------|
| Network service scanning | T1046 | Default-deny ingress, no listeners on non-loopback |
| Exploitation of listening service | T1210 | No services exposed, listening-port audit in CI |
| SSH brute force | T1110 | No SSH listener by default (ADR required to enable) |
| Credential stuffing against exposed service | T1110 | No services exposed |
| Pass-the-hash against SMB/WinRM | T1550 | Not applicable (Linux), SMB disabled |
| CUPS/cups-browsed exploitation (CVE-2024-47176 class) | T1210 | cups-browsed masked, CUPS removed or socket-activated local-only; firewalld blocks UDP/631 ingress; see ADR-005 |
| avahi-daemon exploitation | T1210 | avahi-daemon masked; mDNS disabled system-wide (ADR-005 point 4); firewalld blocks mDNS ingress |
| Container service exposure | T1210 | No 0.0.0.0 binds without ADR; Podman/Docker bridges loopback-only (ADR-005 point 9) |

### T4: Post-Compromise Egress Beacon

**Capability:** Code execution achieved on the box. Attempting to establish C2 or exfiltrate data.

**Motivation:** Maintain persistence, exfiltrate credentials and source code.

**Techniques in scope:**

| Technique | ATT&CK | Control |
|-----------|--------|---------|
| DNS tunneling | T1071.004 | DNS pinned to DoT, non-resolver DNS dropped, anomaly detection |
| HTTPS beacon to arbitrary domain | T1071.001 | Default-deny egress, allowlist-only HTTPS |
| Non-standard port egress | T1571 | All non-allowlisted egress dropped and logged |
| Process injection for egress | T1055 | Falco process monitoring, ptrace restrictions |
| Reverse shell | T1059 | Falco detection, egress deny |
| Data exfil via legitimate service | T1567 | Egress allowlist limits destinations, Falco monitors |

## Out of Scope (Named)

### OS1: Sustained Physical Access Attacker (Evil Maid)

**What it means:** An attacker with repeated, unmonitored physical access to the hardware.

**Why out of scope:** Single-operator home workstation. Sustained physical access implies a threat model (cohabitation with adversary, office theft) that requires controls beyond software — tamper-evident seals, hardware security modules for storage keys, or air-gapping. These are disproportionate for this use case.

**Partial mitigations in place anyway:** Secure Boot, TPM2 LUKS with PCR binding (detects boot chain tampering), Yubikey for commit signing (physical token required). These address opportunistic physical access, not a determined adversary with repeat access.

### OS2: Nation-State Adversary

**What it means:** An adversary with zero-day capability, firmware-level implants, supply chain compromise of hardware vendors, or lawful intercept capability at the ISP level.

**Why out of scope:** The tooling budget, operator count, and threat surface of a personal workstation do not justify the cost of defending against this class. Nation-state defense requires dedicated security teams, hardware provenance chains, and operational security practices that conflict with daily-driver use. Naming this explicitly prevents scope creep into controls that sound good but provide no real protection against this tier.

## Attack Surface Summary

| Surface | Exposure | Primary Control |
|---------|----------|-----------------|
| Network ingress | Default-deny, no listeners | firewalld + listening-port audit |
| Network egress | Allowlist-only | firewalld + Falco + Vector to Loki |
| DNS | DoT pinned, cleartext blocked | systemd-resolved + firewall |
| LAN protocols | mDNS/LLMNR/NBT-NS/WPAD disabled | Network posture role |
| IPv6 | RA rejected, accept_ra=0 | sysctl hardening |
| ARP | Monitored, not prevented | Periodic `ip neigh` snapshots to Loki; anomaly rules in Phase 6 |
| Wireless | No auto-connect, MAC randomized | NetworkManager config |
| Boot chain | Secure Boot + TPM2 PCR binding | UEFI + systemd-boot + LUKS |
| Packages | Renovate + SBOM + allowlisted repos | Supply chain role |
| Containers | No 0.0.0.0 binds, no privileged | Falco + Ansible audit |
| Browser | Profile hardening documented | Phase 10 |
| Process execution | Falco eBPF monitoring | Falco rules + alerts |
| File integrity | AIDE scheduled scans | AIDE + Vector |

## Validation

Every threat with a "Control" column entry must have:

1. An implementation (Ansible role, config file, or documented procedure)
2. A test (detection trigger, verifier script, or chaos drill)
3. A mapping in the detection coverage matrix

Threats without all three are tracked as gaps in the coverage matrix until resolved.
