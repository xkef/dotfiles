complete -c ai-agent -f

complete -c ai-agent -n __fish_ai_agent_needs_command -a spawn -d 'Spawn an isolated jj workspace agent'
complete -c ai-agent -n __fish_ai_agent_needs_command -a list -d 'List isolated agents'
complete -c ai-agent -n __fish_ai_agent_needs_command -a finish -d 'Push bookmark, create PR, and remove workspace'
complete -c ai-agent -n __fish_ai_agent_needs_command -a cleanup -d 'Remove merged or explicitly forced agent workspaces'
complete -c ai-agent -n __fish_ai_agent_needs_command -a ui -d 'Open the tmux agent UI'
complete -c ai-agent -n __fish_ai_agent_needs_command -a preview -d 'Preview an agent workspace'

complete -c ai-agent -n '__fish_ai_agent_seen_command spawn' -l agent -xa 'claude pi' -d 'Agent command to launch'
complete -c ai-agent -n '__fish_ai_agent_seen_command spawn' -l brief -d 'Seed .claude-notes/task.md'
complete -c ai-agent -n '__fish_ai_agent_seen_command spawn' -l from -d 'Base jj revision'
complete -c ai-agent -n '__fish_ai_agent_seen_command spawn' -l sandbox -d 'Launch through sb'

complete -c ai-agent -n '__fish_ai_agent_seen_command list' -l format -xa 'human ui' -d 'Output format'
complete -c ai-agent -n '__fish_ai_agent_seen_command list' -l only -xa 'all live dirty merged' -d 'Filter agents'

complete -c ai-agent -n '__fish_ai_agent_seen_command finish' -xa '(__fish_ai_agent_slugs)' -d 'Agent slug'

complete -c ai-agent -n '__fish_ai_agent_seen_command cleanup' -s f -l force -d 'Remove the workspace even if protected'
complete -c ai-agent -n '__fish_ai_agent_seen_command cleanup' -xa '(__fish_ai_agent_slugs)' -d 'Agent slug'

complete -c ai-agent -n '__fish_ai_agent_seen_command preview' -xa '(__fish_ai_agent_slugs)' -d 'Agent slug'

complete -c ai-agent -n '__fish_ai_agent_seen_command ui' -a spawn -d 'Open direct spawn prompt'
