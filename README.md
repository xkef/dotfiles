# dotfiles

Modern, minimal dotfiles for macOS and Linux. Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick start

```bash
git clone https://github.com/YOUR_USER/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install
```

The install script reads `packages.toml`, auto-detects your OS, and installs everything using the native package manager (Homebrew on macOS, pacman on Arch, apt on Ubuntu/Debian). Then it symlinks configs via stow and sets zsh as default shell.

## The one thing to remember

| Context    | Key          | What it does                       |
| ---------- | ------------ | ---------------------------------- |
| **Neovim** | `Space`      | Leader — every command starts here |
| **tmux**   | `Ctrl-Space` | Prefix — every command starts here |

Same physical key. Ctrl is the only difference. `Space + key` in vim, `Ctrl-Space + key` in tmux.

## What's included

| Category         | Tool                                                         | Why                                       |
| ---------------- | ------------------------------------------------------------ | ----------------------------------------- |
| **Shell**        | Zsh + [zinit](https://github.com/zdharma-continuum/zinit)    | Fast plugin loading, turbo mode           |
| **Prompt**       | [Starship](https://starship.rs)                              | Cross-shell, fast, informative            |
| **Editor**       | Neovim + [LazyVim](https://www.lazyvim.org)                  | Full IDE, lazy-loaded, 12 language extras |
| **Multiplexer**  | tmux + [TPM](https://github.com/tmux-plugins/tpm)            | Session persistence, vim navigation       |
| **Terminal**     | [Ghostty](https://ghostty.org)                               | Native GPU rendering, OSC 52 clipboard    |
| **Git**          | Modern config + [delta](https://github.com/dandavison/delta) | Histogram diffs, zdiff3 conflicts         |
| **Fuzzy finder** | [fzf](https://github.com/junegunn/fzf) everywhere            | Shell, tmux, Neovim, git                  |
| **CLI tools**    | eza, bat, fd, ripgrep, zoxide                                | Rust replacements for UNIX classics       |
| **AI**           | [Claude Code](https://github.com/anthropics/claude-code)     | Global `CLAUDE.md` via stow               |

## Structure

```
dotfiles/
├── install            # Python — auto-detects OS, installs packages + stow
├── packages.toml      # What to install, per platform (single source of truth)
├── .editorconfig      # Consistent formatting across editors
├── git/               # Git config (delta, modern defaults)
├── zsh/               # Zsh + Starship (conf.d/, aliases, fzf, functions)
├── tmux/              # tmux (vi mode, fzf popups, vim navigation)
├── nvim/              # Neovim (LazyVim + custom plugins)
├── ghostty/           # Ghostty terminal
└── local/             # Everything else (scripts, bat, fd, shfmt, CLAUDE.md)
```

Every top-level directory is a **stow package**. Install selectively with `stow git zsh tmux nvim`.

---

## How it works

### tmux

The tmux config gives you a full **vim-feeling** in every mode.

**Pane/window management** (all prefixed with `Ctrl-Space`):

| Key          | Action                                 |
| ------------ | -------------------------------------- |
| `h/j/k/l`    | Navigate panes (vim directions)        |
| `H/J/K/L`    | Resize panes (repeatable)              |
| `\|`         | Split horizontal                       |
| `-`          | Split vertical                         |
| `c`          | New window                             |
| `n/p`        | Next/previous window                   |
| `Tab`        | Last window                            |
| `Ctrl-Space` | Toggle last window (double-tap prefix) |

**Copy mode** — enter with `Ctrl-Space + Enter` or `Ctrl-Space + /` (search, like vim):

| Key       | Action                          |
| --------- | ------------------------------- |
| `v`       | Begin selection (visual mode)   |
| `V`       | Select line (visual line)       |
| `C-v`     | Rectangle select (visual block) |
| `y`       | Yank (copy to system clipboard) |
| `Y`       | Yank to end of line             |
| `/`       | Incremental search forward      |
| `?`       | Incremental search backward     |
| `H/L`     | Start/end of line               |
| `C-u/C-d` | Half page up/down               |
| `Escape`  | Cancel                          |

All standard vim motions (`w`, `b`, `e`, `0`, `$`, `gg`, `G`, `f`, `F`, `n`, `N`) work in copy mode by default.

**FZF popups** (all prefixed with `Ctrl-Space`):

| Key | Action                                                           |
| --- | ---------------------------------------------------------------- |
| `f` | **tmux-sessionizer** — fzf pick a project, create/attach session |
| `F` | fzf switch between existing sessions (with pane preview)         |
| `w` | fzf switch between windows across all sessions                   |
| `s` | Tree-style session/window picker                                 |

**tmux-sessionizer** (`Ctrl-Space + f` or run `tmux-sessionizer` from shell):

Searches `~/projects`, `~/work`, `~/personal`, and `~/.config` for subdirectories, shows them in fzf with a file listing preview. Pick one and it creates a tmux session named after the directory (or switches to it if it already exists). You can also pass a path directly: `tmux-sessionizer ~/projects/myapp`.

This is the main way to jump between projects — each project gets its own tmux session with its own windows/panes, and you switch instantly with fzf.

**Session persistence**: tmux-resurrect + tmux-continuum auto-save every 15 minutes and restore on startup. Your layout survives reboots.

**Seamless navigation**: `Ctrl-h/j/k/l` moves between vim splits and tmux panes transparently (via vim-tmux-navigator).

**Theme**: minimal, low-contrast Catppuccin Mocha. Session name in blue on the left, dim window list in the center, pane title and time on the right. Designed to stay out of your way.

### Neovim

Built on [LazyVim](https://www.lazyvim.org) — leader is **`Space`**.

**Language extras**: TypeScript, Python, Rust, Go, Java, C/C++, JSON, YAML, Markdown, Docker, Terraform, Tailwind CSS

**Key mappings** (all prefixed with `Space`):

| Key   | Action                   | Plugin    |
| ----- | ------------------------ | --------- |
| `ff`  | Find files               | Telescope |
| `/`   | Live grep (project-wide) | Telescope |
| `sG`  | Grep word under cursor   | Telescope |
| `sb`  | Fuzzy find in buffer     | Telescope |
| `sR`  | Resume last search       | Telescope |
| `sc`  | Command history          | Telescope |
| `ha`  | Harpoon add file         | Harpoon   |
| `hh`  | Harpoon quick menu       | Harpoon   |
| `1-4` | Jump to harpoon file 1-4 | Harpoon   |
| `uu`  | Toggle undotree          | Undotree  |
| `zz`  | Zen mode                 | Zen Mode  |

| Key         | Action                           |
| ----------- | -------------------------------- |
| `-`         | Open parent directory (Oil)      |
| `C-h/j/k/l` | Navigate vim splits / tmux panes |

All Telescope pickers use the compiled **fzf-native** sorter for instant results.

### Fuzzy finder (fzf)

fzf is integrated into every layer with consistent keybindings and previews.

**Shell (zsh)**:

| Key       | Action                                            |
| --------- | ------------------------------------------------- |
| `Ctrl-T`  | Find files (bat preview)                          |
| `Ctrl-R`  | Search command history                            |
| `Alt-C`   | cd into directory (tree preview)                  |
| `**<tab>` | fzf path completion on any command                |
| `Tab`     | fzf-tab replaces default completion with previews |

**Shell functions** (type the command):

| Command | Action                                      |
| ------- | ------------------------------------------- |
| `fe`    | Find + open file in editor                  |
| `frg`   | Live ripgrep → fzf → jump to line in editor |
| `fbr`   | Git branch switcher (with log preview)      |
| `flog`  | Interactive git log browser                 |
| `fkill` | Interactive process killer                  |

### Clipboard

System clipboard works everywhere via **OSC 52** escape sequences. Ghostty has first-class support — no external tools needed.

- Yank in Neovim → system clipboard
- `y` in tmux copy mode → system clipboard
- Works over SSH, inside tmux, locally — same mechanism everywhere

### Git

Config follows [core Git developer recommendations](https://blog.gitbutler.com/how-git-core-devs-configure-git/):

- `push.autoSetupRemote` — no more "no upstream branch" errors
- `pull.rebase` — clean history by default
- `merge.conflictstyle = zdiff3` — shows base version in conflicts
- `rerere.enabled` — remembers conflict resolutions
- `diff.algorithm = histogram` — better diffs
- `delta` as pager — syntax-highlighted, side-by-side diffs

Personal config goes in `~/.config/git/config.local`:

```ini
[user]
    name = Your Name
    email = you@example.com
    signingkey = ~/.ssh/id_ed25519.pub
[gpg]
    format = ssh
[commit]
    gpgsign = true
```

---

## Updating

```bash
dotfiles-update    # Pull latest, re-stow, update all plugins (zinit, TPM, lazy.nvim)
```

## Local overrides

| What        | File                                          |
| ----------- | --------------------------------------------- |
| Shell       | `~/.config/zsh/local.zsh` or `~/.zshrc.local` |
| Git         | `~/.config/git/config.local`                  |
| Neovim      | Add files to `~/.config/nvim/lua/plugins/`    |
| Claude Code | Edit `~/.claude/CLAUDE.md`                    |

## Credits

Inspired by [wincent/wincent](https://github.com/wincent/wincent), simplified for maintainability.
