function __fish_ai_agent_seen_command -d "Return true when an ai-agent subcommand is present"
    set -l tokens (commandline -opc)
    contains -- $argv[1] $tokens
end
