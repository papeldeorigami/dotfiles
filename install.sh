#!/bin/bash
# Install dotfiles using GNU Stow

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$DOTFILES_DIR"

packages="tmux nvim ctags vscode"

echo "Stowing dotfiles from $DOTFILES_DIR..."
for pkg in $packages; do
  echo "  stow $pkg"
  stow -t "$HOME" "$pkg"
done

echo "Done! Dotfiles installed."