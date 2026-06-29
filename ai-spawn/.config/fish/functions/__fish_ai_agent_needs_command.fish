function __fish_ai_agent_needs_command -d "Return true when ai-agent needs a subcommand"
    set -l tokens (commandline -opc)
    test (count $tokens) -eq 1
end
