# ~/.zshrc

export PATH=$HOME/bin:/usr/local/bin:$PATH
export LANG=en_US.UTF-8

if [[ -z "$XDG_CONFIG_HOME" ]]; then
  export XDG_CONFIG_HOME="${HOME}/.config"
fi

# Fix locale error in brew.
# See https://discourse.brew.sh/t/failed-to-set-locale-category-lc-numeric-to-en-ru/5092/20
export LC_ALL=en_US.UTF-8

#################
#  zinit setup  #
#################
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

############################
# zinit plugins & snippets #
############################
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-syntax-highlighting
zinit light Aloxaf/fzf-tab
zinit load atuinsh/atuin

autoload -U +X bashcompinit && bashcompinit
autoload -U +X compinit && compinit

zinit cdreplay -q

# Configure Devbox as the primary package manager
eval "$(devbox global shellenv --init-hook)"
# Configure zsh to initialize starship
eval "$(starship init zsh)"
# Configure direnv hook
eval "$(direnv hook zsh)"

# Shell integrations
eval "$(fzf --zsh)"
eval "$(atuin init zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(zellij setup --generate-auto-start zsh)"

###################
# Source dotfiles #
###################
for file in `find ~/.dotfiles/source -name ".*"`; do
	source "$file"
done
