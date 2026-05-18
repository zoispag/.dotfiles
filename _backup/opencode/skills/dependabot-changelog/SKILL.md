---
name: dependabot-changelog
description: Fetch real release notes and changelogs for Dependabot PRs and post them as a structured PR comment. Use this skill whenever Dependabot opens a PR (or group PR) with dependency updates and the changelog is missing, empty, or unhelpful — especially when the user says things like "write the changelog", "Dependabot failed to publish the changelog", "post the release notes", "what changed in this PR", or "look at this Dependabot PR". Also trigger when the user shares a Dependabot PR URL and asks you to summarize or annotate it. This skill handles all package ecosystems: Composer/PHP, npm/JS, pip/Python, etc.
---

# Dependabot Changelog

Dependabot often groups many dependency bumps into a single PR but leaves the description blank or with only boilerplate. Your job is to fetch the actual release notes for each updated package and post a well-organized, useful comment on the PR.

## Workflow

### Step 1: Read the PR diff

Fetch the diff of the PR to identify every version change. For `composer.lock` or `package-lock.json` look for lines like:

```
-            "version": "3.379.3",
+            "version": "3.379.8",
```

Build a list of `{package, from_version, to_version, repo}` tuples. Infer the GitHub repo from the `source.url` field in the lockfile diff — it's almost always present.

Skip packages where only checksums/references changed but the version didn't.

### Step 2: Fetch release notes in parallel

For each package, fetch the release notes from GitHub. Use the GitHub MCP tools:

- `github_get_release_by_tag` — preferred, gives structured release body
- `github_list_releases` — use when jumping multiple minor/patch versions (e.g., 2.6.0 → 2.8.0) to catch intermediate releases

If a package skipped versions (e.g., 2.6.0 → 2.8.0), fetch ALL intermediate releases too — changelog for 2.7.0 matters.

Fire all release fetches **in parallel** — don't wait for one before starting the next.

For packages without GitHub releases (rare), try fetching `CHANGELOG.md` from the repo directly via `github_get_file_contents`.

### Step 3: Triage by importance

Before writing the comment, mentally sort packages into three buckets:

**🔴 Notable / Attention Required** — anything that warrants a closer look:
- New features that could affect how the app behaves (new driver, new auth mechanism, new config option)
- Security-adjacent fixes (crypto, auth, input validation, memory safety)
- Behavior changes that could break things silently
- Minor → minor version bumps (even if semver-patch, they sometimes carry meaningful changes)
- Packages central to the application's operation (error monitoring, queues, PDF generation, etc.)

**🟡 Standard Updates** — meaningful changes worth reading but low risk:
- Bug fixes and performance improvements in app-level packages
- New optional features that require opt-in
- Dependency version requirement updates

**🟢 Tooling / Dev-only** — packages used only in development:
- Test runners, static analysis, linters, code generation tools
- Symfony polyfills and other low-level shims (group these together to save space)

Use your judgment. A "patch" release to `sentry/sentry-php` that adds a new Monolog handler is more notable than a "minor" release to `symfony/polyfill-ctype`. Context matters.

### Step 4: Write and post the comment

Post a single comment to the PR using `github_add_issue_comment`. Structure it like this:

```markdown
## 📦 Changelog for this Dependabot update

### 🔴 Notable / Attention Required

---

#### `package/name` vX.Y.Z → vA.B.C
> [Release](link)

**⚠️ Short attention hook** (why this matters)

- Bullet 1
- Bullet 2

---

### 🟡 Standard Updates

---

#### `package/name` vX → vY
> [Release](link)

- Bullet 1

---

### 🟢 Tooling / Dev-only Updates

---

#### `package/name` vX → vY
> [Release](link)

- Brief description

#### `group/of-similar-packages` vX → vY (N packages)

`pkg-a`, `pkg-b`, `pkg-c` — all bumped together. Brief explanation of what these are and why the update is low-risk (e.g., "Symfony polyfills rarely introduce breaking changes in patch/minor updates").
```

**Attention hooks** — when a package belongs in 🔴, lead with a bolded `**⚠️ Short hook**` that immediately tells the reviewer *why* it matters. Don't bury the lede. Examples:
- `**⚠️ New driver: chrome-php/chrome (native Chrome PHP driver)**`
- `**⚠️ Security-adjacent: More stringent OID limits + OpenSSL 3.2+ PKCS1 fix**`
- `**⚠️ New feature: First-class Redis Cluster support**`

**Grouping** — when multiple packages are closely related and individually uninteresting (e.g., 8 `symfony/polyfill-*` packages all bumping from v1.35 → v1.37), group them under a single entry rather than listing each separately. This keeps the comment scannable.

**Intermediate versions** — when a package jumped multiple versions (e.g., 2.6.0 → 2.8.0), call that out and list changes from each intermediate release separately so nothing is missed.

**Tone** — write for a developer who needs to decide whether to merge this PR today or investigate first. Be factual, not promotional. Don't pad with filler like "This release includes many improvements." Get to the point.

## Tips

- If release notes are empty or just say "full changelog: link", follow the link or check git tags for commit messages.
- For AWS SDK PHP updates, the release notes are always additive new service/API support — these are always 🟢 unless you see a security advisory.
- For `nunomaduro/collision`, `phpunit`, `phpstan`, `rector` and similar dev tooling with no public release notes, note that and describe what changed based on the diff if visible.
- Don't post a comment if you genuinely have nothing to say — but this is rare. Even "no user-facing changes, internal refactor" is useful.
