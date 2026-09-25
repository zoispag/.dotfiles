# Claude Code plugins

Local plugin marketplace (`dotfiles`) for Claude Code. Its main job is to keep
user-level MCP servers in git: user-scope MCPs added with `claude mcp add -s user`
live in `~/.claude.json`, which also holds session state and can't be versioned.
Servers defined in a plugin's `.mcp.json` load in every project, and `${VAR}` /
`${VAR:-default}` placeholders are expanded from the environment at startup, so no
secrets are committed.

## Plugins

- **mcps** — global MCP servers (mirrors `opencode/opencode.jsonc`, minus Vanta,
  which comes from the official Vanta plugin, and Slack, which comes from the
  claude.ai Slack connector and the org-provided `engineering` plugin).

## Install

Plugins are enabled declaratively, not with `claude plugin install`.
`../managed-settings.json` holds `enabledPlugins` and `extraKnownMarketplaces`, and
`./install` symlinks it into Claude Code's managed-settings drop-in dir:

```
/Library/Application Support/ClaudeCode/managed-settings.d/dotfiles.json -> ~/.dotfiles/claude/managed-settings.json
```

The directory is root-owned, so that dotbot step uses `sudo` and prompts for a
password only when the symlink is missing. On startup Claude Code installs any
enabled plugin that isn't installed yet. `~/.claude/settings.json` stays local and
uncommitted (it holds machine-specific `autoMode` and hooks).

Enabled plugins: `mcps@dotfiles`, `vanta@claude-plugins-official`,
`typesafe@typesafe-ai`, `armoctl@armosec`. Slack needs no install: it follows the claude.ai login.

Restart Claude Code, then check `/mcp`. Linear and Vanta use OAuth —
authenticate them from `/mcp`; the tokens are stored in the keychain, not in this repo.

Managed settings caveats:

- Values there are locked: `/plugin` can't disable them locally. Edit the file instead.
- Invalid JSON in the file stops Claude Code from starting.
- Only one managed source applies. If the org ever pushes server-managed settings
  from claude.ai, this file is skipped silently; `/status` shows which source is active.

After editing `mcps/.mcp.json`, bump `version` in `mcps/.claude-plugin/plugin.json`
and run `claude plugin marketplace update dotfiles` (or reinstall) so the change is
picked up.

## Required environment variables

Must be exported in the shell that launches `claude`; a server whose variable is
unset (and has no `:-default`) fails to load.

| Server          | Variables                                                        |
| --------------- | ---------------------------------------------------------------- |
| `github`        | `GITHUB_TOKEN`                                                   |
| `grafana_cloud` | `GRAFANA_CLOUD_URL`, `GRAFANA_CLOUD_SERVICE_ACCOUNT_TOKEN`       |
| `grafana_k8s`   | `GRAFANA_K8S_URL`, `GRAFANA_K8S_SERVICE_ACCOUNT_TOKEN`           |
| `argocd`        | `ARGOCD_BASE_URL`, `ARGOCD_API_TOKEN`                            |
| `zammad`        | `ZAMMAD_URL`, `ZAMMAD_HTTP_TOKEN`                                |

## Notes

- `zammad` temporarily points at a fork pending upstream
  [basher83/Zammad-MCP#310](https://github.com/basher83/Zammad-MCP/pull/310) (prompt
  `ticket_id` annotated `int`). Revert to
  `git+https://github.com/basher83/zammad-mcp.git` once it lands.
- Plugin servers are namespaced: tools show up as `mcp__plugin_mcps_<server>__*`.
