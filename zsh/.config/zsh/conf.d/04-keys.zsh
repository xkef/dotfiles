# ── Key bindings ──────────────────────────────────────
stty -ixon # disable XON/XOFF so Ctrl-S is available
bindkey -e # emacs mode
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
