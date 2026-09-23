---
name: copilot-feedback
description: Review and respond to GitHub Copilot's PR review comments. Reads unresolved Copilot review comments on the current PR, critically evaluates whether each suggestion is worth applying, applies code changes when they make sense, then replies to each comment. Use this skill whenever the user asks to handle Copilot feedback, process Copilot PR comments, review Copilot suggestions, respond to Copilot reviews, or clean up after a Copilot review. Also trigger when phrases like "deal with copilot comments", "apply copilot suggestions", "reply to copilot" or "address copilot feedback" appear.
---

# Copilot PR Feedback

Review unresolved Copilot PR review comments, decide which suggestions are worth applying, implement the good ones, and reply to all of them.

The core principle: be critical. Not every Copilot suggestion is worth acting on. Evaluate each comment on its merits — apply changes only when they genuinely improve the code. When in doubt, ask the user before making changes.

## Workflow

### Step 1: Get the current PR number

Use the GitHub MCP or `gh` CLI to identify the PR for the current branch:

```bash
gh pr view --json number,url,title
```

If no PR is open for the current branch, tell the user and stop.

### Step 2: Fetch unresolved Copilot review comments

Retrieve all review threads on the PR and filter for:
- Comments authored by **GitHub Copilot** (author login: `copilot-pull-request-reviewer` or similar bot)
- Threads that are **not resolved** (`isResolved: false`)

Use the GitHub MCP `get_review_comments` method on the PR. Group comments by thread.

### Step 3: Evaluate each comment critically

For each unresolved Copilot comment, read the suggestion carefully and assess:

**Apply the change if:**
- It fixes a genuine bug, security issue, or correctness problem
- It meaningfully improves readability without changing behavior
- It follows an established pattern in the codebase
- It removes clearly redundant or dead code

**Skip the change if:**
- It's purely stylistic and the existing style is consistent in the codebase
- It introduces unnecessary complexity
- It changes behavior in a non-obvious way
- The suggestion seems wrong or misunderstands the context
- It conflicts with how the rest of the codebase is written

**Ask the user if:**
- You're genuinely unsure whether the change is right
- The suggestion involves a significant behavioral change
- The comment touches something you don't have full context on

Use interview-style questions — one at a time, specific, easy to answer.

### Step 4: Apply changes where warranted

For each comment you've decided to act on, make the minimal targeted change. Do not refactor or improve unrelated code while you're here.

After making changes, run `lsp_diagnostics` on modified files to verify no new errors were introduced.

### Step 5: Reply to every comment

Reply to **all** unresolved Copilot comments, whether or not you made a change:

**If you applied the change:**
> "Applied — [brief description of what you changed and why it was a good call]."

**If you skipped the change:**
> "Skipping — [concise reason: e.g., 'existing style is consistent throughout the codebase', 'this would change behavior in an unintended way', 'the current implementation is intentional because X']."

Keep replies short and factual. Don't be defensive, but be clear about your reasoning.

Use the GitHub MCP `add_reply_to_pull_request_comment` to post replies.

## Key behaviors

- **Read before acting**: Always read the full comment and the surrounding code context before deciding.
- **Be conservative with changes**: A change that breaks something is worse than a slightly imperfect comment reply.
- **One thing at a time**: If you need to ask the user something, ask one question and wait for the answer before proceeding to the next ambiguous comment.
- **Don't ghost comments**: Every comment gets a reply, even the ones you disagree with.
- **Match existing patterns**: If the codebase consistently does something one way, that's usually intentional — don't "fix" it to match Copilot's generic suggestion.
