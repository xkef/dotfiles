function pi --wraps pi --description "pi.dev coding agent: auto-install via npm + pin tmux window name"
    if not command -q pi
        if not command -q npm
            printf '  pi: npm not found; install Node.js first\n' >&2
            return 127
        end
        printf '  Installing pi...\n'
        npm install -g @earendil-works/pi-coding-agent
    end

    command -q dots-skills; and dots-skills ensure pi

    _ai_run_pinned pi pi $argv
end
