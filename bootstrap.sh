#!/usr/bin/env bash

echo "Setting up your Mac..."

# Check for devbox and install if we don't have it
if test ! $(which devbox); then
	curl -fsSL https://get.jetify.com/devbox | bash
fi

# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Update Homebrew recipes
brew update

# Install all our dependencies with bundle (See Brewfile)
brew tap homebrew/bundle
brew bundle

DOTFILES=$(pwd)

# +----- Terminal -----+
# Set ZSH as default shell
chsh -s $(which zsh)

# Delete default ~/.zshrc and link with backup
rm ~/.zshrc && ln -s "$DOTFILES"/_backup/.zshrc ~ && source ~/.zshrc

# Link global devbox with backup and install global devbox packages
rm -f ~/.local/share/devbox/global/default/devbox.json \
	&& ln -s "$DOTFILES"/_backup/devbox.json ~/.local/share/devbox/global/default/devbox.json \
	&& refresh-global

# Delete default starship config and link with backup
rm ~/.config/starship.toml && ln -s "$DOTFILES"/_backup/starship.toml ~ && source ~/.config/starship.toml

# zellij config
ln -s ~/.dotfiles/_backup/zellij ~/.config/zellij

# Install global Composer packages
/usr/local/bin/composer global require laravel/installer

# Create Projects directory
if [ ! -d ~/Projects ]; then
  mkdir ~/Projects
fi

# Symlink the Mackup config file to the home directory
if [ ! -L ~/.mackup.cfg ]; then
  ln -s "$DOTFILES"/.mackup.cfg ~/.mackup.cfg
fi
mackup restore

# Symlink the global .gitignore and gitconfig
if [ ! -L ~/.gitignore ]; then
  ln -s "$DOTFILES"/_backup/.gitignore ~
fi
if [ ! -L ~/.gitconfig ]; then
  ln -s "$DOTFILES"/_backup/.gitconfig ~
fi

# Register SublimeText `subl .` command
if [ ! -L /usr/local/bin/subl ]; then
  ln -s /Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl /usr/local/bin/subl
fi

# add binaries in /usr/local/bin
for file in $(find bin -type f); do
    if [[ ! -L /usr/local/${file} ]]; then
        ln -s "$(pwd)/$file" /usr/local/bin
    fi
done
