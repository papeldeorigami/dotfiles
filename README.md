# Dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/) — each package is a directory mapped to `$HOME` via symlinks.

## Packages

| Package   | What it manages |
|-----------|----------------|
| `tmux`    | `~/.tmux.conf` — Catppuccin Mocha theme, vim navigation, clipboard (OSC 52 + xclip/wl-copy), CPU/RAM status |
| `nvim`    | `~/.config/nvim/` — LazyVim-based Neovim config |
| `ctags`   | `~/.ctags` — ctags configuration |
| `vscode`  | `~/.config/Code/User/` — VS Code settings and keybindings |
| `scripts` | `~/.local/bin/` — utility scripts (GitHub SSH helpers, statusline, etc.)<br>`~/.config/shell/init` — shell-agnostic completions (carapace + fzf) |
| `claude`  | `~/.claude/` — Claude Code CLI config, RTK integration |

## Shell Completions

The `scripts` package provides `~/.config/shell/init`, a shell-agnostic init file sourced from both `.bashrc` and `.zshrc` by a single line:

```bash
[ -f "$HOME/.config/shell/init" ] && . "$HOME/.config/shell/init"
```

It detects the running shell and initializes:

- **[Carapace](https://github.com/carapace-sh/carapace-bin)** — multi-shell completion engine with completions for 2000+ CLI tools
- **[Fzf](https://github.com/junegunn/fzf)** — fuzzy finder with `**`-triggered fuzzy completion and key bindings

The install script adds the source line to `~/.bashrc` automatically (and `~/.zshrc` if it exists).

## Installation

```bash
./install.sh
```

This installs: GNU Stow, clipboard tools, Tmux Plugin Manager, Neovim, nvm/Node, Claude Code CLI, RTK, carapace, and fzf — then stows all packages.

## Quick Start

```bash
# Re-run stow after pulling changes
cd ~/workspace/dotfiles && stow -t ~ */

# Reload shell completions
source ~/.bashrc
```