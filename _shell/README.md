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
- `secrets/.keychain.zsh` — `syncSecrets` copies the "Keychain Secrets" 1Password
  item into the macOS Keychain; every shell exports those variables from there

## Secrets

Secret environment variables live in the 1Password item "Keychain Secrets"
(personal account, Safe vault), one field per variable in its `ENTRIES` section.
`syncSecrets` copies them into the login Keychain (`dotfiles-env.*`) and every
shell exports them from there, so no secret is kept in a file.

- Add or change a secret: edit the item, run `syncSecrets`, open a new shell.
- New Mac: sign in to `op`, then run `syncSecrets` once.

Personal or work-only shell code that shouldn't be public goes in
`~/.dotfiles-private/shell/`, linked into `private/` by that repo's dotbot.

`**.secrets` stay git-ignored as a safety net and must never be committed.
