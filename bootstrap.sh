#!/usr/bin/env bash

echo "Setting up your Mac..."

# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update Homebrew recipes
brew update

# Install all our dependencies with bundle (See Brewfile)
brew tap homebrew/bundle
brew bundle

DOTFILES=`pwd`

# +----- Terminal -----+
# Set ZSH as default shell
chsh -s $(which zsh)

# Install Oh-my-zsh
if [ ! -d ~/.oh-my-zsh ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi
# Delete default ~/.zshrc and link with backup
rm ~/.zshrc && ln -s $DOTFILES/_backup/.zshrc ~ && source ~/.zshrc

# Install global Composer packages
/usr/local/bin/composer global require laravel/installer

# Create Projects directory
if [ ! -d ~/Projects ]; then
  mkdir ~/Projects
fi

# Symlink the Mackup config file to the home directory
if [ ! -L ~/.mackup.cfg ]; then
  ln -s $DOTFILES/.mackup.cfg ~/.mackup.cfg
fi
mackup restore

# Symlink the global .gitingore and register it to global git config
if [ ! -L ~/.gitignore ]; then
  ln -s $DOTFILES/_backup/.gitignore ~
fi
git config --global core.excludesfile ~/.gitignore

# Register SublimeText `subl .` command
if [ ! -L /usr/local/bin/subl ]; then
  ln -s /Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl /usr/local/bin/subl
fi

# add binaries in /usr/local/bin
for file in $(find bin -type f); do
    if [[ ! -L /usr/local/${file} ]]; then
        ln -s `pwd`/$file /usr/local/bin
    fi
done