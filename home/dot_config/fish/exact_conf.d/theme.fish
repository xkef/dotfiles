# ── Theme ────────────────────────────────────────────
# bat uses the terminal ANSI colors, so it follows every Ghostty theme.
set -gx BAT_THEME ansi

status is-interactive; or return

complete -c theme -x -a "(theme --completions 2>/dev/null)"
complete -c theme -l list -s l -d 'List available themes'
complete -c theme -l help -s h -d 'Show help'
