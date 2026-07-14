function flog --description 'Interactive git log browser (fzf)'
    git log --color=always --decorate --format='%h%x09%C(auto)%d %s%Creset' |
        fzf --ansi --no-sort --reverse --height 80% --delimiter='\t' \
            --preview 'git show --color=always {1}' \
            --bind 'enter:execute(git show --color=always {1} | less -R)'
end
