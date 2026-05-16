function pi --wraps pi --description "pi.dev coding agent: auto-install via npm + pin tmux window name"
    if not command -q pi
        if not command -q npm
            printf '  pi: npm not found; install Node.js first\n' >&2
            return 127
        end
        printf '  Installing pi...\n'
        npm install -g @earendil-works/pi-coding-agent
    end

    _ai_ensure_skills pi

    set -l pinned 0
    if set -q TMUX
        set -l agent_slug (tmux display-message -p '#{@agent-slug}' 2>/dev/null)
        if test -z "$agent_slug"
            tmux rename-window pi
            tmux set-window-option allow-rename off
            set pinned 1
        end
    end

    command pi $argv
    set -l rc $status

    if test $pinned -eq 1
        tmux set-window-option automatic-rename on
        tmux set-window-option -u allow-rename
    end
    return $rc
end
