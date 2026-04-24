# ADR-004: Six Pillars, One Tool Each

**Status:** Accepted

## Context

Security monitoring stacks tend to accumulate tools. Each tool addresses a real gap, but the aggregate creates operational burden, resource consumption, and interaction complexity that exceeds what a single operator can manage. The failure mode is not "too few tools" — it is "too many tools, none of them well-configured, all of them consuming resources."

This project runs on a shared workstation with a hard 2 GB RAM budget for all security tooling combined.

## Decision

The security stack is organized into six pillars. Each pillar gets exactly one component. Adding a second tool to a filled pillar is a cut-list violation by default and requires an ADR to justify.

| Pillar | Component | Why this one |
|--------|-----------|-------------|
| Runtime detection | Falco (modern_ebpf) | Mature rule ecosystem, detection-focused (ADR-003) |
| Audit trail | auditd | Kernel-native, zero additional dependencies, required for compliance patterns |
| Filesystem integrity | AIDE | Lightweight scheduled scanning, no daemon, minimal RAM when not scanning |
| Log shipping | Vector | Single binary, low resource usage, flexible routing, replaces Filebeat + Logstash |
| Host hardening | Ansible role | Configuration-as-code, not a running service, zero runtime cost |
| Network posture | Ansible role + WireGuard | Config-as-code for firewall/DNS/protocol hardening, WireGuard for tunnel |

Plus zero-RAM foundation components that are not pillars because they have no runtime cost: Secure Boot, TPM2 LUKS, Yubikey, Renovate, SBOM.

## Consequences

- **Coverage gaps are visible.** If a threat in the threat model has no control, it is because no pillar covers it — not because the right tool wasn't added. Gaps are tracked in the coverage matrix.
- **No overlap or defense-in-depth within a pillar.** Accepted: defense-in-depth comes from having six different pillars looking at different layers (syscalls, audit log, filesystem, network), not from running two tools at the same layer.
- **Adding a tool is expensive.** It requires an ADR, a budget justification, and may require removing the incumbent. This is intentional friction.
- **The budget is divisible.** With six pillars and 2 GB, each pillar gets roughly 300 MB. Components that exceed their share must justify it.
