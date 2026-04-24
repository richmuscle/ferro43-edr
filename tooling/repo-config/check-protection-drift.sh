#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${SCRIPT_DIR}/branch-protection.yml"

if ! command -v gh &>/dev/null; then
  echo "ERROR: gh CLI is required." >&2
  exit 1
fi

if ! command -v yq &>/dev/null; then
  echo "ERROR: yq is required." >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required." >&2
  exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
BRANCH=$(yq '.branch' "$CONFIG")
DRIFT=0

echo "Checking branch protection drift for ${REPO}:${BRANCH}"

LIVE=$(gh api "repos/${REPO}/branches/${BRANCH}/protection" 2>/dev/null) || {
  echo "DRIFT: No branch protection rules found on ${BRANCH}."
  exit 1
}

check_field() {
  local description="$1"
  local live_value="$2"
  local expected_value="$3"

  if [ "$live_value" != "$expected_value" ]; then
    echo "DRIFT: ${description}"
    echo "  expected: ${expected_value}"
    echo "  live:     ${live_value}"
    DRIFT=1
  fi
}

check_field "enforce_admins" \
  "$(echo "$LIVE" | jq -r '.enforce_admins.enabled')" \
  "$(yq '.protection.enforce_admins' "$CONFIG")"

check_field "required_linear_history" \
  "$(echo "$LIVE" | jq -r '.required_linear_history.enabled')" \
  "$(yq '.protection.required_linear_history' "$CONFIG")"

check_field "allow_force_pushes" \
  "$(echo "$LIVE" | jq -r '.allow_force_pushes.enabled')" \
  "$(yq '.protection.allow_force_pushes' "$CONFIG")"

check_field "allow_deletions" \
  "$(echo "$LIVE" | jq -r '.allow_deletions.enabled')" \
  "$(yq '.protection.allow_deletions' "$CONFIG")"

check_field "strict_status_checks" \
  "$(echo "$LIVE" | jq -r '.required_status_checks.strict')" \
  "$(yq '.protection.required_status_checks.strict' "$CONFIG")"

LIVE_CONTEXTS=$(echo "$LIVE" | jq -r '[.required_status_checks.contexts[]?] | sort | join(",")')
EXPECTED_CONTEXTS=$(yq -o=json '.protection.required_status_checks.contexts' "$CONFIG" | jq -r 'sort | join(",")')

check_field "required_status_check_contexts" "$LIVE_CONTEXTS" "$EXPECTED_CONTEXTS"

LIVE_SIGS=$(gh api "repos/${REPO}/branches/${BRANCH}/protection/required_signatures" 2>/dev/null | jq -r '.enabled' 2>/dev/null || echo "false")
EXPECTED_SIGS=$(yq '.protection.required_signatures' "$CONFIG")

check_field "required_signatures" "$LIVE_SIGS" "$EXPECTED_SIGS"

if [ "$DRIFT" -eq 0 ]; then
  echo "No drift detected."
else
  echo ""
  echo "Run 'make apply-branch-protection' to reconcile."
  exit 1
fi
