# ── Television ───────────────────────────────────────
# tv picks from channels: files, dirs, text, git objects, and those in
# ~/.config/television/cable. `tv list-channels` lists them.
status is-interactive; or return
command -q tv; or return

# Ctrl-T picks for the command being typed: directories after `cd`, branches
# after `git checkout`, and changes after `jj edit`. The television config
# maps commands to channels.
__cached_init tv init fish

# tv's trigger `jj restore` also matches `jj op restore`, so Ctrl-T routes
# `jj op` to the operation picker before tv guesses a channel.
function __tv_ctrl_t
    if not string match -qr '^\s*jj\s+op\s' -- (commandline --current-process)
        tv_smart_autocomplete
        return
    end

    printf "\n"
    if set -l op (tv jj-op-log --inline --no-status-bar)
        commandline -t -- "$op "
    end
    printf "\033[A"
    commandline -f repaint
end

for mode in default insert
    bind --mode $mode \ct __tv_ctrl_t
end

# atuin takes over Ctrl-R from tv. Its init spawns `atuin uuid` for a new
# session ID in each shell level, about 10ms. atuin reads the ID as an
# opaque string, so random UUIDv4 hex from fish builtins serves. The
# condition matches the init's own.
if not set -q ATUIN_SESSION; or test "$ATUIN_SHLVL" != "$SHLVL"
    set -gx ATUIN_SESSION (printf %04x (random 0 65535) (random 0 65535) (random 0 65535) \
        (random 16384 20479) (random 32768 49151) (random 0 65535) (random 0 65535) (random 0 65535))
    set -gx ATUIN_SHLVL $SHLVL
end
__cached_init atuin init fish --disable-up-arrow

# zoxide's PWD hook records each cd, so the Alt-Z jump ranks too.
bind \ec 'set -l dir (tv dirs); test -n "$dir"; and cd -- $dir; commandline -f repaint'
bind \ez 'set -l dir (tv zoxide-cd); test -n "$dir"; and cd -- $dir; commandline -f repaint'
bind \e/ 'tv text; commandline -f repaint'
