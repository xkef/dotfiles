# ── Theme ────────────────────────────────────────────
# bat uses terminal ANSI colors — adapts to any Ghostty theme automatically.
set -gx BAT_THEME ansi

# Tab completion for the theme command (lists all Ghostty themes)
complete -c theme -x -a "(theme --completions 2>/dev/null)"
complete -c theme -l list -s l -d 'List available themes'
complete -c theme -l help -s h -d 'Show help'
