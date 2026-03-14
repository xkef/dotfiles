# ── Key bindings ──────────────────────────────────────
stty -ixon # disable XON/XOFF so Ctrl-S is available
bindkey -e # emacs mode

# Defensive unbinds: disable sequences that cause mysterious behavior
# Ctrl-Q (flow control resume — redundant with stty -ixon)
bindkey -r '^Q'
# Alt-Enter / ESC-Enter (some terminals send this accidentally)
bindkey -r '^[^M'
# Alt-H (run-help — opens man page unexpectedly)
bindkey -r '^[H' '^[h'
# Alt-? (which-command — easy to fat-finger)
bindkey -r '^[?'
# Alt-L (downcase-word — easy to hit instead of Ctrl-L)
bindkey -r '^[l' '^[L'
# Alt-T (transpose-words — rarely intended)
bindkey -r '^[t' '^[T'
# Alt-U (upcase-word — rarely intended)
bindkey -r '^[u' '^[U'
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[[A' history-search-backward # Up arrow
bindkey '^[[B' history-search-forward  # Down arrow
bindkey '^[[3~' delete-char            # Delete key

# Edit command line in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

bindkey '^Z' undo
bindkey ' ' magic-space

# Ctrl-S → yazi (cd-on-quit)
yazi-widget() {
  local tmp
  tmp=$(mktemp -t "yazi-cwd.XXXXXX")
  yazi --cwd-file="$tmp" < /dev/tty
  if cwd=$(command cat -- "$tmp") && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
  zle reset-prompt
}
zle -N yazi-widget
bindkey '^S' yazi-widget
