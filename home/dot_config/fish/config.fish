# Sourced for interactive shells after every conf.d/ file. Environment
# variables sit in conf.d/. Functions sit in functions/ and load on first
# call.

set -g fish_greeting

# Machine-local overrides, untracked.
set -l local_conf ~/.config/fish/local.fish
test -f $local_conf && source $local_conf
