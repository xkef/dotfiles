# The subcommands and descriptions come from the @key lines in dots.
function __dots_commands
    awk -F ' :: ' '/^ *# @key dots :: / { print $2 "\t" $3 }' (command -s dots)
end

complete -c dots -f
complete -c dots -n __fish_use_subcommand -xa '(__dots_commands)'
complete -c dots -n '__fish_seen_subcommand_from ref' -xa --raw
complete -c dots -n '__fish_seen_subcommand_from theme' -xa "(theme --list 2>/dev/null)"
complete -c dots -n '__fish_seen_subcommand_from theme' -xa --list
