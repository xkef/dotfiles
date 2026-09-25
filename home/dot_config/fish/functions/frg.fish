function frg --description 'Ripgrep → tv → editor'
    set -l query (string join ' ' -- $argv)
    test -z "$query" && set query '.'
    set -l selected (env RG_QUERY=$query tv text -k 'enter="confirm_selection"' \
        --source-command 'rg --color=always --line-number --no-heading --smart-case -- "$RG_QUERY"')
    if test -n "$selected"
        set -l parts (string split ':' $selected)
        test -n "$parts[1]" && $EDITOR $parts[1] +$parts[2]
    end
end
