#!/bin/bash

# A best practices Bash script template with many useful functions. This file
# combines the source.sh & script.sh files into a single script. If you want
# your script to be entirely self-contained then this should be what you want!
set -e

function script_usage() {
    cat <<EOF
- - - - - - - - - - - - - - - -
Batch Github Repository Deleter
- - - - - - - - - - - - - - - -
./deleter.sh FILE

    GITHUB_TOKEN: personal access token for github (Settings -> Developer settings -> Personal Access Tokens)

            username/reponame_1
            username/reponame_2
             ...
            username/reponame_n

EOF
}
function git_repo_delete() {
    curl -vL \
        -H "Authorization: token xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
        -H "Content-Type: application/json" \
        -X DELETE https://api.github.com/repos/$1 |
        jq .
}

function main() {
    script_usage

    REPO_FILE=$1

    repos=$(cat "$REPO_FILE")

    for repo in $repos; do (git_repo_delete "$repo"); done
}

main "$@"

exit 0
