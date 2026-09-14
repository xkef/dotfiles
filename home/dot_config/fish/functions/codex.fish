function codex --wraps codex --description "OpenAI Codex CLI: pin tmux window name"
    if not command -q codex
        printf '  codex: not installed; run `chezmoi apply` or `brew install --cask codex`\n' >&2
        return 127
    end

    _ai_run_pinned codex sb codex $argv
end
