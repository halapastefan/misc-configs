brew install --cask iterm2
brew install lazygit
brew install zoxide
brew install eza
brew install fd
brew install fzf
brew install --cask nikitabobko/tap/aerospace
brew install yazi
brew install --cask temurin # Java LTS
brew install caarlos0/tap/timer
brew install terminal-notifier
brew install bat
brew install --cask plexamp
brew install jq
brew install tree
brew install powerlevel10k
brew install stow
brew install ripgrep

# Symlink dotfiles
stow -t ~ dotfiles 

# Symlink scripts
mkdir ~/scripts
stow -t ~/scripts scripts
chmod +x /scripts/utils/development.sh
