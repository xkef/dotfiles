function fkill --description 'Interactive process kill (tv)'
    set -l sig $argv[1]
    test -z "$sig" && set sig 15
    set -l pid (command ps -eo pid,user,%cpu,command | sed 1d |
        awk -v u=$USER '$2==u' | sort -k3 -rn |
        tv --no-preview --source-output '{0}')
    for p in $pid
        kill -$sig $p
    end
end
