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

bind \ec __tv_cd
bind \ez __tv_zoxide
bind \e/ 'tv text; commandline -f repaint'
