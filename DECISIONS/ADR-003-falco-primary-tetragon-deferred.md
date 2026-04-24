# ADR-003: Falco as Primary Runtime Detection, Tetragon Deferred

**Status:** Accepted

## Context

The runtime detection pillar needs one eBPF-based tool for syscall and process monitoring. The two serious candidates are:

1. **Falco** (modern_ebpf driver): Mature, large rule ecosystem, CNCF graduated, well-documented rule language. Higher baseline resource usage than Tetragon.
2. **Tetragon**: Lower overhead, policy-based enforcement (can block, not just detect), newer, smaller rule ecosystem, tighter Kubernetes integration.

Both use eBPF. Both can monitor syscalls, process execution, file access, and network connections. The one-pillar-one-tool constraint (ADR-004) means picking one.

## Decision

Falco with the modern_ebpf driver is the primary runtime detection engine. Tetragon is deferred, not rejected — it goes on the cut list for now, with a clear re-evaluation trigger.

The reasons:

1. **Rule maturity.** Falco ships with a large, community-maintained ruleset that covers common ATT&CK techniques out of the box. For a single operator, starting with a mature ruleset and tuning down is faster than building a policy set from scratch.
2. **Documentation and community.** Falco's documentation, rule-writing guides, and troubleshooting resources are substantially more extensive. For a project that values reproducibility and runbook quality, this matters.
3. **Detection-first posture.** This project prioritizes detecting and alerting over enforcement/blocking. Falco is designed for detection. Tetragon's enforcement capabilities are its differentiator, but enforcement on a daily-driver workstation carries risk of blocking legitimate workflows.
4. **Resource budget compatibility.** Falco with modern_ebpf on a single host with tuned rules fits within the 2 GB aggregate budget. Measured, not assumed — the perf regression gate (Phase 8) will prove this continuously.

**Re-evaluation trigger:** If Falco's resource usage exceeds its allocated share of the 2 GB budget after tuning, or if enforcement (not just detection) becomes a requirement, re-evaluate Tetragon via a new ADR that supersedes this one.

## Consequences

- No runtime enforcement. Falco detects and alerts; it does not block. A detected attack proceeds until the operator responds. Accepted: for a single-operator workstation, automated blocking carries high false-positive risk.
- Falco's resource usage must be monitored. The perf regression gate is the enforcement mechanism.
- Tetragon is on the cut list. Proposing it requires a new ADR. The re-evaluation trigger is documented above.
