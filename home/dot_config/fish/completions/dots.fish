complete -c dots -f
complete -c dots -n __fish_use_subcommand -xa update -d 'Pull the repo and apply changes'
complete -c dots -n __fish_use_subcommand -xa doctor -d 'Check dotfiles health'
complete -c dots -n __fish_use_subcommand -xa diff -d 'Show pending changes'
complete -c dots -n __fish_use_subcommand -xa apply -d 'Apply the source state'
complete -c dots -n __fish_use_subcommand -xa keys -d 'Show keybinding reference'
complete -c dots -n __fish_use_subcommand -xa skills -d 'Refresh shared agent skills from upstream'
complete -c dots -n __fish_use_subcommand -xa theme -d 'Switch terminal + editor theme'
complete -c dots -n '__fish_seen_subcommand_from keys' -xa --raw
complete -c dots -n '__fish_seen_subcommand_from theme' -xa "(theme --completions 2>/dev/null | string replace ':' \t)"
complete -c dots -n '__fish_seen_subcommand_from theme' -xa --list
