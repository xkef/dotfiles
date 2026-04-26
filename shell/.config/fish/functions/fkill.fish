function fkill --description 'Interactive process kill (fzf)'
    set -l sig $argv[1]
    test -z "$sig" && set sig 15
    set -l pid (command ps -eo pid,user,%cpu,command | sed 1d |
        awk -v u=$USER '$2==u' | sort -k3 -rn |
        fzf --height 40% --reverse -m | awk '{print $1}')
    for p in $pid
        kill -$sig $p
    end
end
