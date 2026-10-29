function fgd --description 'Pick changed files to edit (tv + jj diff)'
    jj root &>/dev/null || return
    set -l files (jj diff --name-only |
        tv --preview-command 'jj diff --color=always -- {}' \
            --input-header 'tab select │ enter open │ ctrl-o preview')
    test (count $files) -gt 0 && $EDITOR $files
end
