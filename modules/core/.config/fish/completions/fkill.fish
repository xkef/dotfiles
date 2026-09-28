# fkill takes one signal, such as TERM or 9. The list comes from fish's
# own kill completion, which reads `kill -l`.
complete -c fkill -f
complete -c fkill -n __fish_is_first_arg -x \
    -a '(__fish_make_completion_signals; string replace -r "(\d+) (.*)" "\$2\t\$1" -- $__kill_signals)'
