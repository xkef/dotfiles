# ── Theme completion ────────────────────────────────────
# Loaded after compinit (01-plugins.zsh) so compdef is available.
if (( $+commands[theme] )); then
  _theme() {
    local -a themes flags
    themes=(
      'catppuccin-mocha:dark catppuccin'
      'catppuccin-latte:light catppuccin'
      'tokyonight:dark tokyonight'
      'tokyonight-day:light tokyonight'
      'rose-pine:dark rosé pine'
      'rose-pine-dawn:light rosé pine'
      'gruvbox-dark:dark gruvbox'
      'gruvbox-light:light gruvbox'
      'nord:dark nord'
    )
    flags=(
      '--list:list available themes'
      '--toggle:toggle dark/light variant'
      '--help:show help'
    )
    _describe 'theme' themes -- flags
  }
  compdef _theme theme
fi
