complete -c agent-skills -f
complete -c agent-skills -n __fish_is_first_arg -a ensure -d 'Install once, then skip while installed'
complete -c agent-skills -n __fish_is_first_arg -a refresh -d 'Reinstall from upstream'
complete -c agent-skills -n '__fish_is_nth_token 2' -a 'claude pi' -d 'Agent the message names'
