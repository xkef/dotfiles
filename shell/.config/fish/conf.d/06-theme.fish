# ── Theme ────────────────────────────────────────────
# Read BAT_THEME from the theme state file
set -l theme_file "$XDG_CONFIG_HOME/theme/current"
if test -f $theme_file
    while read -l line
        switch $line
            case 'bat_theme=*'
                set -gx BAT_THEME (string replace 'bat_theme=' '' $line)
        end
    end <$theme_file
end

# Replay OSC palette on new shells (skip inside tmux)
set -l osc_file "$XDG_CONFIG_HOME/theme/osc-palette"
if test -f $osc_file -a -t 0 -a -z "$TMUX"
    printf '%s' (cat $osc_file) >/dev/tty
end

# Tab completion for the theme command
complete -c theme -x -a "(theme --completions 2>/dev/null | string replace ':' \t)"
complete -c theme -l list -s l -d 'List available themes'
complete -c theme -l toggle -s t -d 'Toggle dark/light variant'
complete -c theme -l help -s h -d 'Show help'
