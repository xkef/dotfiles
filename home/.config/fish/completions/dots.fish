complete -c dots -f
complete -c dots -n __fish_use_subcommand -xa switch -d 'Apply the config'
complete -c dots -n __fish_use_subcommand -xa update -d 'Pull the repo, update flake inputs, and switch'
complete -c dots -n __fish_use_subcommand -xa diff -d 'Show what a switch would change'
complete -c dots -n __fish_use_subcommand -xa keys -d 'Show keybinding reference'
complete -c dots -n __fish_use_subcommand -xa theme -d 'Switch terminal + editor theme'
complete -c dots -n '__fish_seen_subcommand_from keys' -xa --raw
complete -c dots -n '__fish_seen_subcommand_from theme' -xa "(theme --list 2>/dev/null)"
complete -c dots -n '__fish_seen_subcommand_from theme' -xa --list
