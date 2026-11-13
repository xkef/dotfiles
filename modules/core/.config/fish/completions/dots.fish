# The subcommands and descriptions come from the @key lines in dots.
function __dots_commands
    awk -F ' :: ' '/^ *# @key dots :: / { print $2 "\t" $3 }' (command -s dots)
end

complete -c dots -f
complete -c dots -n __fish_use_subcommand -xa '(__dots_commands)'
complete -c dots -n '__fish_seen_subcommand_from ref' -xa --raw
complete -c dots -n '__fish_seen_subcommand_from theme' -xa "(theme --list 2>/dev/null)"
complete -c dots -n '__fish_seen_subcommand_from theme' -xa --list
complete -c dots -n '__fish_seen_subcommand_from apply update' -l plan -d 'Print modules, packages, and steps'
complete -c dots -n '__fish_seen_subcommand_from apply update' -l no-admin -d 'Run nothing that needs sudo'
complete -c dots -n '__fish_seen_subcommand_from apply update' -l modules -x -d 'Select modules, comma-separated'
complete -c dots -n '__fish_seen_subcommand_from apply update' -l yes -d 'Apply without asking'
complete -c dots -n '__fish_seen_subcommand_from apply update diff' -l help -d 'Print the options'
