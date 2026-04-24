# Principles

These are the governing design principles for ferro43-edr. They are not aspirational — they are constraints. A change that violates a principle requires an ADR that explicitly names the principle being overridden and why.

## 1. The LAN Is Hostile

Any network this box connects to is assumed compromised. Home, travel, coworking, conference — identical posture. No design decision may implicitly trust the LAN. This assumption is load-bearing; see [THREAT-MODEL.md](THREAT-MODEL.md).

## 2. One Pillar, One Tool

Six security pillars. Each gets exactly one component. A second tool in a filled pillar is a cut-list violation by default and requires an ADR to justify. The pillars are: runtime detection, audit trail, filesystem integrity, log shipping, host hardening, network posture.

## 3. Every Claim Is Tested

A detection rule without a trigger script is not done. An Ansible role without Molecule is not done. A network control without a verifier is not done. A performance budget without a regression gate is not done. Untested claims are not claims.

## 4. The Budget Is a Build Gate

The security tooling resource budget (≤ 2 GB RAM steady-state, ≤ 700 MB transient, ≤ 5% CPU, zero gaming impact) is enforced in CI. A PR that breaches the SLO does not merge. The budget exists because this is a shared workstation, and gaming is a first-class workload.

## 5. Boring Technology

Prefer tools that have been running in production for years over tools that are architecturally elegant but young. Prefer fewer moving parts over more. Prefer configuration over code. Prefer deleting over adding. When two approaches are equivalent, pick the one with less operational surface.

## 6. Default Deny, Allowlist Up

Ingress: nothing listens on non-loopback by default. Egress: everything is dropped unless explicitly allowlisted. DNS: pinned to a chosen resolver, cleartext blocked. Every exception is an ADR.

## 7. ADRs Over Assumptions

Every non-trivial decision gets an Architecture Decision Record. Short: context, decision, consequences. The ADR is the artifact that says "we thought about this." Decisions without ADRs are accidents.

## 8. Cut List Discipline

The cut list exists. It names specific tools that are tempting, plausible, and rejected. If a cut-list item looks necessary, write the ADR arguing for it and stop. The operator decides. The cut list is not a suggestion — it is a constraint.

## 9. Single Operator Reality

There is one person. No SOC, no on-call rotation, no team. IR procedures, alert triage, and recovery plans must be designed for a rotation of one. Complexity that requires a team to operate is a bug.

## 10. Commits Are Small and Real

Conventional Commits, signed via Yubikey, with real messages. No "wip" on main. Main is protected. Every commit should be reviewable in isolation.

## 11. Reproducibility

Ansible roles converge idempotently. Detection tests produce deterministic results. The test harness uses pinned toolchains. If the box is lost, the repo plus a bare Fedora install rebuilds the security posture.

## 12. Honest Constraints

When something is out of scope, name it. When a control is partial, say so. When a threat is accepted rather than mitigated, document the acceptance. Security theater — controls that look good but provide no real protection — is worse than an honest gap.
