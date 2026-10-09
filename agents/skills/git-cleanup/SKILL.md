---
name: git-cleanup
description: >-
  Clean up a git repository's stale worktrees and local branches: remove
  worktrees and delete branches whose pull requests are merged (or closed and
  abandoned), while keeping anything with an open PR, uncommitted changes, or
  unpushed work. Use this skill whenever the user asks to clean up, prune, or
  tidy worktrees or branches — phrases like "delete merged branches", "check the
  worktrees and delete what's not needed", "clean up old branches", "prune
  worktrees", "remove stale branches", or "git housekeeping". Works with
  squash-merged PRs, where `git branch --merged` misses them.
---

# Git cleanup: worktrees and branches

Goal: leave the repo with only the default branch plus branches that still have
work in flight. Squash merges mean `git branch --merged` is unreliable, so
decide from the PR state on GitHub and the upstream tracking state, not from
ancestry alone.

## 1. Gather state (read-only)

Run from the repo root:

```bash
git fetch --prune --quiet
git worktree list
git branch -vv
default=$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)
for b in $(git for-each-ref --format='%(refname:short)' refs/heads); do
  [ "$b" = "$default" ] && continue
  echo "$b: $(gh pr list --head "$b" --state all --json number,state \
    --jq '.[] | "#\(.number) \(.state)"' | tr '\n' ' ')"
done
```

For every worktree other than the main one, check for uncommitted work:

```bash
git -C <worktree-path> status --short
```

Also glance at `git stash list`. Stashes are not tied to a worktree, so removing
one does not remove them, but mention any stash whose name mentions a branch you
are deleting.

## 2. Classify each branch

| Situation | Action |
|---|---|
| PR **MERGED** | delete |
| PR **CLOSED**, not merged, upstream `gone` | delete, and list it in the summary so the user sees it |
| PR **CLOSED**, not merged, upstream still exists | keep; ask |
| PR **OPEN** | keep |
| No PR, upstream `gone` | check `git log origin/<default>..<branch>`. If it's empty, delete. Otherwise keep and ask, because it may be unpushed work |
| No PR, never pushed (no upstream) | keep; ask |
| Default branch, or the currently checked-out branch | never delete |

If several PRs share a head branch, the newest one decides.

A worktree can be removed when its branch is classified **delete** and
`git status --short` in it is empty. If it has changes, keep it and report the
files.

## 3. Act

Only do the unambiguous ones without asking (merged, or closed with the upstream
gone, and the worktree is clean). Batch everything that's ambiguous into a
single question.

```bash
git worktree remove <path>      # no --force; if it refuses, stop and report why
git worktree prune
git branch -D <branch> ...      # -D is needed because squash merges aren't ancestors
```

Do not delete remote branches unless the user asks. GitHub usually deletes the
head branch on merge anyway. If they ask, use `git push origin --delete <branch>`,
and only for merged PRs.

## 4. Report

Keep it short:
- worktrees removed (branch name, not the full temp path)
- branches deleted (count, plus any closed-unmerged ones named)
- what was kept and why (open PR #N, uncommitted changes, unpushed commits)
- confirm that only local branches were deleted, unless you also deleted remote ones

Finish with `git worktree list && git branch -vv` so the final state is visible.
