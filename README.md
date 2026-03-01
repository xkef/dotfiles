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

| Category         | Tool                                                         | Why                                     |
|------------------|--------------------------------------------------------------|-----------------------------------------|
| **Shell**        | Zsh + [zinit](https://github.com/zdharma-continuum/zinit)    | Fast plugin loading, turbo mode         |
| **Prompt**       | [Starship](https://starship.rs)                              | Cross-shell, fast, informative          |
| **Editor**       | Neovim + lazy.nvim (no distro)                               | Minimal, explicit plugins, fast startup |
| **Multiplexer**  | tmux + [TPM](https://github.com/tmux-plugins/tpm)            | Session persistence, vim navigation     |
| **Terminal**     | [Ghostty](https://ghostty.org)                               | Native GPU rendering, OSC 52 clipboard  |
| **Git**          | Modern config + [delta](https://github.com/dandavison/delta) | Histogram diffs, zdiff3 conflicts       |
| **Fuzzy finder** | [fzf](https://github.com/junegunn/fzf) everywhere            | Shell, tmux, Neovim, git                |
| **CLI tools**    | eza, bat, fd, ripgrep, zoxide                                | Rust replacements for UNIX classics     |
| **AI**           | [Claude Code](https://github.com/anthropics/claude-code)     | Global `CLAUDE.md` via stow             |

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
| `/`     | Live grep                          |
| `sG`    | Grep word under cursor             |
| `sr`    | Resume last search                 |
| `S`     | Search & replace (grug-far)        |
| `sR`    | Search & replace word under cursor |
| `ha`    | Harpoon add                        |
| `hh`    | Harpoon menu                       |
| `1`–`4` | Jump to harpoon file               |

**LSP:**

| Key       | Action               |
|-----------|----------------------|
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
