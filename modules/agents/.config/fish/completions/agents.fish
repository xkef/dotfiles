# Completes the arguments after `agents <command>` as the tool it runs.
function __agents_complete_tool
    set -l args (commandline -xpc)[2..]
    complete -C (string join ' ' -- agent-$args[1] (string escape -- $args[2..]) (commandline -ct))
end

# The subcommands and descriptions come from the @key lines in agents.
function __agents_commands
    awk -F ' :: ' '/^ *# @key agents :: / { print $2 "\t" $3 }' (command -s agents)
end

complete -c agents -f
complete -c agents -n __fish_use_subcommand -xa '(__agents_commands)'
complete -c agents -n __fish_use_subcommand -xa help -d 'Show usage'
complete -c agents -n '__fish_seen_subcommand_from skills trace' -a '(__agents_complete_tool)'

set -l vm_commands shell take drop set update
set -l vm_first "__fish_seen_subcommand_from vm; and not __fish_seen_subcommand_from $vm_commands"
complete -c agents -n $vm_first -a shell -d 'fish on the repository copy'
complete -c agents -n $vm_first -a take -d "Apply the VM copy's changes to the host"
complete -c agents -n $vm_first -a drop -d "Discard the VM copy's changes"
complete -c agents -n $vm_first -a set -d 'Store a token for the VM'
complete -c agents -n $vm_first -a update -d 'Rebuild the VM from dev.yaml'
complete -c agents -n $vm_first -l net -xa 'off trusted full' -d 'Network for the session'
complete -c agents -n $vm_first -l github -d 'Pass the GitHub token to the session'
complete -c agents -n '__fish_seen_subcommand_from vm; and __fish_seen_subcommand_from set' -a claude -d 'Claude Code OAuth token'
complete -c agents -n '__fish_seen_subcommand_from vm; and __fish_seen_subcommand_from set' -a github -d 'GitHub token for gh and git'
