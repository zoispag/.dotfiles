---
name: dependency-update-safety
description: Assess whether a dependency-update pull request is safe to merge, fetch the real changelog/release notes when the bot left none, and post a structured verdict comment on the PR. Use this skill whenever the user shares a dependency-bump PR link (Renovate, Dependabot, Mend, etc.) and asks whether it is "safe to merge", to "confirm it's safe", to "check this update", "review this bump", "there's no changelog from renovate/dependabot", or "same for <PR link>". Works for any ecosystem — Helm charts, Docker tags, npm/pip/composer/cargo/go modules, GitHub Actions, Terraform providers — and any host repo.
---

# Dependency Update Safety

A bot (Renovate, Dependabot, Mend, etc.) opened a PR that bumps a dependency, but the changelog is missing, empty, or just boilerplate. The user wants a trustworthy answer to one question: **is this safe to merge?**

Your job: read the PR, fetch the *real* upstream changelog for every version in the range, triage the changes for risk, post a structured verdict comment on the PR, and give the user a concise merge recommendation.

Assess and report. **Never merge** unless the user explicitly asks you to in a follow-up.

## Workflow

### Step 1: Read the PR

Use the GitHub tools (`pull_request_read`) to fetch, in parallel:
- `get` — title, body, `mergeable_state`, labels, head/base SHA, author (confirm it's a bot).
- `get_diff` — the actual change. Confirm it is a pure version bump and note the exact `from → to` versions and the file changed.
- `get_status` — combined check status (state, `total_count`).

From the diff and title, build the update tuple(s): `{dependency, from_version, to_version, upstream_repo, ecosystem}`.

Infer the upstream repo from the PR body (Renovate/Dependabot usually link `source`/`redirect` URLs), the package registry, or the dependency name. If genuinely ambiguous, say so rather than guessing.

**Multi-hop bumps matter.** A `3.2.1 → 3.2.3` bump spans `3.2.2` *and* `3.2.3` — fetch changelogs for **every** intermediate version, not just the target.

### Step 2: Fetch the real changelog

Resolve where the upstream project actually publishes changelogs. Try these in order until you get real content:

1. **GitHub Releases** — `github_get_release_by_tag` for each version tag. Guess the tag format from the ecosystem:
   - Plain app/library: `v3.5.1`, `3.5.1`
   - Helm chart monorepos (e.g. `argoproj/argo-helm`): `argo-cd-10.3.3` (chart-name-prefixed)
   - Go modules / submodule tags: `sdk/v1.2.3`, `module/name/v1.2.3`
   Use `github_list_releases` to discover the real tag naming if a guess 404s.
2. **`CHANGELOG.md` in the repo** — `github_get_file_contents`. Many projects (e.g. Teleport) keep versioned changelogs here instead of Releases. Check the **release branch** (e.g. `branch/v18`, `release/1.x`) if the default branch's changelog doesn't cover the version yet.
3. **Chart-repo vs source-repo split** — Helm charts often live in a different repo than the app. The chart bump's only real change may be "bump bundled app image X → Y"; in that case follow through and fetch the *app's* changelog too (that's the substance).
4. **Commit that added the entry** — if a version's changelog was just added, find the commit (via `list_commits` on `CHANGELOG.md`) and read the file at that SHA.

Fire independent fetches in parallel.

#### When the changelog genuinely doesn't exist

Report it honestly — this is itself a useful signal. Common cases and how to read them:
- **Version tag missing upstream** (e.g. `v18.10.5` has no git tag) → likely a chart-only release or a skipped version. Verify with `github_get_tag` / `github_list_releases` and state the finding.
- **"Private security release"** language → the project (e.g. Teleport) withholds per-item detail until coordinated disclosure. This means the bump is a **security follow-up** — lean *toward* recommending it, and say why.
- **Skipped version** → e.g. changelog says "18.10.5 was skipped due to CI/CD issue". Note it so the range makes sense.

Never invent changelog entries. If you can't find one, say exactly where you looked and what you concluded.

### Step 3: Triage for risk

Sort every change in the range into buckets:

**🔴 Attention required** — anything that could break this deployment or needs a human decision:
- Breaking changes, removed/renamed config keys, CRD/schema changes, required migration steps
- Behavior changes that could silently alter runtime (defaults changed, auth flow changes)
- Version jumps that cross a **major** boundary, or **minor** bumps with notable feature/behavior shifts
- Explicit upgrade-order requirements (e.g. "upgrade auth/proxy before agents")
- Regressions the release notes themselves warn about

**🟢 / 🟡 Low-risk** — patch-level bug fixes, security fixes, CVE reductions, performance work, dependency bumps, additive optional features.

**Check whether a flagged change actually applies to *this* repo.** If a release fixes a crash triggered by overlapping config keys, grep the chart/values in the current workspace to see if those keys are even set. A fix that can't trigger here is a non-issue — say so. (This is the difference between a generic changelog dump and a real safety assessment.) Use `grep`/`glob` against the workspace when the current repo is checked out.

Also weigh:
- **Semver level**: patch < minor < major risk.
- **Blast radius**: is this a leaf component, an agent, or the control plane / a tool that manages the repo itself (e.g. Argo CD, the GitOps controller)? Call out self-managed-controller upgrades.
- **Security posture**: security/CVE fixes push *toward* merging.

### Step 4: Post the verdict comment

Post a single comment on the PR with `github_add_issue_comment`. Structure:

```markdown
## 📦 Changelog for this <bot> update

`<dependency>` **<from> → <to>** (<semver level>). <One line: why there was no changelog / where you sourced it.>

> [!NOTE]
> <Only if relevant: skipped version, private security release, chart-vs-app split, missing tag, etc.>

### 🟡 What changed

#### `<upstream>` <from> → <to>
> [Release / CHANGELOG](<link>)

<Grouped, triaged bullets. For multi-hop, one subsection per intermediate version.
Lead 🔴 items with a bold ⚠️ hook stating why it matters.>

---

### ✅ Merge assessment

- **Diff**: <what the diff actually is, e.g. single-line version bump in path>.
- <Breaking changes? Migration? Semver level?>
- <Does any flagged change apply to THIS repo? What you verified.>
- <Blast radius note.>

<Verdict line: "Safe to merge. ✅"  /  "Safe to merge, but note X."  /  "⚠️ Do NOT merge yet — <reason>.">
```

Keep it factual and scannable. Write for someone deciding whether to merge *today*. No filler.

### Step 5: Report to the user

Give a short summary in chat:
- The one-line verdict (safe / safe-with-caveat / not-yet).
- Link to the comment you posted.
- **Always surface merge-blockers you noticed** even if the changelog is clean, e.g.:
  - `mergeable_state: blocked` → branch protection needs an approval or a required check.
  - `get_status` state `pending` with `total_count: 0` → no checks have reported; confirm whether required checks are expected.
- Offer to investigate a `blocked` state or to merge, but wait for explicit confirmation.

## "Same for <link>" follow-ups

The user will often paste more PR links with just "same for <url>" or "sme for <url>". Treat each as a fresh run of this workflow on that PR. Keep the output format identical across PRs so they're easy to compare.

## Tips

- **Parallelize**: fetch PR `get`/`get_diff`/`get_status` together, and fire all changelog lookups at once.
- Bot PR bodies frequently link the Dependency Dashboard and the source repo — mine them before guessing.
- CVE comparison tables in release notes (common in Kubecost, etc.) are strong positive signals — summarize the trend (e.g. "High 69 → 30"), don't paste the whole table.
- Large changelog files may be truncated by the tool; that's fine — you only need the top entries covering the version range. Read the relevant slice rather than the whole file.
- Distinguish the **chart version** from the **app version** for Helm charts — they often differ, and the app version is what actually runs.
