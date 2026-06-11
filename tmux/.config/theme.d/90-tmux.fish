# Theme adapter (tmux package): refresh the status line. tmux styles use
# ANSI palette slots, so the OSC push from `theme` recolors everything;
# only a redraw is needed.
if command -q tmux; and tmux list-sessions &>/dev/null
    tmux refresh-client -S 2>/dev/null || true
end
