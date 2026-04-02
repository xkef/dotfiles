# config.fish — sourced for interactive shells, AFTER all conf.d/ files.
# Environment variables live in conf.d/ (sourced before this file).
# Functions live in functions/ (autoloaded on first call).

set -g fish_greeting

# atuin: must load here (after all conf.d) because PatrickF1/fzf.fish
# installs its own conf.d/fzf.fish that rebinds Ctrl-R. Loading atuin
# last ensures its Ctrl-R binding wins.
if command -q atuin
    set -gx ATUIN_TMUX_POPUP false
    atuin init fish --disable-up-arrow | source
end

# Machine-local overrides (not tracked in git)
set -l local_conf ~/.config/fish/local.fish
test -f $local_conf && source $local_conf
