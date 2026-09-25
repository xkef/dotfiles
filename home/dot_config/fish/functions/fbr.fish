function fbr --description 'Interactive git branch switch (tv)'
    set -l branch (git for-each-ref --sort=-committerdate refs/heads/ \
        --format='%(refname:short) %(committerdate:relative) %(subject)' |
        tv --source-output '{0}' \
            --preview-command 'git log --oneline --graph --color=always {0} --')
    test -n "$branch" && git switch $branch
end
