function claude --wraps claude --description "claude-code: auto-install via official script + pin tmux window name"
    if not test -x $HOME/.local/bin/claude
        printf '  Installing claude...\n'
        curl -fsSL https://claude.ai/install.sh | bash -s -- latest
    end

    _ai_ensure_skills claude-code

    if set -q TMUX
        tmux rename-window claude
        tmux set-window-option allow-rename off
    end

    command claude $argv
    set -l rc $status

    if set -q TMUX
        tmux set-window-option automatic-rename on
        tmux set-window-option -u allow-rename
    end
    return $rc
end
