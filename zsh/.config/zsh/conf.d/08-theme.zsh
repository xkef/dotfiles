# ── Theme completion ────────────────────────────────────
# Loaded after compinit (01-plugins.zsh) so compdef is available.
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
