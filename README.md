# dotfiles

![screenshot](scrot.png)

Managed with [GNU Stow](https://www.gnu.org/software/stow/).
Supports macOS and Arch Linux (btw).

```bash
git clone https://github.com/xkef/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install
```

The `install` script auto-detects your OS and installs packages
using the native format (`Brewfile` on macOS, `pkgs.arch` on Arch).
Then it symlinks configs via stow and sets fish as default shell.

## What's included

| Tool                                                             | What it does                                  |
| ---------------------------------------------------------------- | --------------------------------------------- |
| [Fish](https://fishshell.com)                                    | Shell with fzf completions, sane defaults     |
| [Starship](https://starship.rs)                                  | Minimal, cross-shell prompt                   |
| [Neovim](https://neovim.io) + [LazyVim](https://www.lazyvim.org) | Editor with LazyVim distro                    |
| [tmux](https://github.com/tmux/tmux)                             | Terminal multiplexer with vim navigation      |
| [Ghostty](https://ghostty.org)                                   | GPU-accelerated terminal                      |
| [fzf](https://github.com/junegunn/fzf)                           | Fuzzy finder everywhere (shell, tmux, neovim) |
| [atuin](https://atuin.sh)                                        | Searchable shell history with sync            |
| [Claude Code](https://claude.ai/)                                | AI coding agent with nono sandbox             |
| [jj (Jujutsu)](https://github.com/jj-vcs/jj)                     | Git-compatible VCS with simpler mental model  |
| eza, bat, fd, ripgrep, zoxide                                    | Modern unix replacements                      |

## Maintenance

```sh
make install        # Full install (packages + stow + tools)
make update         # Pull, re-stow, update plugins and tools
make doctor         # Check dotfiles health (binaries, symlinks, configs)
make restow         # Re-stow (fixes stale symlinks)
```

Or use the `dots` command directly:

```sh
dots doctor         # Check health
dots update         # Update everything
dots versions       # Show tool versions
dots keys           # Keybinding reference
```

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

| What   | File                                  |
| ------ | ------------------------------------- |
| Fish   | `~/.config/fish/local.fish`           |
| Git    | `~/.config/git/config.local`          |
| jj     | `jj config set --user user.name "…"`  |
| Neovim | `~/.config/lazyvim/lua/plugins/*.lua` |
| tmux   | `~/.config/tmux/local.conf`           |
| sesh   | `~/.config/sesh/local.toml`           |
| SSH    | `~/.ssh/conf.d/*.conf`                |

---

## Credits

Heavily inspired by
[wincent/wincent](https://github.com/wincent/wincent) --
tmux, neovim structure, keymaps, and general philosophy.
Also borrows from:

- [omerxx/dotfiles](https://github.com/omerxx/dotfiles) --
  tooling and tmux
- [ThePrimeagen](https://github.com/ThePrimeagen/.dotfiles) --
  tmux-sessionizer
- [folke/LazyVim](https://github.com/LazyVim/LazyVim) --
  Neovim distro and plugin ecosystem
