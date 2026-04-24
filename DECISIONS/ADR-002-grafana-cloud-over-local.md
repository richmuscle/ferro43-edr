# ADR-002: Grafana Cloud Free Tier Over Local Log Storage

**Status:** Accepted

## Context

Logs from auditd, Falco, and system journals need a searchable destination with enough retention to support incident investigation. The options are:

1. **Local log storage** (Elasticsearch, OpenSearch, Loki on-host): Full control, works offline, but consumes significant RAM and disk on the host being monitored.
2. **Grafana Cloud Loki free tier**: 50 GB/month ingest, 14-day retention, managed infrastructure, zero local resource cost.
3. **Self-hosted remote Loki**: Requires a second machine, which violates the single-host constraint.

## Decision

Use Grafana Cloud Loki free tier as the log destination. Vector ships logs from the host; Grafana Cloud provides storage, search, and dashboarding.

The reasons:

1. **Zero local RAM cost.** The 2 GB security tooling budget is fully available for detection and hardening. Local Elasticsearch alone would consume 1-2 GB.
2. **Managed infrastructure.** No patching, no disk management, no backup of log storage. Operational burden matches a single operator.
3. **Free tier is sufficient.** A single host generating auditd + Falco + journal logs stays well within 50 GB/month. 14-day retention covers the realistic investigation window for a personal workstation.
4. **Off-host log storage is a security benefit.** If the host is compromised, logs already shipped to Grafana Cloud cannot be tampered with by the attacker.

## Consequences

- **Vendor dependency.** Grafana Labs could change free tier terms. Mitigation: Vector's output is configurable; switching to a different Loki endpoint or another backend is a config change, not a rewrite.
- **No log search when offline.** Mitigation: journald retains logs locally on a rolling basis; the RUNBOOK documents local query procedures for offline scenarios.
- **Data leaves the host.** Security logs are sent to a third party. auditd logs can contain command-line arguments, which may include secrets (passwords passed as CLI args, tokens in curl commands, environment variable dumps). This is a P0-class redaction defect if unaddressed. Mitigation: Vector pipeline includes redaction transforms as a reviewable artifact (`ansible/roles/vector/templates/redaction/`), applied before shipping. Redaction rules strip patterns matching tokens, passwords, and key material from auditd EXECVE records. The redaction config is tested in CI — a test log containing synthetic secrets must emerge clean.
- **14-day retention limit.** Investigations older than 14 days lose cloud log data. Accepted: for a personal workstation, 14 days is a realistic investigation window. Longer-term forensics would rely on local AIDE baselines and auditd archives.
