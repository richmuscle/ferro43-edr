# ADR-008: Public Repository Posture

**Status:** Accepted

## Context

GitHub's free tier does not support branch protection rules on private repositories. ferro43-edr requires branch protection (signed commits, required status checks, linear history) as a governance mechanism from Phase 1 onward. The alternatives are: upgrade to GitHub Pro for a single-operator personal project, or make the repository public and accept the exposure.

## Decision

The repository is public. It contains Ansible roles, detection rules, threat model documentation, CI configuration, and tooling — none of which include the operator's keys, secrets, workstation state, or identifying artifacts beyond a GitHub username. The operator's actual security posture is the applied state on the host, not the repo contents. Secrets are managed via ansible-vault and never committed; the vault password file is gitignored and excluded by pre-commit hooks.

## Consequences

- **The repo is a targeting profile.** A motivated attacker can read the threat model, detection rules, and hardening configuration to understand exactly what is and is not monitored. This reinforces the hostile-LAN posture (ADR-005), which already assumes the attacker knows the network topology. The threat model is designed to be defensible even when public — security through obscurity is not a control.
- **Anything committed is permanently world-visible.** A secret committed even briefly is compromised. Pre-commit hooks (detect-private-key, detect-aws-credentials) and the gitignore provide defense-in-depth, but the primary control is discipline: secrets live in ansible-vault, not in cleartext files.
- **Future GitHub features requiring a paid tier will need their own ADRs.** Branch protection is available on public free-tier repos, but features like required reviewers, CODEOWNERS enforcement, or repository rulesets may require Pro. Each such feature needs a cost-benefit ADR rather than a blanket upgrade.
