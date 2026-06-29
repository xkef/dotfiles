# Theme adapter (terminal package): persist the current theme as Ghostty's
# untracked include fragment. This file is also the current-theme state read
# by `theme --current`, the LazyVim adapter, and dots-update — it runs first
# (10-) so later fragments see the new state.
# Sourced by `theme` with $THEME_NAME and the parsed palette set.
set -l ghostty_config (set -q XDG_CONFIG_HOME && echo $XDG_CONFIG_HOME || echo $HOME/.config)/ghostty/config
if test -f $ghostty_config
    set -l state_file (path dirname $ghostty_config)/theme
    printf '# Written by `theme` — machine-local current theme.\ntheme = %s\n' \
        $THEME_NAME >$state_file
end
