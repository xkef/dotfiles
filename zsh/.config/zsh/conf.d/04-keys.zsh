# ── Key bindings ──────────────────────────────────────
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
