# Dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/) — each package is a directory mapped to `$HOME` via symlinks.

## Packages

| Package    | What it manages |
|------------|----------------|
| `tmux`     | `~/.tmux.conf` — Catppuccin Mocha theme, vim navigation, clipboard (OSC 52 + xclip/wl-copy), CPU/RAM status |
| `nvim`     | `~/.config/nvim/` — LazyVim-based Neovim config |
| `ctags`    | `~/.ctags` — ctags configuration |
| `vscode`   | `~/.config/Code/User/` — VS Code settings and keybindings |
| `scripts`  | `~/.local/bin/` — utility scripts (see below)<br>`~/.config/shell/` — shell-agnostic init, aliases, Claude Code proxy config |
| `claude`   | `~/.claude/` — Claude Code CLI settings, RTK hook integration, dark theme, custom status line |
| `starship` | `~/.config/starship.toml` — cross-shell prompt theme |

## Shell Init

The `scripts` package provides `~/.config/shell/init`, a shell-agnostic init file sourced from both `.bashrc` and `.zshrc`:

```bash
[ -f "$HOME/.config/shell/init" ] && . "$HOME/.config/shell/init"
```

It detects the running shell and initializes:

- **[Mise](https://mise.jdx.dev)** — multi-tool version manager (auto-activates for bash)
- **[Starship](https://starship.rs)** — cross-shell prompt (uses `~/.config/starship.toml`)
- **[Carapace](https://github.com/carapace-sh/carapace-bin)** — multi-shell completion engine (2000+ CLI tools)
- **[Fzf](https://github.com/junegunn/fzf)** — fuzzy finder with `**`-triggered completions and key bindings

Additional files sourced by `init`:

| File | Purpose |
|------|---------|
| `~/.secrets.sh` | API keys and sensitive env vars (in `.gitignore`) |
| `~/.config/shell/claude-env.sh` | Claude Code proxy config via DeepSeek API |
| `~/.config/shell/aliases.sh` | Shell aliases (e.g. `gmerged`) |

The install script adds the source line to `.bashrc` **and** `.zshrc` (idempotent, with macOS-compatible `sed`).

## Utility Scripts

All scripts live in `~/.local/bin/` (part of the `scripts` package):

| Script | Purpose |
|--------|---------|
| `tmux-yank` | Clipboard integration via OSC 52 (SSH), xclip (X11), or wl-copy (Wayland) |
| `gh-setup` | Install, authenticate, and add SSH keys to GitHub via `gh` CLI |
| `github-ssh-init` | Full SSH key setup workflow for GitHub |
| `ssh-key-for` | Generate ed25519 SSH keys for a specific purpose (github, gitlab, work, etc.) |
| `statusline.sh` | Custom Claude Code status line with context info |
| `mise` | Bundled mise binary for multi-tool version management |
| `rtk` | Bundled RTK (Rust Token Killer) binary for Claude Code token optimization |
| `starship` | Bundled starship binary |

## Clipboard Integration (tmux)

When SSH'd from a Mac, tmux yanking uses **OSC 52** escape sequences to reach the local Mac clipboard.

### Required: iTerm2 setting

1. Open **iTerm2** → **Preferences** → **General** → **Selection**
2. Check **"Applications in terminal may access clipboard"**

### Terminal compatibility

| Terminal | OSC 52 support |
|----------|---------------|
| iTerm2   | Yes (with setting above) |
| Kitty    | Yes (enabled by default) |
| Alacritty | Yes (enabled by default) |
| WezTerm  | Yes (enabled by default) |
| Terminal.app | No |

### Fallback chain

`~/.local/bin/tmux-yank` picks the right method automatically:

1. **SSH session** → OSC 52 (to local Mac terminal)
2. **Local X11** → `xclip`
3. **Local Wayland** → `wl-copy`

## Claude Code Config

The `claude` package configures Claude Code CLI with:

- **RTK integration** — every `Bash` tool call is transparently rewritten via RTK for 60-90% token savings
- **Model** — defaults to Sonnet (`deepseek-v4-flash`)
- **Theme** — dark mode
- **Status line** — custom script showing context info

The proxy config (`claude-env.sh`) routes Claude Code through DeepSeek's API bridge, mapping Opus → `deepseek-v4-pro`, Sonnet/Haiku → `deepseek-v4-flash`.

## Installation

```bash
./install.sh
```

The install script is cross-platform (Linux/macOS with apt, dnf, pacman, or brew) and installs:

GNU Stow, clipboard tools (xclip/wl-clipboard), Tmux Plugin Manager + plugins, Neovim, nvm/Node, Claude Code CLI, RTK (Rust Token Killer), mise, carapace, fzf, starship

It then stows all packages with conflict handling — existing files are backed up to `~/.dotfiles-backup/<timestamp>/` before being replaced with symlinks.

## Quick Start

```bash
# Re-run stow after pulling changes
cd ~/workspace/dotfiles && stow -t ~ */

# Reload shell
source ~/.bashrc   # or ~/.zshrc on macOS
```
