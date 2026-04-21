function pi --wraps pi --description "pi.dev coding agent: auto-install via npm + pin tmux window name"
    if not command -q pi
        if not command -q npm
            printf '  pi: npm not found; install Node.js first\n' >&2
            return 127
        end
        printf '  Installing pi...\n'
        npm install -g @mariozechner/pi-coding-agent
    end

    if set -q TMUX
        tmux rename-window pi
        tmux set-window-option allow-rename off
    end

    command pi $argv
    set -l rc $status

    if set -q TMUX
        tmux set-window-option automatic-rename on
        tmux set-window-option -u allow-rename
    end
    return $rc
end
