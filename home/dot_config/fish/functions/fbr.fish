function fbr --description 'Interactive git branch switch (fzf)'
    set -l branch (git for-each-ref --sort=-committerdate refs/heads/ \
        --format='%(refname:short) %(committerdate:relative) %(subject)' |
        fzf --height 40% --reverse --nth=1 \
            --preview 'git log --oneline --graph --color=always {1} -- | head -20' |
        awk '{print $1}')
    test -n "$branch" && git switch $branch
end
