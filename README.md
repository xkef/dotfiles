# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

```bash
git clone https://github.com/YOUR_USER/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install
```

The `install` script auto-detects your OS and installs packages using the native format (`Brewfile` on macOS,
`pkgs.arch`
on Arch, pre-built binaries elsewhere). Then it symlinks configs via stow and sets zsh as default shell.

## What's included

| Tool                                                                             | What it does                                           |
| -------------------------------------------------------------------------------- | ------------------------------------------------------ |
| [Zsh](https://www.zsh.org) + [zinit](https://github.com/zdharma-continuum/zinit) | Shell with fast plugin loading                         |
| [Starship](https://starship.rs)                                                  | Minimal, cross-shell prompt                            |
| [Neovim](https://neovim.io) + [LazyVim](https://www.lazyvim.org)                 | Editor with LazyVim distro                             |
| [tmux](https://github.com/tmux/tmux)                                             | Terminal multiplexer with vim navigation               |
| [Ghostty](https://ghostty.org)                                                   | GPU-accelerated terminal                               |
| [fzf](https://github.com/junegunn/fzf)                                           | Fuzzy finder everywhere (shell, tmux, neovim)          |
| [atuin](https://atuin.sh)                                                        | Searchable shell history with sync                     |
| [Claude Code](https://claude.ai/)                                                | AI coding agent with Seatbelt sandbox and custom hooks |
| [jj (Jujutsu)](https://github.com/jj-vcs/jj)                                     | Git-compatible VCS with simpler mental model           |
| eza, bat, fd, ripgrep, zoxide                                                    | Modern unix replacements                               |

## Maintenance

```
make install       # Full install (packages + stow + tools)
make install-adopt # Install, adopting existing files
make update        # Pull, re-stow, update plugins and tools
make test          # Run smoke tests
make stow          # Stow all packages into ~
make restow        # Re-stow (fixes stale symlinks)
make fmt           # Format all dotfiles
make lint          # Lint shell scripts and neovim config
```

On macOS, run `./macos-defaults` once after a fresh install to apply developer-friendly system defaults.

---

## The one thing to remember

| Context    | Key          |        |
| ---------- | ------------ | ------ |
| **Neovim** | `Space`      | leader |
| **tmux**   | `Ctrl-Space` | prefix |

Same physical key. Ctrl is the only difference.

## Finding keybindings

| Where      | How          | What                                  |
| ---------- | ------------ | ------------------------------------- |
| **tmux**   | `prefix + ?` | Keybinding reference (floating popup) |
| **Neovim** | `leader + ?` | which-key discovery popup             |
| **Shell**  | `Ctrl-G`     | navi interactive cheatsheets          |

---

## Local overrides

| What   | File                                 |
| ------ | ------------------------------------ |
| Shell  | `~/.config/zsh/local.zsh`            |
| Git    | `~/.config/git/config.local`         |
| jj     | `jj config set --user user.name "…"` |
| Neovim | `~/.config/nvim/lua/plugins/*.lua`   |
| tmux   | `~/.config/tmux/local.conf`          |

---

## Credits

Heavily inspired by [wincent/wincent](https://github.com/wincent/wincent) -- tmux, zsh, neovim structure, keymaps, and
general philosophy. Also borrows from:

- [omerxx/dotfiles](https://github.com/omerxx/dotfiles) -- tooling and tmux
- [ThePrimeagen](https://github.com/ThePrimeagen/.dotfiles) -- tmux-sessionizer
- [mattmc3/zdotdir](https://github.com/mattmc3/zdotdir) -- zsh caching and compilation patterns
- [folke/LazyVim](https://github.com/LazyVim/LazyVim) -- Neovim distro and plugin ecosystem
