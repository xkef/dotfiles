# ── Television ───────────────────────────────────────
# tv picks from channels: files, dirs, text, git objects, and those in
# ~/.config/television/cable. `tv list-channels` lists them.
status is-interactive; or return
command -q tv; or return

# Ctrl-T picks for the command being typed: directories after `cd`, branches
# after `git checkout`.
tv init fish | source

# atuin takes over Ctrl-R from tv.
if command -q atuin
    atuin init fish --disable-up-arrow | source
end

# zoxide's PWD hook records each cd, so the Alt-Z jump ranks too.
bind \ec 'set -l dir (tv dirs); test -n "$dir"; and cd -- $dir; commandline -f repaint'
bind \ez 'set -l dir (tv zoxide-cd); test -n "$dir"; and cd -- $dir; commandline -f repaint'
bind \e/ 'tv text; commandline -f repaint'
