# Contributing

This is a single-operator project. Contributions are welcome but the scope is deliberately narrow. Read [PRINCIPLES.md](PRINCIPLES.md) and [THREAT-MODEL.md](THREAT-MODEL.md) before proposing changes.

## Before You Start

1. Check the [cut list](PRINCIPLES.md). If your idea involves a cut-list tool, write an ADR arguing for it and open a discussion — do not submit a PR.
2. Check existing [ADRs](DECISIONS/). Your change may conflict with an existing decision.
3. If your change is non-trivial, open an issue first to discuss the approach.

## Commit Standards

- **Conventional Commits** are required. The commit-msg hook enforces this.
- **Signed commits** are required. Unsigned commits are rejected by CI on protected branches.
- **Small commits** with real messages. Each commit should be reviewable in isolation.
- No "wip", "fix", or "update" as standalone commit messages.

Format: `type(scope): description`

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`

Scopes are **required** and enforced by commitlint. Allowed scopes:

`hardening`, `network-posture`, `wireguard`, `falco`, `auditd`, `aide`, `vector`, `backup`, `ci`, `docs`, `deps`, `meta`

Adding a new scope requires updating `.commitlintrc.yml` — this is intentional friction.

Examples:

```text
feat(falco): add detection for container escape via nsenter
fix(network-posture): close egress gap for UDP/53 to non-resolver
docs(runbook): add chaos drill writeup for WireGuard endpoint failure
test(auditd): add trigger script for suid binary execution rule
```

## Testing Requirements

Every change must have corresponding tests:

| What you changed | Required test |
|-----------------|---------------|
| Ansible role | Molecule converge + idempotence |
| Detection rule (Falco/auditd) | Trigger script + expected output |
| Network control | Verifier in `tooling/network-posture-verify/` |
| Performance-sensitive component | Perf regression gate pass |
| Firewall rule | Positive and negative test in verifier |

A detection without a trigger script is not done. A role without Molecule is not done.

## ADR Process

Non-trivial decisions require an Architecture Decision Record in `DECISIONS/`:

1. Create a new file: `DECISIONS/ADR-NNN-short-title.md`
2. Follow the existing format: Status, Context, Decision, Consequences
3. ADRs are immutable once accepted — supersede with a new ADR, don't edit old ones
4. If your change contradicts an existing ADR, your PR must include a superseding ADR

## Branch Protection

- `main` is protected. Direct pushes are not accepted.
- PRs require CI to pass: lint, Molecule, detection tests, perf gate, network verifier.
- PRs require signed commits.
- Branch protection rules are versioned in `tooling/repo-config/`.

## Code Review

The operator reviews all PRs. Review focus:

- Does this introduce a dependency? Was it discussed?
- Does this implicitly trust the LAN? (If yes: stop, flag it.)
- Is there a test?
- Does this stay within the SLO budget?
- Is there an ADR if needed?

## Style

- Ansible: YAML, fully qualified collection names, no `command`/`shell` when a module exists
- Detection rules: ATT&CK mapping, rationale comment, tuning notes
- Shell: POSIX where possible, bash where necessary, shellcheck clean
- Python (tooling): black, ruff, type hints
