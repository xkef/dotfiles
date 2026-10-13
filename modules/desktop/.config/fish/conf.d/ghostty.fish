status is-interactive; or return
test "$TERM_PROGRAM" = ghostty; or return
set -q TMUX; and return
command -q tmux; or return

# ── tmux session ─────────────────────────────────────
# Ghostty runs tmux as its multiplexer. Each window attaches the session
# named main, or creates it, so a closed window detaches instead of killing
# its shells, as WezTerm's mux domain does.
exec tmux new-session -A -s main
