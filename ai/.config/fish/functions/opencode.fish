function opencode --wraps opencode --description "opencode wrapper that lazy-installs skills on first launch"
    _ai_ensure_skills opencode
    command opencode $argv
end
