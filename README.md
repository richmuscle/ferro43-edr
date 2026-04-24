# ferro43-edr

Single-host endpoint detection and hardening for a Fedora 43 workstation, built under the assumption that any local network is hostile.

This is not a SOC. It is an EDR plus hostile-LAN network posture, with discipline, reproducibility, and tested detections. The value is the rigor, not the component count.

This repository contains tooling, threat model, and documentation. The operator's workstation state, keys, secrets, and identifying artifacts are not part of this repo.

## Host

- Fedora 43, Intel i9-14900K, RTX 5070 Ti, 32 GB RAM
- Shared with gaming and daily driver use — gaming is a first-class workload
- Single operator, single box

## Security Tooling Budget

All security tooling combined must stay within:

| Metric | Limit |
|--------|-------|
| RAM resident steady-state | ≤ 2 GB |
| RAM transient peak (scans) | ≤ 700 MB |
| Sustained CPU | ≤ 5% |
| Gaming impact | Zero perceptible |

Violations are build-gate failures.

## Stack

Six pillars, one component each. No exceptions without an ADR.

| Pillar | Component |
|--------|-----------|
| Runtime detection | Falco (modern_ebpf) |
| Audit trail | auditd |
| Filesystem integrity | AIDE (scheduled) |
| Log shipping | Vector → Grafana Cloud Loki (free tier) |
| Host hardening | Ansible role |
| Network posture | Ansible role + WireGuard with killswitch |

Plus zero-RAM foundation: Secure Boot, TPM2 LUKS with PCR binding, Yubikey signed commits, Renovate, SBOM.

## Threat Model

Full details in [THREAT-MODEL.md](THREAT-MODEL.md). The load-bearing assumption: **any LAN is hostile**. Home, travel, coworking, event wifi — all treated identically.

In scope: on-path LAN attacker, remote-via-application attacker, lateral movement, egress beaconing. Out of scope (named): sustained physical access, nation-state adversary.

## Design Principles

See [PRINCIPLES.md](PRINCIPLES.md). Short version: one tool per pillar, every detection tested, every control verified, boring technology preferred, cut list enforced.

## Decisions

Architecture decisions are recorded in [DECISIONS/](DECISIONS/). Every non-trivial choice gets an ADR. Key decisions:

- [ADR-001](DECISIONS/ADR-001-single-host-no-three-tier.md) — Single host, no three-tier SOC architecture
- [ADR-002](DECISIONS/ADR-002-grafana-cloud-over-local.md) — Grafana Cloud over local log storage
- [ADR-003](DECISIONS/ADR-003-falco-primary-tetragon-deferred.md) — Falco primary, Tetragon deferred
- [ADR-004](DECISIONS/ADR-004-six-pillars-one-tool-each.md) — Six pillars, one tool each
- [ADR-005](DECISIONS/ADR-005-hostile-lan-threat-model.md) — Hostile LAN threat model
- [ADR-006](DECISIONS/ADR-006-wireguard-vpn-transport.md) — WireGuard as VPN transport
- [ADR-007](DECISIONS/ADR-007-encrypted-dns-resolver.md) — Encrypted DNS resolver choice (DoT via systemd-resolved)

## Repo Layout

```
ferro43-edr/
├── README.md
├── THREAT-MODEL.md
├── PRINCIPLES.md
├── RUNBOOK.md
├── SECURITY.md
├── CONTRIBUTING.md
├── CODEOWNERS
├── CHANGELOG.md
├── LICENSE
├── DECISIONS/
├── ansible/
│   ├── inventory/
│   ├── roles/{hardening,network_posture,wireguard,falco,auditd,aide,vector,backup}/
│   ├── playbooks/
│   └── molecule/
├── detections/
│   ├── falco/{rules,tests}/
│   ├── auditd/{rules,tests}/
│   ├── network/{rules,tests}/
│   └── coverage-matrix.md
├── tooling/
│   ├── detection-test-harness/
│   ├── perf-regression/
│   ├── network-posture-verify/
│   └── repo-config/
└── .github/workflows/
```

## Build Phases

| Phase | Scope |
|-------|-------|
| 0 | Documents: threat model, principles, ADRs |
| 1 | Ansible skeleton, repo governance, CI plumbing |
| 2 | Hardening role: sysctl, SELinux, firewalld, AIDE |
| 3 | Network posture role: egress deny, DoT, protocol hardening |
| 4 | WireGuard role + killswitch |
| 5 | Secure Boot, TPM2 LUKS, PCR binding |
| 6 | auditd rules, then Falco rules — tested detections |
| 7 | Detection test harness + network posture verifier |
| 8 | Performance regression CI |
| 9 | Vector + Grafana Cloud Loki |
| 10 | Supply chain finishing |
| 11 | RUNBOOK completion, chaos drills, recovery drill |

## License

[MIT](LICENSE)
