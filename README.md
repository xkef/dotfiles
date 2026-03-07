# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

```bash
git clone https://github.com/YOUR_USER/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install
```

The install script auto-detects your OS and installs packages using the native format (`Brewfile` on macOS, `pkgs.arch`
on Arch, pre-built binaries elsewhere). Then it symlinks configs via stow and sets zsh as default shell.

## What's included

| Category     | Tool                                                                                    | Why                         |
|--------------|-----------------------------------------------------------------------------------------|-----------------------------|
| **Shell**    | Zsh + [zinit](https://github.com/zdharma-continuum/zinit)                               | Turbo-loaded plugins        |
| **Prompt**   | [Starship](https://starship.rs)                                                         | Cross-shell, fast           |
| **Editor**   | Neovim + lazy.nvim                                                                      | No distro, explicit config  |
| **Mux**      | tmux                                                                                    | Vim nav, fzf sessions       |
| **Terminal** | [Ghostty](https://ghostty.org)                                                          | GPU rendering, OSC 52       |
| **Git**      | [delta](https://github.com/dandavison/delta)                                            | Histogram diffs, zdiff3     |
| **Fuzzy**    | [fzf](https://github.com/junegunn/fzf) + [snacks](https://github.com/folke/snacks.nvim) | Shell/tmux + Neovim picker  |
| **History**  | [atuin](https://atuin.sh)                                                               | Ranked search, sync         |
| **CLI**      | eza, bat, fd, ripgrep, zoxide                                                           | Rust UNIX replacements      |
| **Cheats**   | [navi](https://github.com/denisidoro/navi)                                              | Interactive cheatsheets     |
| **AI**       | [Claude Code](https://github.com/anthropics/claude-code)                                | Global `CLAUDE.md` via stow |

---

## The one thing to remember

| Context    | Key          |        |
|------------|--------------|--------|
| **Neovim** | `Space`      | leader |
| **tmux**   | `Ctrl-Space` | prefix |

Same physical key. Ctrl is the only difference.

## Finding keybindings

| Where      | How                 | What                                        |
|------------|---------------------|---------------------------------------------|
| **tmux**   | `prefix + ?`        | Keybinding reference (floating popup)       |
| **Neovim** | `Space ?`           | Keybinding reference (floating terminal)    |
| **Neovim** | `Space` + wait      | which-key discovery popup                   |
| **Shell**  | `Ctrl-G`            | navi interactive cheatsheets (commands)     |
| **Shell**  | `keys`              | Same keybinding reference as above          |

---

## Local overrides

| What   | File                               |
|--------|------------------------------------|
| Shell  | `~/.config/zsh/local.zsh`          |
| Git    | `~/.config/git/config.local`       |
| Neovim | `~/.config/nvim/lua/plugins/*.lua` |
