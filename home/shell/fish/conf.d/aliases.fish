# ── Abbreviations ────────────────────────────────────
# Abbreviations expand inline, so the full command stays visible. Use `abbr`
# for commands you type and `alias` for transparent replacements. Interactive
# only: an alias like `grep --color` must not leak into scripts.
status is-interactive; or return

# Quick edit
abbr -a v nvim
abbr -a vi nvim
abbr -a vim nvim
abbr -a helix hx

# Pipe -h output through bat, after folke/dot.
abbr -a --position anywhere --set-cursor -- -h "-h 2>&1 | bat --plain --language=help"

# Misc
abbr -a reload 'exec fish'
alias grep 'grep --color=auto'
abbr -a extract 'ouch decompress'
abbr -a compress 'ouch compress'

