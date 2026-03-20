# Keybinding Reference

**tmux prefix = Ctrl-Space | nvim leader = Space**

## tmux — Ctrl-Space +

| Key        | Action                            |
| ---------- | --------------------------------- |
| │ / -      | Split right / down                |
| h/j/k/l    | Navigate panes                    |
| H/J/K/L    | Resize pane (repeatable)          |
| Ctrl-Space | Toggle last window (double-tap)   |
| Tab        | Last window                       |
| n / p      | Next / previous window            |
| < / >      | Swap window left / right          |
| c          | New window                        |
|            |                                   |
| f          | Sessionizer (fzf project picker)  |
| F          | Switch session (fzf popup)        |
| w          | Switch window, all sessions       |
| g          | Lazygit (floating popup)          |
| R          | Scooter search & replace (popup)  |
| ?          | This reference (floating popup)   |
| t          | Thumbs (hint-copy visible text)   |
| u          | Open URL from scrollback (fzf)    |
| Ctrl-f     | tmux-fzf (sessions/windows/etc)   |
|            |                                   |
| S          | New named session                 |
| s          | Browse sessions                   |
| o / i      | Jump to prev / next prompt        |
| Enter      | Enter copy mode                   |
| /          | Search forward (enters copy mode) |
| Ctrl-l     | Clear scrollback history          |
| r          | Reload tmux config                |
| I          | Install TPM plugins               |

### Copy mode

v/V/Ctrl-v toggle VISUAL/LINE/BLOCK (press again to cancel)
— y yank — Y yank-EOL — q cancel

| Key        | Action                    |
| ---------- | ------------------------- |
| H / L      | Start / end of line       |
| / / ?      | Search forward / backward |
| Ctrl-u / d | Half page up / down       |
| o / i      | Previous / next prompt    |
| Escape / q | Cancel                    |

---

## Neovim — Space +

Uses [LazyVim](https://www.lazyvim.org) defaults.
Press `Space` and wait for which-key to discover all bindings.

Full keymap reference: <https://www.lazyvim.org/keymaps>

---

## Shell

### Zsh line editing

Ctrl-R atuin | Ctrl-G navi | Ctrl-P/N prefix history

| Key           | Action                                |
| ------------- | ------------------------------------- |
| Ctrl-T        | File search (fzf)                     |
| Alt-C         | Directory jump under cwd (fzf + fd)   |
| Alt-Z         | Jump to visited directory (fzf+zoxide)|
| Alt-/         | Live grep file contents (rg + fzf)    |
| Ctrl-R        | Atuin history search                  |
| Ctrl-G        | Navi cheatsheet                       |
| Ctrl-S        | Yazi file manager (cd-on-quit)        |
|               |                                       |
| Ctrl-X d      | Directory jump fallback               |
| Ctrl-X z      | Visited directory jump fallback       |
| Ctrl-X g      | Live grep fallback                    |
|               |                                       |
| Ctrl-A / E    | Beginning / end of line               |
| Alt-F / B     | Forward / backward one word           |
| Ctrl-W        | Delete word backward (stops at /.\_-) |
| Alt-D         | Delete word forward                   |
| Ctrl-K        | Kill to end of line                   |
| Ctrl-U        | Kill entire line                      |
| Ctrl-Y        | Yank last killed text                 |
| Ctrl-P / N    | Prefix history search (also arrows)   |
| Ctrl-Z        | Toggle fg/bg (undo if no jobs)        |
| Ctrl-X Ctrl-E | Edit command in nvim                  |
| !! then Space | Expand history inline                 |
| Esc Esc       | Sudo last command                     |

### Named directories

`~dots` dotfiles | `~cfg` ~/.config | `~data` ~/.local/share | `~cache` ~/.cache

### Modern aliases

`extract` / `compress` ouch | `cat` bat | `ls` eza |
`du` dust | `df` duf | `ps` procs
