status is-interactive; or return
test "$TERM_PROGRAM" = ghostty; or return
set -q TMUX; and return
command -q tmux; or return

# ── tmux session ─────────────────────────────────────
# Ghostty runs tmux as its multiplexer. The first window attaches the
# session named main, or creates it, so a closed window detaches instead of
# killing its shells, as WezTerm's mux domain does. Each further window,
# tab, or split joins a session grouped with main: it shares main's tmux
# windows but shows its own, and it ends when Ghostty closes it.
if test -n "$(tmux list-clients -t main 2>/dev/null)"
    exec tmux new-session -t main \; set-option destroy-unattached on
end
exec tmux new-session -A -s main
