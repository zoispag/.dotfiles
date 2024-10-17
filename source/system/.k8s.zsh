#!/bin/bash

alias k='kubectl'
alias kubectl='kubecolor'

# kubectx + kubens
alias kns='kubens'
alias kcx='kubectx'
alias kctx='kubectx'

# kubectl get
alias kgn='kubectl get nodes'
alias kgp='kubectl get pods'
alias kgd='kubectl get deploy'
alias kgrs='kubectl get replicasets'
alias kgss='kubectl get statefulsets'
alias kgds='kubectl get daemonsets'
alias kgs='kubectl get secrets'
alias kgcm='kubectl get configmaps'
alias kgns='kubectl get namespaces'
alias kgsv='kubectl get svc'
alias kgj='kubectl get jobs'
alias kgcj='kubectl get cronjobs'

# velero
alias v='velero'
alias vgb='velero get backups'
alias vbd='velero backup describe'

# helm
# Function to store all helm-generated files after running `helm template`
function helmout () {
	local releaseName="$1";

	helm template --dry-run "$releaseName" . | awk -vout=out -F": " '$0~/^# Source: /{file=out"/"$2; print "Creating "file; system ("mkdir -p $(dirname "file"); echo -n "" > "file)} $0!~/^#/ && $0!="---"{print $0 >> file}'
}

# Retrieve raw secret values for the provided secret
function kds() {
  local secret="$1";
  kubectl get "secret/${secret}" -ojson | jq '.data | map_values(@base64d)';
}

# Attaches an ephimeral debug pod to the specified pod. Alpine by default.
# See https://www.youtube.com/watch?v=qKb6loAEPV0
function kdebug() {
  local pod="$1";
  local image="${2:-alpine}";
  kubectl debug "$pod" \
    --image "$image" \
    --stdin --tty \
    --share-processes \
    --copy-to "${pod}-debug";
  kubectl delete "pod/${pod}-debug";
}
