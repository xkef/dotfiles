function fgd --description 'Pick dirty files to edit (fzf + git diff)'
    git rev-parse --is-inside-work-tree &>/dev/null || return
    set -l files (git -c color.status=always status --short |
        fzf --ansi --multi --nth=2.. --scheme=path \
            --preview 'git diff --color=always -- {2} 2>/dev/null' \
            --header 'Tab select │ Enter open │ CTRL-/ preview' |
        awk '{print $NF}')
    test -n "$files" && $EDITOR $files
end
