# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

ZSH_THEME="agnoster"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=(
  git
	docker
	composer
	zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Fix locale error in brew.
# See https://discourse.brew.sh/t/failed-to-set-locale-category-lc-numeric-to-en-ru/5092/20
export LC_ALL=en_US.UTF-8

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

#prompt_context() {
#  prompt_segment black `whoami`
#}
DEFAULT_USER=`whoami`

# Source my .dotfiles
for file in `find ~/.dotfiles/source -name ".*"`; do
    source "$file"
done

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
