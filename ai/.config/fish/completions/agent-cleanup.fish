complete -c agent-cleanup -f
complete -c agent-cleanup -s f -l force -d 'Remove the workspace even if protected'
complete -c agent-cleanup -xa '(__fish_ai_agent_slugs)' -d 'Agent slug'
