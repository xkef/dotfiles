complete -c agents -f
complete -c agents -n __fish_use_subcommand -xa skills -d 'Refresh shared agent skills from upstream'
complete -c agents -n __fish_use_subcommand -xa trace -d 'Report failed tool calls in Claude Code sessions'
complete -c agents -n __fish_use_subcommand -xa vm -d 'Run Claude Code in the Lima VM'
complete -c agents -n '__fish_seen_subcommand_from skills' -xa 'ensure refresh'
complete -c agents -n '__fish_seen_subcommand_from trace' -xa 'list errors denials sandbox collect --all --since'
