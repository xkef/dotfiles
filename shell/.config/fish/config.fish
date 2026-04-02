# config.fish — sourced for interactive shells, AFTER all conf.d/ files.
# Environment variables live in conf.d/ (sourced before this file).
# Functions live in functions/ (autoloaded on first call).

set -g fish_greeting

# Machine-local overrides (not tracked in git)
set -l local_conf ~/.config/fish/local.fish
test -f $local_conf && source $local_conf
