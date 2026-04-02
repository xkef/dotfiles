function __fzf_grep --description 'Live grep file contents (rg + fzf)'
    set -l RG_PREFIX 'rg --column --line-number --no-heading --color=always --smart-case'
    set -l selected (: | fzf --ansi --disabled \
        --bind "change:reload:$RG_PREFIX {q} || true" \
        --delimiter ':' \
        --preview 'bat --color=always --highlight-line {2} --line-range {2}:+100 {1} 2>/dev/null' \
        --preview-window 'right:50%:+{2}-5' \
        --header 'Live grep │ CTRL-/ toggle preview │ CTRL-Y copy')
    if test -n "$selected"
        set -l parts (string split ':' $selected)
        if test -n "$parts[1]"
            commandline -r "$EDITOR $parts[1] +$parts[2]"
            commandline -f execute
        end
    end
    commandline -f repaint
end
