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

# Misc
abbr -a reload 'exec fish'
alias grep 'grep --color=auto'
abbr -a extract 'ouch decompress'
abbr -a compress 'ouch compress'
