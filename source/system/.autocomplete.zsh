# Autocomplete for kubectl
source <(kubectl completion zsh)
complete -F __start_kubectl k
compdef kubecolor=kubectl

# Autocomplete for velero
source <(velero completion zsh)
complete -F __start_velero v

# Autocomplete for ArgoCD
source <(argocd completion zsh)

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -la --no-user --no-permissions --no-filesize --no-time --icons=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -la --no-user --no-permissions --no-filesize --no-time --icons=always $realpath'
