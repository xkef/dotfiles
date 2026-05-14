function jj --wraps jj --description 'jj with commit subject length warning'
    command jj $argv
    set -l rc $status
    switch $argv[1]
        case commit describe
            if test $rc -eq 0
                set -l rev '@'
                test "$argv[1]" = commit && set rev '@-'
                set -l subject (command jj log -r $rev --no-graph -T 'description.first_line()' 2>/dev/null)
                if test (string length -- $subject) -gt 72
                    printf '\e[33mwarning:\e[0m subject is %d chars (GitHub truncates at 72)\n' (string length -- $subject)
                end
            end
    end
    return $rc
end
