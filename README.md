# My .dotfiles

## Install using dotbot

```bash
git clone https://github.com/zoispag/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install
```

## Claude Code plugins and MCP servers

Global MCP servers ship as a local plugin, enabled through a managed-settings
drop-in that `./install` symlinks (needs `sudo` once) — see
[`claude/plugins/README.md`](claude/plugins/README.md).
