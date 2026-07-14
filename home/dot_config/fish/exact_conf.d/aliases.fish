# ── Abbreviations ────────────────────────────────────
# Fish abbreviations expand inline (like aliases but you see the full command).
# Use `abbr` for commands you type; `alias` for transparent replacements.

# Quick edit
abbr -a v nvim
abbr -a vi nvim
abbr -a vim nvim
abbr -a helix hx

# Tmux
abbr -a t tmux
abbr -a ta 'tmux attach -t'
abbr -a tn 'tmux new -s'
abbr -a tl 'tmux list-sessions'

# AI tools
# Use `sb <tool>` for an explicit nono sandbox.

# Pipe --help through bat with syntax highlighting (via folke/dot)
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
# eza/bat/dust/duf/procs wrappers live in functions/ (ls, ll, lt, la, eza, cat,
# catn, du, df, ps). They check `command -q` at call time, so they degrade
# gracefully and don't depend on PATH being set by another conf.d file first.
