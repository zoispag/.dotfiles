# ~/.zshrc

export PATH=$HOME/bin:/usr/local/bin:$PATH
export LANG=en_US.UTF-8

# Fix locale error in brew.
# See https://discourse.brew.sh/t/failed-to-set-locale-category-lc-numeric-to-en-ru/5092/20
export LC_ALL=en_US.UTF-8

# Source my .dotfiles
for file in `find ~/.dotfiles/source -name ".*"`; do
    source "$file"
done

eval "$(starship init zsh)"
eval "$(direnv hook zsh)"
