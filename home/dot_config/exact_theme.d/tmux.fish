# Theme adapter for tmux: refreshes the status line. tmux styles use ANSI
# palette slots, so the OSC push from `theme` recolors everything and only
# a redraw remains.
if command -q tmux; and tmux list-sessions &>/dev/null
    tmux refresh-client -S 2>/dev/null || true
end
