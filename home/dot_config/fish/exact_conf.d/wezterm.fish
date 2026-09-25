status is-interactive; or return
set -q WEZTERM_PANE; or return

# ── WezTerm tab names ────────────────────────────────
# Publishes the running command as the WEZTERM_PROG user var, as WezTerm's
# bash and zsh integration does. The WezTerm window reaches its panes
# through the mux server and can't see their foreground process, so
# status.lua names tabs from this var.
function __wezterm_user_var -a name value
    printf '\e]1337;SetUserVar=%s=%s\a' $name (printf '%s' $value | base64 | string join '')
end

function __wezterm_prog_start --on-event fish_preexec
    __wezterm_user_var WEZTERM_PROG $argv[1]
end

function __wezterm_prog_end --on-event fish_postexec
    __wezterm_user_var WEZTERM_PROG ''
end
