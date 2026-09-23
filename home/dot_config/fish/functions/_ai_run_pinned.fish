# The callers, claude, codex, and pi, pass `sb <tool>`, so the agent starts
# in a nono sandbox and never reenters the fish wrapper that shadows its
# binary.
function _ai_run_pinned -d "Run a command with the tmux window pinned to its name"
    set -l name $argv[1]
    set -l cmd $argv[2..-1]

    set -l pinned 0
    if set -q TMUX
        tmux rename-window $name
        tmux set-window-option allow-rename off
        set pinned 1
    end

    $cmd
    set -l rc $status

    if test $pinned -eq 1
        tmux set-window-option automatic-rename on
        tmux set-window-option -u allow-rename
    end
    return $rc
end
