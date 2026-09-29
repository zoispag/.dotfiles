# kubectl, velero and argocd completions come from brew's site-functions
# (_opencode is generated into fpath by ~/.zshrc). `k` and `v` are aliases,
# which zsh expands before completing, so they need no extra wiring.
compdef kubecolor=kubectl

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -la --no-user --no-permissions --no-filesize --no-time --icons=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -la --no-user --no-permissions --no-filesize --no-time --icons=always $realpath'
