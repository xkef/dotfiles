# ── Theme environment ────────────────────────────────────
# The `theme` command (see ~/.local/bin/theme) writes key=value pairs to
# ~/.config/theme/current when switching themes. This file reads that data
# and exports env vars that CLI tools use for color adaptation.
#
# Currently only BAT_THEME is needed (bat uses it for syntax highlighting).
# Other tools (fzf, delta, starship) read their theme from their own config
# files or from ANSI terminal colors, which the theme command also sets.
_td="${XDG_CONFIG_HOME:-$HOME/.config}/theme"
if [[ -f "$_td/current" ]]; then
  while IFS='=' read -r _tk _tv; do
    case "$_tk" in
    bat_theme) export BAT_THEME="$_tv" ;;
    esac
  done <"$_td/current"
fi

# Replay saved OSC palette on new interactive shells so the terminal
# colors match ~/.config/theme/current (no forks, just a tty write).
#
# OSC (Operating System Command) escape sequences reprogram terminal colors:
#   OSC 4;N;rgb:RR/GG/BB   — set ANSI color N (0-15)
#   OSC 10;rgb:...         — set foreground
#   OSC 11;rgb:...         — set background
#   OSC 12;rgb:...         — set cursor color
# See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
#
# Skipped inside tmux: tmux manages its own palette via the theme command's
# reload_tmux function, and replaying here would double-apply colors.
if [[ -f "$_td/osc-palette" ]] && [[ -t 0 ]] && [[ -z "${TMUX:-}" ]]; then
  printf '%s' "$(<"$_td/osc-palette")" >/dev/tty
fi
