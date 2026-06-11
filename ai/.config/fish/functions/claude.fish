function claude --wraps claude --description "claude-code: auto-install via official script + pin tmux window name"
    if not test -x $HOME/.local/bin/claude
        printf '  Installing claude...\n'
        curl -fsSL https://claude.ai/install.sh | bash -s -- latest
    end

    command -q dots-skills; and dots-skills ensure claude-code

    _ai_run_pinned claude claude $argv
end
