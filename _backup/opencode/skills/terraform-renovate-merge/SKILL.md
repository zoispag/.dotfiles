# --- agentskill.sh ---
# slug: terraform-renovate-merge
# owner: zoispag
# contentSha: 16dc486
# installed: 2026-03-19T00:00:00.000Z
# source: local
# ---
---
name: terraform-renovate-merge
description: Scans a GitHub org for open Renovate dependency-update PRs that run Terraform, checks if GitHub Actions passed and the terraform plan produced no infrastructure changes, then approves and merges them. Use this skill whenever the user asks to merge, approve, or clean up Renovate PRs in a GitHub org — especially phrases like "merge safe renovate PRs", "approve terraform renovate PRs", "clean up no-change renovate PRs", "merge renovate PRs with no changes", or "which renovate PRs can I auto-merge". Trigger even if the user doesn't say "terraform" explicitly — if they're in a terraform-heavy org and asking about renovate PR cleanup, this skill applies. Also covers non-Terraform-provider updates in terraform repos: GitHub Actions action updates, terraform tooling updates (terraform-ls, tflint, opentofu), and any other Renovate PR that runs a terraform plan and produces "No changes."
---

# Terraform Renovate PR Merge

Safely find, approve, and merge Renovate dependency-update PRs that have passed CI and whose Terraform plan produced zero infrastructure changes.

The core safety guarantee: two independent checks must both pass before a PR is touched — CI fully green, and the terraform plan explicitly says "No changes. Your infrastructure matches the configuration." If either check fails or is absent, the PR is skipped.

## Workflow

### Step 1: Discover all open Renovate PRs org-wide

Use `gh search prs` to cover the entire org in one shot. Never hardcode a repo list — repos get added over time and a static list will always be stale.

```bash
gh search prs \
  --author app/renovate \
  --state open \
  --owner <org> \
  --limit 100 \
  --json number,repository,title,url,statusCheckRollup
```

If the org has more than 100 open Renovate PRs, paginate with `--limit` and `--page`.

### Step 2: Identify terraform-running PRs via CI checks

The most reliable way to know if a PR runs terraform is to look at its actual CI checks — not its repo name or PR title, which are heuristics that can miss repos or over-include irrelevant ones.

For each PR, look at `statusCheckRollup`. A PR is terraform-relevant if it has any check whose name contains `terraform` or `tflint` (case-insensitive).

PRs with no checks at all, or only non-terraform checks, are out of scope for this workflow — skip them without reporting.

> **Why this matters**: Relying on repo name prefix (e.g. `tf-`) misses repos that run terraform but aren't named that way, and includes repos that have the prefix but don't run a plan on every PR. The checks are ground truth.

**What counts as a terraform-relevant PR title**: Do NOT filter by PR title. Any of the following are valid and must be included if their checks are terraform-relevant:

- Terraform provider/module updates: `update terraform-aws-modules/vpc to v5.x`
- GitHub Actions action updates in terraform repos: `update kyosenergy-engineering/tf-gh-actions action to v1.6.0`
- Terraform tooling updates: `update dependency terraform-ls to v0.38.6`, `update tflint to v0.x`, `update opentofu to v1.x`
- Helm/Docker image updates in repos where those feed terraform variables

All of these run `terraform plan` in CI, and if the plan shows "No changes", they are safe to merge.

### Step 3: Check CI status (ignoring SKIPPED/NEUTRAL)

For each terraform-relevant PR, determine if CI passed:

```bash
gh pr view <number> --repo <org>/<repo> \
  --json statusCheckRollup \
  --jq '.statusCheckRollup // [] |
    map(select(.conclusion != null and .conclusion != "SKIPPED" and .conclusion != "NEUTRAL")) |
    if length == 0 then "NO_CHECKS"
    elif all(.conclusion == "SUCCESS") then "SUCCESS"
    elif any(.conclusion == "FAILURE") then "FAILURE"
    else "PENDING"
    end'
```

**Critical**: `SKIPPED` and `NEUTRAL` conclusions must be ignored — they are not failures. Optional checks like Infracost are commonly SKIPPED on PRs where cost doesn't change, and that's fine. Only count checks that produced a real `SUCCESS` or `FAILURE` conclusion.

Skip PRs that are `FAILURE`, `PENDING`, or `NO_CHECKS`.

### Step 4: Verify the terraform plan shows no changes

For each CI-passing PR, the plan output must be in a bot comment. Run both checks together — the PR must satisfy both:

```bash
# Must be true: plan says "No changes"
gh pr view <number> --repo <org>/<repo> \
  --json comments \
  --jq '.comments | map(select(.body | test("No changes\\. Your infrastructure"; "i"))) | length > 0'

# Must be false: plan does NOT have a "Plan: X to add/change/destroy" line
gh pr view <number> --repo <org>/<repo> \
  --json comments \
  --jq '.comments | map(select(.body | test("Plan:.*to add|Plan:.*to change|Plan:.*to destroy"; "i"))) | length > 0'
```

A PR qualifies only if the first returns `true` **and** the second returns `false`.

> **Why two checks**: The "Plan:" line check catches cases where a PR has both a "no changes" comment (from an earlier run) and a later comment showing changes (from a re-triggered plan). Using only the positive check could produce false positives.

If there's no plan comment at all, skip the PR — the plan may not have completed or something went wrong.

### Step 5: Approve and merge qualifying PRs

For each PR that passed both checks:

```bash
gh pr review <number> --repo <org>/<repo> --approve
gh pr merge <number> --repo <org>/<repo> --squash
```

If merge fails because the branch is not up to date with base:
```bash
gh pr merge <number> --repo <org>/<repo> --squash --auto
```

`--auto` queues the merge once branch protection requirements are met. This is safe — the plan already confirmed no changes.

### Step 6: Report results

Present a table covering all terraform-relevant PRs examined:

| PR # | Repository | Title | CI | Plan | Action |
|------|------------|-------|----|------|--------|
| 42 | `tf-aws-compute` | update terraform aws to v6.x | ✅ | No changes | ✅ Merged |
| 43 | `tf-aws-compute` | update helm to v3.x | ✅ | Has changes | ⏭ Skipped (plan has changes) |
| 44 | `tf-aws-storage` | update terraform aws to v6.x | ⏳ | — | ⏭ Skipped (CI pending) |

Always show skipped PRs with the reason — the user needs to know what still requires attention. Non-terraform PRs (no terraform checks) are out of scope and don't need to appear in the table.

## Edge Cases

**Multiple plan comments**: Renovate sometimes re-triggers plans after a push. The dual check (positive "No changes" + negative "Plan: X") handles this — if any comment shows changes, the PR is excluded regardless of older "no changes" comments.

**PRs with only SKIPPED checks**: If all checks are SKIPPED/NEUTRAL and none produced real conclusions, treat as `NO_CHECKS` and skip — don't auto-merge without a real signal.

**Merge queue / branch protection**: If `gh pr merge --squash` fails with "not mergeable: head branch not up to date", retry with `--auto`. If it fails for other reasons (e.g. required reviewers), report it in the table and move on.

**Docker/non-provider Renovate PRs in terraform repos**: Repos like `tf-aws-sftpgo` can have PRs updating Docker image tags (e.g. `update caddy docker tag`). These still run `terraform plan` because the image is a terraform variable. They follow the same rules — if the plan shows no changes, merge; if it shows changes, skip.

**GitHub Actions action updates in terraform repos**: PRs like `update kyosenergy-engineering/tf-gh-actions action to v1.6.0` update the CI workflow actions themselves. They still run `terraform plan` as part of CI. The plan output is the safety signal — if it shows "No changes", the action update did not alter infrastructure behaviour and is safe to merge.

**Terraform tooling updates** (terraform-ls, tflint, opentofu, terraform itself): PRs like `update dependency terraform-ls to v0.38.6` update tool version pins (`.tool-versions`, `.terraform-version`, or similar config files). These do not change `.tf` resource definitions, so the plan consistently shows "No changes." Apply the same two-check rule — plan must say "No changes" and must NOT have a "Plan: X to add/change/destroy" line.

**Abandoned PRs**: Renovate sometimes marks stale PRs as "abandoned" in the title. Skip them.
