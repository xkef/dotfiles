# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

```bash
git clone https://github.com/YOUR_USER/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install
```

The install script reads `packages.toml`, auto-detects your OS, and installs everything using the native package
manager (Homebrew on macOS, pacman on Arch, apt on Ubuntu/Debian). Then it symlinks configs via stow and sets zsh as
default shell.

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
| **AI**       | [Claude Code](https://github.com/anthropics/claude-code)                                | Global `CLAUDE.md` via stow |

---

## The one thing to remember

| Context    | Key          |        |
|------------|--------------|--------|
| **Neovim** | `Space`      | leader |
| **tmux**   | `Ctrl-Space` | prefix |

Same physical key. Ctrl is the only difference.

---

## tmux `Ctrl-Space +`

| Key          | Action                            |
|--------------|-----------------------------------|
| `\|` / `-`   | Split right / down                |
| `H/J/K/L`    | Resize pane                       |
| `Ctrl-Space` | Toggle last window (double-tap)   |
| `Tab`        | Last window                       |
| `f`          | Sessionizer — fzf pick project    |
| `F`          | fzf switch session (with preview) |
| `w`          | fzf switch window (all sessions)  |
| `g`          | Lazygit (floating popup)          |
| `Enter`      | Enter copy mode                   |
| `/`          | Enter copy mode and search        |

**Copy mode** (`v` select, `V` line, `C-v` block, `y` yank, `Y` yank to EOL):

| Key     | Action                  |
|---------|-------------------------|
| `H/L`   | Start / end of line     |
| `/` `?` | Search forward/backward |

---

## Neovim `Space +`

**Files & search:**

| Key     | Action                             |
|---------|------------------------------------|
| `Space` | Alternate file (last buffer)       |
| `-`     | File browser (Oil)                 |
| `ff`    | Find files                         |
| `fr`    | Recent files                       |
| `fb`    | Buffers                            |
| `fh`    | Help tags                          |
| `/`     | Live grep                          |
| `sG`    | Grep word under cursor             |
| `sr`    | Resume last search                 |
| `S`     | Search & replace (grug-far)        |
| `sR`    | Search & replace word under cursor |
| `ha`    | Harpoon add                        |
| `hh`    | Harpoon menu                       |
| `1`–`4` | Jump to harpoon file               |

**Navigation:**

| Key | Action                                     |
|-----|--------------------------------------------|
| `s` | Flash jump — jump anywhere in 2 keystrokes |
| `S` | Flash treesitter — jump to any syntax node |

**Git:**

| Key  | Action  |
|------|---------|
| `gs` | Lazygit |

**LSP:**

| Key       | Action               |
|-----------|----------------------|
| `gd`      | Go to definition     |
| `gr`      | References           |
| `gI`      | Implementation       |
| `gy`      | Type definition      |
| `K`       | Hover                |
| `ca`      | Code action          |
| `cr`      | Rename               |
| `cf`      | Format               |
| `e`       | Diagnostic float     |
| `[d`/`]d` | Prev/next diagnostic |

**Other:**

| Key                  | Action                        |
|----------------------|-------------------------------|
| `Up`/`Down`          | Prev/next quickfix entry      |
| `Left`/`Right`       | Prev/next quickfix file       |
| `p`                  | Show file path                |
| `zz`                 | Strip trailing whitespace     |
| `v`                  | Reselect last visual          |
| `J`/`K` (visual)     | Move selection down/up        |
| `Space + p` (visual) | Paste without losing register |
| `j`/`k`              | Jumps > 5 stored in jumplist  |

---

## Shell functions

| Command                          | Action                                 |
|----------------------------------|----------------------------------------|
| `fe`                             | fzf → open file in editor              |
| `frg`                            | ripgrep → fzf → jump to line in editor |
| `fbr`                            | fzf git branch switcher                |
| `flog`                           | fzf git log browser                    |
| `fkill`                          | fzf process killer                     |
| `theme [name\|--list\|--toggle]` | Switch terminal/editor theme           |
| `dotfiles-update`                | Pull, re-stow, update all plugins      |

---

## Local overrides

| What   | File                               |
|--------|------------------------------------|
| Shell  | `~/.config/zsh/local.zsh`          |
| Git    | `~/.config/git/config.local`       |
| Neovim | `~/.config/nvim/lua/plugins/*.lua` |
