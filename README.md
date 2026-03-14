# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

```bash
git clone https://github.com/YOUR_USER/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install
```

The install script auto-detects your OS and installs packages using the native format (`Brewfile` on macOS, `pkgs.arch`
on Arch, pre-built binaries elsewhere). Then it symlinks configs via stow and sets zsh as default shell.

## What's included

| Tool                                                                             | What it does                                           |
| -------------------------------------------------------------------------------- | ------------------------------------------------------ |
| [Zsh](https://www.zsh.org) + [zinit](https://github.com/zdharma-continuum/zinit) | Shell with fast plugin loading                         |
| [Starship](https://starship.rs)                                                  | Minimal, cross-shell prompt                            |
| [Neovim](https://neovim.io) + lazy.nvim                                          | Editor, no distro                                      |
| [tmux](https://github.com/tmux/tmux)                                             | Terminal multiplexer with vim navigation               |
| [Ghostty](https://ghostty.org)                                                   | GPU-accelerated terminal                               |
| [fzf](https://github.com/junegunn/fzf)                                           | Fuzzy finder everywhere (shell, tmux, neovim)          |
| [atuin](https://atuin.sh)                                                        | Searchable shell history with sync                     |
| [Claude Code](https://claude.ai/)                                                | AI coding agent with Seatbelt sandbox and custom hooks |
| [jj (Jujutsu)](https://github.com/jj-vcs/jj)                                     | Git-compatible VCS with simpler mental model           |
| eza, bat, fd, ripgrep, zoxide                                                    | Modern unix replacements                               |

---

## Management

Use the `dot` command for all dotfiles operations:

```
dot install       Full install (packages + stow + tools)
dot install-adopt  Install, adopting existing files into the repo
dot update         Pull, re-stow, update plugins and tools
dot stow           Stow all packages into ~
dot unstow         Remove all symlinks from ~
dot restow         Re-stow (fixes stale symlinks)
dot test           Run smoke tests
dot fmt            Format all dotfiles
dot lint           Lint shell scripts and neovim config
dot edit           Open dotfiles in $EDITOR
dot cd             Print dotfiles path (use: cd "$(dot cd)")
dot macos          Apply macOS developer defaults (macOS only)
```

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
