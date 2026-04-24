# ADR-001: Single Host, No Three-Tier SOC Architecture

**Status:** Accepted

## Context

Traditional security monitoring architectures separate concerns across tiers: sensors on endpoints, a collection/correlation layer (SIEM), and an analysis/response layer (TheHive, Cortex, case management). This pattern exists because SOCs manage hundreds or thousands of endpoints and need centralized correlation, team workflows, and case tracking.

ferro43-edr monitors one host, operated by one person. The host is a Fedora 43 workstation shared with gaming and daily driver use, with a hard security tooling budget of ≤ 2 GB RAM steady-state.

## Decision

All detection, audit, and hardening runs directly on the single host being monitored. Log shipping goes to Grafana Cloud Loki (free tier) for retention and search, but there is no local SIEM, no local correlation engine, no case management system, and no separate analysis tier.

The reasons:

1. **Operator count is one.** Case management, SOAR playbooks, and ticket-based triage workflows are designed for teams. For a single operator, the IR procedure is a decision tree in a runbook, not a ticket system.
2. **Resource budget.** A local Elasticsearch or OpenSearch instance for SIEM would consume the entire 2 GB RAM budget alone, leaving nothing for actual detection.
3. **Attack surface.** Every additional service on the host is an additional attack surface. A SIEM stack (Elasticsearch + Kibana + ingestion pipeline) is a large, complex surface with its own CVE history — on the very host it is supposed to protect.
4. **Correlation is simple at N=1.** With one host, correlation is "grep the logs." Grafana Cloud's LogQL handles this without local infrastructure.

## Consequences

- No local log search when offline. Accepted: the box is a workstation with an internet connection; offline operation is not the normal mode. The RUNBOOK documents how to query local journald as a fallback.
- No automated correlation rules. Accepted: Falco and auditd rules provide detection; cross-signal correlation at single-host scale is manual review, which is appropriate for a rotation of one.
- If monitoring requirements grow beyond one host, this architecture does not scale. Accepted and named: this project is permanently scoped to one host. Scaling would be a new project, not an extension of this one.
