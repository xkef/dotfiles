function frg --description 'Ripgrep → fzf → editor'
    set -l query $argv
    test -z "$query" && set query '.'
    set -l selected (rg --color=always --line-number --no-heading $query |
        fzf --ansi --delimiter ':' \
            --preview 'bat --color=always --highlight-line {2} --line-range {2}:+100 {1} 2>/dev/null' \
            --preview-window 'right,55%,border-rounded,wrap,+{2}-5,<80(down,55%,border-top,wrap,+{2}-5)')
    if test -n "$selected"
        set -l parts (string split ':' $selected)
        test -n "$parts[1]" && $EDITOR $parts[1] +$parts[2]
    end
end
