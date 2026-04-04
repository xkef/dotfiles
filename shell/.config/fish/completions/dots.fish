complete -c dots -f
complete -c dots -n __fish_use_subcommand -xa doctor -d 'Check dotfiles health'
complete -c dots -n __fish_use_subcommand -xa update -d 'Pull, re-stow, update plugins and tools'
complete -c dots -n __fish_use_subcommand -xa versions -d 'Show installed tool versions'
complete -c dots -n __fish_use_subcommand -xa keys -d 'Show keybinding reference'
complete -c dots -n __fish_use_subcommand -xa theme -d 'Switch terminal + editor theme'
complete -c dots -n '__fish_seen_subcommand_from keys' -xa --raw
complete -c dots -n '__fish_seen_subcommand_from theme' -xa "(theme --completions 2>/dev/null | string replace ':' \t)"
complete -c dots -n '__fish_seen_subcommand_from theme' -xa --list
