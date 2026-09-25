status is-interactive; or return

# ── Prompt cursor ────────────────────────────────────
# A steady bar at the prompt and the terminal's block while a command
# runs. Vi mode sets its own shapes.

function __cursor_bar --on-event fish_prompt
    functions -q fish_vi_cursor_handle; or echo -en "\e[6 q"
end

function __cursor_reset --on-event fish_preexec
    functions -q fish_vi_cursor_handle; or echo -en "\e[0 q"
end
