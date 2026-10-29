# jj has no branch to switch to. A new change on top of the picked
# bookmark takes its place, newest bookmark first.
function fbr --description 'Start a change on a jj bookmark (tv)'
    set -l bookmark (jj bookmark list --sort committer-date- -T '
        if(remote, "", if(normal_target, name ++ " "
            ++ normal_target.committer().timestamp().ago() ++ " "
            ++ normal_target.description().first_line() ++ "\n"))' |
        tv --source-output '{0}' \
            --preview-command 'jj log --color=always -r "::{0}" --limit 20')
    test -n "$bookmark" && jj new $bookmark
end
