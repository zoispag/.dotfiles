# My .dotfiles

## Install using dotbot

```bash
git clone https://github.com/zoispag/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install
```

## Sofka migration follow-up (dependency note)

The Sofka migration itself is tracked in PR #2 (`copilot/add-sofka-support`).
This follow-up intentionally does **not** recreate that migration on top of the
current `master` snapshot.

### Argo CD `sync-app` migration refinement

| k9s plugin | Sofka replacement | Status | Minimum Sofka version |
| --- | --- | --- | --- |
| `sync-app` (`Shift-S`, `argocd app sync $NAME`) | Select an Argo CD `Application` and press `t` for native actions (`sync-now`, `suspend`, `resume`) | Replaced by native controls (no Sofka plugin stanza needed) | `v0.22.0+` |

Compatibility evidence:

- Sofka release `v0.22.0` includes “add support ArgoCD Applications and
  ApplicationSets sync” in release notes.
- `docs/features.md` for `v0.22.0` documents `t`-menu native Argo CD controls
  for Applications/ApplicationSets and states no `argocd` binary is needed.

Behavior note: Sofka native actions operate against the selected Kubernetes
context/namespace in-session, not a separate `argocd` CLI login context.
