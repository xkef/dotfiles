# The callers, claude, codex, and pi, pass `sb <tool>`, so the agent starts
# in a nono sandbox and never reenters the fish wrapper that shadows its
# binary.
function _ai_run_pinned -d "Run a command with the tmux window or zellij tab pinned to its name"
    set -l name $argv[1]
    set -l cmd $argv[2..-1]

    set -l pinned 0
    if set -q TMUX
        tmux rename-window $name
        tmux set-window-option allow-rename off
        set pinned 1
    end

    # zellij doesn't rename tabs on its own, so the old name comes back after.
    # The tab id pins the rename to this pane's tab even when focus moves.
    set -l zellij_tab
    if set -q ZELLIJ_PANE_ID
        set zellij_tab (zellij action list-panes -a -j | jq -r --argjson id $ZELLIJ_PANE_ID \
            '.[] | select(.id == $id and (.is_plugin | not)) | "\(.tab_id)\t\(.tab_name)"' | string split \t)
        test -n "$zellij_tab[1]"; and zellij action rename-tab-by-id $zellij_tab[1] $name
    end

    $cmd
    set -l rc $status

    if test $pinned -eq 1
        tmux set-window-option automatic-rename on
        tmux set-window-option -u allow-rename
    end
    if test -n "$zellij_tab[1]"
        zellij action rename-tab-by-id $zellij_tab[1] $zellij_tab[2]
    end
    return $rc
end
