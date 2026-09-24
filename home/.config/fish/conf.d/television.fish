# ── Television ───────────────────────────────────────
# tv picks from channels in ~/.config/television/cable: files, directories,
# text, zoxide, git and jj objects, processes, and more. `tv <channel>`
# opens one, and `tv list-channels` lists them.
status is-interactive; or return

# Ctrl-T picks for the command being typed: directories after `cd`, branches
# after `git checkout`. config.toml maps commands to channels.
command -q tv; and tv init fish | source

# atuin takes over Ctrl-R from tv.
if command -q atuin
    atuin init fish --disable-up-arrow | source
end

bind \ec __tv_cd
bind \ez __tv_zoxide
bind \e/ 'tv text; commandline -f repaint'

# The fzf-era function names, now channels.
abbr -a fbr tv git-branch
abbr -a flog tv git-log
abbr -a fgd tv git-diff
abbr -a fkill tv procs
abbr -a frg tv text
