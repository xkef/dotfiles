function fgd --description 'Pick dirty files to edit (fzf + git diff)'
    git rev-parse --is-inside-work-tree &>/dev/null || return
    set -l files (begin
            git diff --name-only
            git diff --name-only --cached
            git ls-files --others --exclude-standard
        end | sort -u |
        fzf --multi --scheme=path \
            --preview 'git diff --color=always -- {} 2>/dev/null || bat --color=always --style=numbers --line-range :200 {} 2>/dev/null' \
            --header 'Tab select │ Enter open │ CTRL-/ preview')
    test (count $files) -gt 0 && $EDITOR $files
end
