# _shell

Personal zsh code — aliases, functions, exports, keybindings.

**Sourced** at runtime by `~/.zshrc` (via `find ~/.dotfiles/_shell -name ".*"`),
**not** symlinked by dotbot. This is the one thing here that isn't third-party
app config: everything else at the repo root (`nvim/`, `ghostty/`, `starship/`, …)
is an app's config that dotbot links into place.

## Layout

- `base/` — default shell setup loaded everywhere (aliases, exports, functions, …)
- `_kyos/` — work-profile overrides
- `secrets/.import.zsh` — 1Password env importer (`importEnv`)

## Secrets

`**.secrets` are git-ignored and must never be committed.
