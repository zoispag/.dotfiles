# Completions are cached by _zcache (see zsh/zshrc) -- generating them live costs
# ~430ms warm / ~1.3s cold, since each one is a separate process invocation.

# Autocomplete for kubectl
# NB: `complete -F __start_kubectl k` used to live here, but __start_kubectl only
# exists in `kubectl completion bash` -- under the zsh script the alias got no
# completion at all. compdef is the zsh-native equivalent.
_zcache kubectl-completion kubectl kubectl completion zsh
compdef k=kubectl
compdef kubecolor=kubectl

# Autocomplete for velero
_zcache velero-completion velero velero completion zsh
compdef v=velero

# Autocomplete for ArgoCD
_zcache argocd-completion argocd argocd completion zsh

# Autocomplete for OpenCode
_zcache opencode-completion opencode opencode completion

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -la --no-user --no-permissions --no-filesize --no-time --icons=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -la --no-user --no-permissions --no-filesize --no-time --icons=always $realpath'
