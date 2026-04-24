# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## [Unreleased]

## [0.0.1] - 2026-04-23

### Added

- `README.md` — project overview, stack, build phases, repo layout
- `THREAT-MODEL.md` — hostile-LAN threat model with ATT&CK mappings
- `PRINCIPLES.md` — 12 governing design constraints
- `SECURITY.md` — vulnerability reporting policy
- `CONTRIBUTING.md` — commit standards, testing requirements, ADR process
- `RUNBOOK.md` — section stubs for IR, chaos drills, recovery, network procedures
- `CODEOWNERS` — single owner
- `CHANGELOG.md` — this file
- `LICENSE` — MIT
- ADR-001: Single host, no three-tier SOC architecture
- ADR-002: Grafana Cloud free tier over local log storage
- ADR-003: Falco primary, Tetragon deferred
- ADR-004: Six pillars, one tool each
- ADR-005: Hostile LAN threat model
- ADR-006: WireGuard as VPN transport
- ADR-007: Encrypted DNS resolver (DoT via systemd-resolved)
