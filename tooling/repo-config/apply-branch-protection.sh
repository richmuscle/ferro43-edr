#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${SCRIPT_DIR}/branch-protection.yml"

if ! command -v gh &>/dev/null; then
  echo "ERROR: gh CLI is required. Install: https://cli.github.com/" >&2
  exit 1
fi

if ! command -v yq &>/dev/null; then
  echo "ERROR: yq is required. Install: sudo dnf install yq" >&2
  exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
BRANCH=$(yq '.branch' "$CONFIG")

echo "Applying branch protection to ${REPO}:${BRANCH}"

CONTEXTS=$(yq -o=json '.protection.required_status_checks.contexts' "$CONFIG")
STRICT=$(yq '.protection.required_status_checks.strict' "$CONFIG")
ENFORCE_ADMINS=$(yq '.protection.enforce_admins' "$CONFIG")
REQUIRED_SIGNATURES=$(yq '.protection.required_signatures' "$CONFIG")
LINEAR_HISTORY=$(yq '.protection.required_linear_history' "$CONFIG")
ALLOW_FORCE=$(yq '.protection.allow_force_pushes' "$CONFIG")
ALLOW_DELETE=$(yq '.protection.allow_deletions' "$CONFIG")

gh api -X PUT "repos/${REPO}/branches/${BRANCH}/protection" \
  --input - << EOF
{
  "required_status_checks": {
    "strict": ${STRICT},
    "contexts": ${CONTEXTS}
  },
  "enforce_admins": ${ENFORCE_ADMINS},
  "required_pull_request_reviews": null,
  "restrictions": null,
  "required_linear_history": ${LINEAR_HISTORY},
  "allow_force_pushes": ${ALLOW_FORCE},
  "allow_deletions": ${ALLOW_DELETE}
}
EOF

if [ "$REQUIRED_SIGNATURES" = "true" ]; then
  gh api -X POST "repos/${REPO}/branches/${BRANCH}/protection/required_signatures" 2>/dev/null || true
fi

echo "Branch protection applied successfully."
echo "Verify at: https://github.com/${REPO}/settings/branches"
