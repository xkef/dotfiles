# ── Theme ────────────────────────────────────────────
# bat uses the terminal ANSI colors, so it follows every tinty scheme.
set -gx BAT_THEME ansi

# The Tab pager copies tv's default theme, so completions and pickers
# match. ANSI names keep both on the tinty scheme.
set -g fish_pager_color_completion brblue
set -g fish_pager_color_prefix brred --bold
set -g fish_pager_color_description white
set -g fish_pager_color_progress brred
set -g fish_pager_color_selected_background --background=brblack
set -g fish_pager_color_selected_completion brgreen
