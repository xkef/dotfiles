# ── Theme completion ────────────────────────────────────
# Tab completion for the `theme` command (see ~/.local/bin/theme).
# Loaded after compinit (01-plugins.zsh) so compdef is available.
#
# The theme command outputs "name:variant" pairs via --completions,
# which _describe presents as candidates with descriptions.
# See: man zshcompsys "COMPLETION FUNCTIONS"
if (( $+commands[theme] )); then
  _theme() {
    local -a themes flags
    themes=(${(f)"$(theme --completions 2>/dev/null)"})
    flags=(
      '--list:list available themes'
      '--toggle:toggle dark/light variant'
      '--help:show help'
    )
    _describe 'theme' themes -- flags
  }
  compdef _theme theme
fi
