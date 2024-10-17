# oh-my-zsh inspired
alias ..="cd ../"
alias ...="cd ../.."

# Better replacements (eza, bat, zoxide)
alias ls='eza --git --icons=always'
alias cat='bat --paging never --theme DarkNeon --style plain'
alias catn='bat --paging never --theme DarkNeon --style=rule,header,numbers'
alias fzfp='fzf --preview "bat --style=rule,numbers --color=always {}"'

alias watch='viddy'

# Traversal
alias dl="cd ~/Downloads"
alias dot="cd ~/.dotfiles"
alias pj="cd ~/Projects"

# Dotfiles in VSCode
alias codedot="code ~/.dotfiles"
alias dotcode="code ~/.dotfiles"

# List declared aliases, exports, functions, paths
alias aliases="alias | sed 's/=.*//'"
alias exports="export | sed 's/=.*//'"
alias functions="declare -f | grep '^[a-z].* ()' | sed 's/{$//'"
alias paths='echo -e ${PATH//:/\\n}'

# Network
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias ipl="ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'"
alias speedtest="wget -O /dev/null http://speed.transip.nl/1gb.bin"
alias hosts='sudo vi /etc/hosts'

# macOS
alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"
alias btr="battery-status"
alias kraken='open -na GitKraken --args -p "$(git rev-parse --show-toplevel)"'

# AWS
alias awsadmin='export AWS_PROFILE=admin'

# Docker
alias drmf='docker rm --force'
alias drmi='docker rmi'
alias dpsa='docker ps -a'
alias ctop='docker run --rm -ti -v /var/run/docker.sock:/var/run/docker.sock --name ctop quay.io/vektorlab/ctop:latest'

# docker compose
alias dps='docker compose ps'
alias dup='docker compose up -d'
alias ddown='docker compose down'
alias dstart='docker compose start'
alias dstop='docker compose stop'
alias drr='ddown && dup'
alias dbuild='COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker compose build'
alias drb='ddown && dbuild && dup'
alias dpull='docker compose pull'

# typos 🙈
alias dokcer='docker'
alias docker-compose='docker compose'
alias dokcer-compose='docker compose'
alias docker-composer='docker compose'
alias cd..="cd .."

# Docker tools
alias trivy='docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $HOME/Library/Caches:/root/.cache/ aquasec/trivy --ignore-unfixed --light --no-progress'

# DevOps
alias tf='terraform'
alias tg='terragrunt'

# Laravel
alias a='php artisan'

# Laravel Dusk
alias dusk='a dusk --debug'
alias ddf='a dusk --debug --filter'
alias ddg='a dusk --debug --group='

# Cypress
alias cy:open='npm run cy:open'
alias cy:run='npm run cy:run'
