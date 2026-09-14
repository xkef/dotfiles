# The callers (claude, codex, pi) pass `sb <tool>`, so the agent starts in a
# nono sandbox and never re-enters the fish wrapper that shadows its binary.
function _ai_run_pinned -d "Run a command with the tmux window pinned to its name"
    set -l name $argv[1]
    set -l cmd $argv[2..-1]

    set -l pinned 0
    if set -q TMUX
        # Workspace agents own their window via the @agent-slug option set
        # by ai-agent; only pin plain interactive windows.
        set -l agent_slug (tmux display-message -p '#{@agent-slug}' 2>/dev/null)
        if test -z "$agent_slug"
            tmux rename-window $name
            tmux set-window-option allow-rename off
            set pinned 1
        end
    end

    $cmd
    set -l rc $status

    if test $pinned -eq 1
        tmux set-window-option automatic-rename on
        tmux set-window-option -u allow-rename
    end
    return $rc
end
