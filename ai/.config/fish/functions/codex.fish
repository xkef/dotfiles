function codex --wraps codex --description "codex wrapper that lazy-installs skills on first launch"
    _ai_ensure_skills codex
    command codex $argv
end
