function claude --wraps claude --description "claude-code: auto-install via official script + pin tmux window name"
    if not test -x $HOME/.local/bin/claude
        printf '  Installing claude...\n'
        curl -fsSL https://claude.ai/install.sh | bash -s -- latest
    end

    _ai_ensure_skills claude-code

    set -l pinned 0
    if set -q TMUX
        set -l agent_slug (tmux display-message -p '#{@agent-slug}' 2>/dev/null)
        if test -z "$agent_slug"
            tmux rename-window claude
            tmux set-window-option allow-rename off
            set pinned 1
        end
    end

    command claude $argv
    set -l rc $status

    if test $pinned -eq 1
        tmux set-window-option automatic-rename on
        tmux set-window-option -u allow-rename
    end
    return $rc
end
