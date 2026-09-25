# ── Abbreviations ────────────────────────────────────
# Abbreviations expand inline, so the full command stays visible. Use `abbr`
# for commands you type and `alias` for transparent replacements. Interactive
# only: an alias like `mkdir -pv` must not leak into scripts.
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
abbr -a cls clear
alias mkdir 'mkdir -pv'
alias grep 'grep --color=auto'
abbr -a help man
abbr -a extract 'ouch decompress'
abbr -a compress 'ouch compress'

# ── Modern replacements ──────────────────────────────
# The eza, bat, dust, duf, and procs wrappers sit in functions/ as ls, ll,
# lt, la, eza, cat, catn, du, df, and ps. They check `command -q` at call
# time, so they fall back to the base tool and don't depend on PATH from
# another conf.d file.
