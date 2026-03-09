# Keybinding Reference

**tmux prefix = Ctrl-Space | nvim leader = Space**

## tmux — Ctrl-Space +

| Key        | Action                           |
|------------|----------------------------------|
| │ / -      | Split right / down               |
| h/j/k/l    | Navigate panes                   |
| H/J/K/L    | Resize pane (repeatable)         |
| Ctrl-Space | Toggle last window (double-tap)  |
| Tab        | Last window                      |
| n / p      | Next / previous window           |
| c          | New window                       |
|            |                                  |
| f          | Sessionizer (fzf project picker) |
| F          | Switch session (fzf popup)       |
| w          | Switch window, all sessions      |
| g          | Lazygit (floating popup)         |
| ?          | This reference (floating popup)  |
|            |                                  |
| S          | New named session                |
| s          | Browse sessions                  |
| Enter      | Enter copy mode                  |
| /          | Copy mode + search               |

### Copy mode

v select — V line — Ctrl-v block — y yank — Y yank-EOL

| Key        | Action                    |
|------------|---------------------------|
| H / L      | Start / end of line       |
| / / ?      | Search forward / backward |
| Ctrl-u / d | Half page up / down       |

---

## Neovim — Space +

### Files and search

| Key   | Action                        |
|-------|-------------------------------|
| Space | Alternate file (last buffer)  |
| - / e | File browser (nvim-tree)      |
| ff    | Find files                    |
| fr    | Recent files                  |
| fb    | Buffers                       |
| fh    | Help tags                     |
| /     | Live grep                     |
| sG    | Grep word under cursor        |
| sr    | Resume last search            |
| S     | Search and replace (grug-far) |
| sR    | Search and replace at cursor  |
|       |                               |
| ha    | Harpoon add                   |
| hh    | Harpoon menu                  |
| 1-4   | Jump to harpoon mark          |

### Navigation

| Key | Action                         |
|-----|--------------------------------|
| s   | Flash jump (2 keystrokes)      |
| S   | Flash treesitter (syntax node) |

### Git

| Key     | Action              |
|---------|---------------------|
| gs      | Lazygit             |
| ]h / [h | Next / prev hunk    |
| hp      | Preview hunk diff   |
| hr      | Reset (revert) hunk |
| hd      | Diff buffer         |

### LSP

| Key     | Action                 |
|---------|------------------------|
| gd      | Go to definition       |
| gr      | References             |
| gI      | Implementation         |
| gy      | Type definition        |
| K       | Hover                  |
| ca      | Code action            |
| cr      | Rename                 |
| cf      | Format                 |
| e       | Diagnostic float       |
| [d / ]d | Prev / next diagnostic |

### Other

| Key            | Action                        |
|----------------|-------------------------------|
| ?              | Which-key (all keybindings)   |
| t              | Floating terminal             |
| Up / Down      | Prev / next quickfix entry    |
| Left / Right   | Prev / next quickfix file     |
| zz             | Strip trailing whitespace     |
| v              | Reselect last visual          |
| J / K (visual) | Move selection down / up      |
| Space+p (vis)  | Paste without losing register |

---

## Shell

### Functions

| Key             | Action                          |
|-----------------|---------------------------------|
| fe              | fzf file finder, open in editor |
| frg             | ripgrep + fzf, jump to line     |
| fbr             | fzf git branch switcher         |
| flog            | fzf git log browser             |
| fkill           | fzf process killer              |
| g               | git status / git command        |
| mcd \<dir>      | mkdir + cd                      |
| root            | cd to git repo root             |
| envup [file]    | Load .env into shell            |
| theme           | Switch terminal / editor theme  |
| dotfiles-update | Pull, re-stow, update plugins   |
| keys            | This reference                  |

### Zsh line editing

Ctrl-R atuin | Ctrl-G navi | Ctrl-P/N prefix history

| Key           | Action                      |
|---------------|-----------------------------|
| Ctrl-T        | File search (fzf)           |
| Ctrl-X d      | Directory jump (fzf)        |
| Ctrl-G        | Navi cheatsheet             |
|               |                             |
| Ctrl-A / E    | Beginning / end of line     |
| Alt-F / B     | Forward / backward one word |
| Ctrl-W        | Delete word backward        |
| Alt-D         | Delete word forward         |
| Ctrl-K        | Kill to end of line         |
| Ctrl-U        | Kill entire line            |
| Ctrl-Y        | Yank last killed text       |
| Ctrl-Z        | Undo last edit              |
| Ctrl-X Ctrl-E | Edit command in nvim        |
| !! then Space | Expand history inline       |
| Esc Esc       | Sudo last command           |
