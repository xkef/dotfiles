complete -c theme -x -a "(theme --list 2>/dev/null)"
complete -c theme -x -a auto -d 'Match system light/dark appearance'
complete -c theme -l apply -d 'Apply the current theme again'
complete -c theme -l list -s l -d 'List the themes'
complete -c theme -l current -d 'Print the current theme'
complete -c theme -l help -s h -d 'Show help'
