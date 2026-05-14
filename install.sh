#!/bin/bash
# Install dotfiles using GNU Stow

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

detect_pkg_manager() {
  if command -v apt-get &>/dev/null; then
    echo "apt-get"
  elif command -v dnf &>/dev/null; then
    echo "dnf"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  elif command -v brew &>/dev/null; then
    echo "brew"
  else
    echo ""
  fi
}

install_packages() {
  local pkg_manager="$1"
  shift
  local packages=("$@")

  case "$pkg_manager" in
    apt-get)
      sudo apt-get update -qq && sudo apt-get install -y "${packages[@]}"
      ;;
    dnf)
      sudo dnf install -y "${packages[@]}"
      ;;
    pacman)
      sudo pacman -S --noconfirm "${packages[@]}"
      ;;
    brew)
      brew install "${packages[@]}"
      ;;
    *)
      echo "Error: No supported package manager found. Install packages manually: ${packages[*]}" >&2
      exit 1
      ;;
  esac
}

# Install GNU Stow
if ! command -v stow &>/dev/null; then
  echo "GNU Stow not found. Installing..."
  pkg_manager=$(detect_pkg_manager)
  install_packages "$pkg_manager" "stow"
fi

# Install clipboard tools for tmux integration
missing_clipboard=()
if ! command -v xclip &>/dev/null && ! command -v wl-copy &>/dev/null; then
  if [ -n "$WAYLAND_DISPLAY" ]; then
    missing_clipboard+=("wl-clipboard")
  else
    missing_clipboard+=("xclip")
  fi
fi

if [ ${#missing_clipboard[@]} -gt 0 ]; then
  echo "Installing clipboard tools: ${missing_clipboard[*]}"
  pkg_manager=$(detect_pkg_manager)
  install_packages "$pkg_manager" "${missing_clipboard[@]}"
fi

# Install Tmux Plugin Manager and plugins
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  echo "Installing Tmux Plugin Manager..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

echo ""
echo "Installing tmux plugins..."
tmux new-session -d -s tpm-install -x 80 -y 24 2>/dev/null || true
tmux source-file "$HOME/.tmux.conf" 2>/dev/null || true
"$TPM_DIR/bin/install_plugins" 2>/dev/null || true
tmux kill-session -t tpm-install 2>/dev/null || true
echo "  done"

# Install Neovim if missing
if ! command -v nvim &>/dev/null; then
  echo "Neovim not found. Installing..."
  pkg_manager=$(detect_pkg_manager)
  case "$pkg_manager" in
    apt-get)
      echo "Using snap to install Neovim (apt version is outdated)..."
      sudo snap install nvim --classic
      ;;
    dnf)
      sudo dnf install -y neovim
      ;;
    pacman)
      sudo pacman -S --noconfirm neovim
      ;;
    brew)
      brew install neovim
      ;;
    *)
      echo "Warning: No supported package manager found. Install Neovim manually." >&2
      ;;
  esac
fi

# Install nvm and a stable Node version
if [ ! -d "$HOME/.nvm" ]; then
  echo "Installing nvm..."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command -v node &>/dev/null || [ "$(node --version | cut -d. -f1 | tr -d 'v')" -lt 18 ]; then
  echo "Installing latest stable Node..."
  nvm install stable
fi

# Install Claude Code CLI via npm if missing
if ! command -v claude &>/dev/null; then
  echo "Installing Claude Code CLI..."
  npm install -g @anthropic-ai/claude-code
fi

# Install RTK (Rust Token Killer) for Claude Code token optimization
if ! command -v rtk &>/dev/null; then
  echo "Installing RTK (Rust Token Killer)..."
  curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/master/install.sh | sh
fi

# Initialize RTK for Claude Code globally (idempotent)
if command -v rtk &>/dev/null; then
  rtk init --global 2>/dev/null || true
fi

# Install mise (multi-tool version manager) — cross-platform: Linux, macOS, Termux
if ! command -v mise &>/dev/null; then
  echo "Installing mise..."
  curl https://mise.run | sh
fi

# Ensure mise is available for the rest of the install
export PATH="$HOME/.local/bin:$PATH"
if command -v mise &>/dev/null; then
  eval "$(mise activate bash 2>/dev/null)" || true
fi

# Install carapace via mise (cross-platform)
if ! command -v carapace &>/dev/null; then
  echo "Installing carapace via mise..."
  mise use -g carapace@latest
fi

# Install fzf (fuzzy finder)
if ! command -v fzf &>/dev/null; then
  echo "Installing fzf..."
  pkg_manager=$(detect_pkg_manager)
  case "$pkg_manager" in
    apt-get)
      sudo apt-get install -y fzf
      ;;
    dnf)
      sudo dnf install -y fzf
      ;;
    pacman)
      sudo pacman -S --noconfirm fzf
      ;;
    brew)
      brew install fzf
      ;;
    *)
      # Fallback: git clone
      if [ ! -d "$HOME/.fzf" ]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        "$HOME/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-zsh
      fi
      ;;
  esac
fi

# Install starship prompt
if ! command -v starship &>/dev/null; then
  echo "Installing starship..."
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
fi

cd "$DOTFILES_DIR"

packages="tmux nvim ctags vscode scripts claude starship"

# Stow a package, handling conflicts with backup-and-replace
stow_package() {
  local pkg="$1"
  local target="$HOME"

  echo "  stow $pkg"

  # Check for conflicts using simulation mode
  local conflicts
  conflicts=$(stow --no -t "$target" "$pkg" 2>&1 | grep "over existing target" | sed 's/.*over existing target //;s/ since.*//' || true)

  if [ -z "$conflicts" ]; then
    stow -t "$target" "$pkg"
    return
  fi

  # Conflicts detected
  local backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

  echo "    Conflict detected! The following files already exist and"
  echo "    would prevent stowing '$pkg':"
  echo ""
  while IFS= read -r file; do
    echo "      ~/$file"
  done <<< "$conflicts"
  echo ""
  echo -n "    Backup these files and replace with symlinks? [y/N] "
  read -r answer

  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "    Skipping $pkg"
    return
  fi

  # Backup conflicting files before stowing
  while IFS= read -r file; do
    local src="$target/$file"
    if [ -e "$src" ] || [ -L "$src" ]; then
      local bak="$backup_dir/$file"
      mkdir -p "$(dirname "$bak")"
      mv "$src" "$bak"
      echo "      Backed up ~/$file -> $backup_dir/$file"
    fi
  done <<< "$conflicts"

  stow -t "$target" "$pkg"
  echo "    Stowed $pkg"
}

echo "Stowing dotfiles from $DOTFILES_DIR..."
for pkg in $packages; do
  stow_package "$pkg"
done

# Add shell completion init and prompt to .bashrc (idempotent)
add_shell_init() {
  local rc_file="$1"
  local SHELL_INIT_LINE='[ -f "$HOME/.config/shell/init" ] && . "$HOME/.config/shell/init"'

  # Already has it (active or commented) — nothing to do
  if grep -qs "config/shell/init" "$rc_file" 2>/dev/null; then
    # If it's commented out, uncomment it
    if grep -qs "^[[:space:]]*#[[:space:]]*$SHELL_INIT_LINE" "$rc_file" 2>/dev/null; then
      sed -i "s|^[[:space:]]*#[[:space:]]*$SHELL_INIT_LINE|$SHELL_INIT_LINE|" "$rc_file"
      echo "  Uncommented shell init in $rc_file"
    fi
    return
  fi

  # Insert before the first PS1/prompt-related line if found, otherwise append
  local insert_before
  insert_before=$(grep -n "force_color_prompt\|PS1=" "$rc_file" 2>/dev/null | head -1 | cut -d: -f1)
  if [ -n "$insert_before" ]; then
    sed -i "$insert_before i\\
# Source shell completions and prompt (carapace + fzf + starship)\\
$SHELL_INIT_LINE
" "$rc_file"
  else
    echo "" >> "$rc_file"
    echo "# Source shell completions and prompt (carapace + fzf + starship)" >> "$rc_file"
    echo "$SHELL_INIT_LINE" >> "$rc_file"
  fi
  echo "  Added shell init to $rc_file"
}

add_shell_init "$HOME/.bashrc"

# Also add to .zshrc if it exists
if [ -f "$HOME/.zshrc" ]; then
  add_shell_init "$HOME/.zshrc"
fi

echo "Done! Dotfiles installed."
echo ""
echo "To apply changes:"
echo "  tmux   → tmux source-file ~/.tmux.conf  (or start a new session)"
echo "  vscode → Reload VS Code (Ctrl+Shift+P → Developer: Reload Window)"
echo "  nvim   → Just restart Neovim"
echo "  shell  → Run: source ~/.bashrc  (or start a new terminal)"
