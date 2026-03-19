#!/usr/bin/env bash
# Unit tests for the jq filters used in the terraform-renovate-merge skill.
# Run with: bash tests/test_jq_filters.sh
# Requires: jq

set -uo pipefail

PASS=0
FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$actual" = "$expected" ]; then
    echo "  ✅ $desc"
    ((PASS++))
  else
    echo "  ❌ $desc"
    echo "     expected: $expected"
    echo "     actual:   $actual"
    ((FAIL++))
  fi
}

# ---------------------------------------------------------------------------
# CI AGGREGATION FILTER
# Ignores SKIPPED and NEUTRAL; produces SUCCESS / FAILURE / PENDING / NO_CHECKS
# ---------------------------------------------------------------------------

CI_FILTER='.statusCheckRollup // [] |
  map(select(.conclusion != null and .conclusion != "SKIPPED" and .conclusion != "NEUTRAL")) |
  if length == 0 then "NO_CHECKS"
  elif all(.conclusion == "SUCCESS") then "SUCCESS"
  elif any(.conclusion == "FAILURE") then "FAILURE"
  else "PENDING"
  end'

run_ci() { echo "$1" | jq -r "$CI_FILTER"; }

echo ""
echo "=== CI aggregation filter ==="

assert_eq "all SUCCESS → SUCCESS" "SUCCESS" "$(run_ci '{"statusCheckRollup":[{"conclusion":"SUCCESS"},{"conclusion":"SUCCESS"}]}')"
assert_eq "one FAILURE → FAILURE" "FAILURE" "$(run_ci '{"statusCheckRollup":[{"conclusion":"SUCCESS"},{"conclusion":"FAILURE"}]}')"
assert_eq "has PENDING (IN_PROGRESS) → PENDING" "PENDING" "$(run_ci '{"statusCheckRollup":[{"conclusion":"SUCCESS"},{"conclusion":"IN_PROGRESS"}]}')"
assert_eq "empty array → NO_CHECKS" "NO_CHECKS" "$(run_ci '{"statusCheckRollup":[]}')"
assert_eq "null rollup → NO_CHECKS" "NO_CHECKS" "$(run_ci '{}')"
assert_eq "all SKIPPED → NO_CHECKS" "NO_CHECKS" "$(run_ci '{"statusCheckRollup":[{"conclusion":"SKIPPED"},{"conclusion":"SKIPPED"}]}')"
assert_eq "all NEUTRAL → NO_CHECKS" "NO_CHECKS" "$(run_ci '{"statusCheckRollup":[{"conclusion":"NEUTRAL"}]}')"
assert_eq "SKIPPED mixed with SUCCESS → SUCCESS" "SUCCESS" "$(run_ci '{"statusCheckRollup":[{"conclusion":"SUCCESS"},{"conclusion":"SKIPPED"}]}')"
assert_eq "NEUTRAL mixed with SUCCESS → SUCCESS" "SUCCESS" "$(run_ci '{"statusCheckRollup":[{"conclusion":"SUCCESS"},{"conclusion":"NEUTRAL"}]}')"
assert_eq "SKIPPED mixed with FAILURE → FAILURE" "FAILURE" "$(run_ci '{"statusCheckRollup":[{"conclusion":"SKIPPED"},{"conclusion":"FAILURE"}]}')"
assert_eq "SKIPPED + NEUTRAL + SUCCESS → SUCCESS" "SUCCESS" "$(run_ci '{"statusCheckRollup":[{"conclusion":"SUCCESS"},{"conclusion":"SKIPPED"},{"conclusion":"NEUTRAL"}]}')"

# ---------------------------------------------------------------------------
# TERRAFORM CHECK DETECTION
# PR is terraform-relevant if any check name contains "terraform" or "tflint"
# ---------------------------------------------------------------------------

TF_CHECK_FILTER='.statusCheckRollup // [] |
  map(select(.name != null)) |
  map(.name | ascii_downcase) |
  any(test("terraform|tflint"))'

run_tf() { echo "$1" | jq -r "$TF_CHECK_FILTER"; }

echo ""
echo "=== Terraform check detection filter ==="

assert_eq "check named 'terraform plan' → true" "true" "$(run_tf '{"statusCheckRollup":[{"name":"terraform plan","conclusion":"SUCCESS"}]}')"
assert_eq "check named 'Terraform / Plan' → true" "true" "$(run_tf '{"statusCheckRollup":[{"name":"Terraform / Plan","conclusion":"SUCCESS"}]}')"
assert_eq "check named 'tflint' → true" "true" "$(run_tf '{"statusCheckRollup":[{"name":"tflint","conclusion":"SUCCESS"}]}')"
assert_eq "check named 'TFLint (us-east-1)' → true" "true" "$(run_tf '{"statusCheckRollup":[{"name":"TFLint (us-east-1)","conclusion":"SUCCESS"}]}')"
assert_eq "non-terraform check → false" "false" "$(run_tf '{"statusCheckRollup":[{"name":"build","conclusion":"SUCCESS"}]}')"
assert_eq "no checks → false" "false" "$(run_tf '{}')"
assert_eq "mixed: terraform + other → true" "true" "$(run_tf '{"statusCheckRollup":[{"name":"build","conclusion":"SUCCESS"},{"name":"terraform validate","conclusion":"SUCCESS"}]}')"

# ---------------------------------------------------------------------------
# PLAN POSITIVE CHECK
# Returns true if any comment contains "No changes. Your infrastructure..."
# ---------------------------------------------------------------------------

PLAN_POS_FILTER='.comments |
  map(select(.body | test("No changes\\. Your infrastructure"; "i"))) |
  length > 0'

run_pos() { echo "$1" | jq -r "$PLAN_POS_FILTER"; }

echo ""
echo "=== Plan positive check (no-changes comment) ==="

assert_eq "comment has exact phrase → true" "true" "$(run_pos '{"comments":[{"body":"No changes. Your infrastructure matches the configuration."}]}')"
assert_eq "comment has phrase (mixed case) → true" "true" "$(run_pos '{"comments":[{"body":"no changes. your infrastructure matches the configuration."}]}')"
assert_eq "comment shows changes → false" "false" "$(run_pos '{"comments":[{"body":"Plan: 1 to add, 0 to change, 0 to destroy."}]}')"
assert_eq "no comments → false" "false" "$(run_pos '{"comments":[]}')"
assert_eq "unrelated comment → false" "false" "$(run_pos '{"comments":[{"body":"renovate updated the lock file"}]}')"

# ---------------------------------------------------------------------------
# PLAN NEGATIVE CHECK
# Returns true if any comment contains "Plan: X to add/change/destroy"
# If true, the PR must be SKIPPED (it has actual changes)
# ---------------------------------------------------------------------------

PLAN_NEG_FILTER='.comments |
  map(select(.body | test("Plan:.*to add|Plan:.*to change|Plan:.*to destroy"; "i"))) |
  length > 0'

run_neg() { echo "$1" | jq -r "$PLAN_NEG_FILTER"; }

echo ""
echo "=== Plan negative check (changes-present comment) ==="

assert_eq "comment has 'Plan: 1 to add' → true (has changes)" "true" "$(run_neg '{"comments":[{"body":"Plan: 1 to add, 0 to change, 0 to destroy."}]}')"
assert_eq "comment has 'Plan: 0 to add, 1 to change' → true" "true" "$(run_neg '{"comments":[{"body":"Plan: 0 to add, 1 to change, 0 to destroy."}]}')"
assert_eq "comment has 'Plan: 0 to add, 0 to change, 1 to destroy' → true" "true" "$(run_neg '{"comments":[{"body":"Plan: 0 to add, 0 to change, 1 to destroy."}]}')"
assert_eq "no-changes comment only → false (safe)" "false" "$(run_neg '{"comments":[{"body":"No changes. Your infrastructure matches the configuration."}]}')"
assert_eq "no comments → false" "false" "$(run_neg '{"comments":[]}')"

# ---------------------------------------------------------------------------
# COMBINED SAFETY GATE
# Safe = positive=true AND negative=false
# ---------------------------------------------------------------------------

echo ""
echo "=== Combined safety gate ==="

safe_pr() {
  local json="$1"
  local pos neg
  pos=$(echo "$json" | jq -r "$PLAN_POS_FILTER")
  neg=$(echo "$json" | jq -r "$PLAN_NEG_FILTER")
  if [ "$pos" = "true" ] && [ "$neg" = "false" ]; then
    echo "SAFE"
  else
    echo "UNSAFE"
  fi
}

assert_eq "no-changes comment only → SAFE" "SAFE" \
  "$(safe_pr '{"comments":[{"body":"No changes. Your infrastructure matches the configuration."}]}')"

assert_eq "changes comment only → UNSAFE" "UNSAFE" \
  "$(safe_pr '{"comments":[{"body":"Plan: 2 to add, 0 to change, 0 to destroy."}]}')"

assert_eq "old no-changes + new changes → UNSAFE (re-trigger scenario)" "UNSAFE" \
  "$(safe_pr '{"comments":[{"body":"No changes. Your infrastructure matches the configuration."},{"body":"Plan: 1 to add, 0 to change, 0 to destroy."}]}')"

assert_eq "no comments at all → UNSAFE" "UNSAFE" \
  "$(safe_pr '{"comments":[]}')"

# ---------------------------------------------------------------------------
# SUMMARY
# ---------------------------------------------------------------------------

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
