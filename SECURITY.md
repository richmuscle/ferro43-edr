# Security Policy

## Scope

This repository contains Ansible roles, detection rules, and tooling for hardening a single personal workstation. It is not a product. It does not have users beyond the operator.

That said, the configurations and detection rules in this repo may be adopted by others. Vulnerabilities in the security controls themselves — rules that fail to detect, firewall rules that fail open, hardening that weakens posture — are worth reporting.

## Reporting a Vulnerability

If you find a security issue in this repo:

1. **Do not open a public issue.**
2. Email the maintainer at the address listed in [CODEOWNERS](CODEOWNERS).
3. Include: what you found, which file(s) are affected, and what the impact is.
4. You will receive a response on a best-effort basis, typically within 7 days.

## What Counts as a Vulnerability

- A detection rule that can be trivially bypassed in a way the rule claims to cover
- A firewall rule that fails open when it should fail closed
- A hardening configuration that weakens security posture
- A secret, credential, or token committed to the repository
- An Ansible role that creates a privilege escalation path
- A CI configuration that can be manipulated to skip security gates

## What Does Not Count

- Missing detections for threats not listed in [THREAT-MODEL.md](THREAT-MODEL.md)
- Suggestions to add tools on the [cut list](PRINCIPLES.md)
- Performance improvements that do not affect security posture
- Cosmetic issues

## Supported Versions

This repo targets a single host running the current Fedora release. There are no versioned releases in the traditional sense. The `main` branch represents the current intended state.

## Security Practices

- All commits to `main` are signed via Yubikey
- Branch protection is enforced as code in `tooling/repo-config/`
- Dependencies are managed by Renovate with security auto-merge
- SBOMs are generated for locally built binaries
- No secrets are stored in the repository; secrets are managed via `ansible-vault`
