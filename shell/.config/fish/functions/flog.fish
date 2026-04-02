function flog --description 'Interactive git log browser (fzf)'
    git log --oneline --graph --color=always --decorate |
        fzf --ansi --no-sort --reverse --height 80% \
            --preview 'echo {} | grep -o "[a-f0-9]\{7,\}" | head -1 | xargs git show --color=always' \
            --bind 'enter:execute(echo {} | grep -o "[a-f0-9]\{7,\}" | head -1 | xargs git show --color=always | less -R)'
end
