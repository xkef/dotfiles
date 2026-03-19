# ── Key bindings ──────────────────────────────────────
bindkey -e # emacs mode
ZLE_RPROMPT_INDENT=0

# Defensive unbinds: disable sequences that cause mysterious behavior
# Ctrl-Q (flow control resume — redundant with NO_FLOW_CONTROL)
bindkey -r '^Q'
# Alt-Enter / ESC-Enter (some terminals send this accidentally)
bindkey -r '^[^M'
# Alt-H → enhanced run-help (context-aware: `git commit` opens man git-commit)
autoload -Uz run-help run-help-git run-help-sudo run-help-openssl run-help-ip
unalias run-help 2>/dev/null
bindkey '^[H' run-help
bindkey '^[h' run-help
# Alt-? (which-command — easy to fat-finger)
bindkey -r '^[?'
# Alt-L (downcase-word — easy to hit instead of Ctrl-L)
bindkey -r '^[l' '^[L'
# Alt-T (transpose-words — rarely intended)
bindkey -r '^[t' '^[T'
# Alt-U (upcase-word — rarely intended)
bindkey -r '^[u' '^[U'
# Smart word boundaries: Ctrl-W stops at / . _ - instead of deleting entire paths
autoload -Uz select-word-style
select-word-style bash
WORDCHARS=''

# History search: handles multi-line commands + prefix matching
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^p' up-line-or-beginning-search
bindkey '^n' down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search  # Up arrow
bindkey '^[[B' down-line-or-beginning-search # Down arrow
bindkey '^[[3~' delete-char                  # Delete key

# Edit command line in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Ctrl-Z: toggle between foreground and background
fg-bg-toggle() {
  if (( ${#jobstates} )); then
    fg
    zle reset-prompt
  else
    zle undo
  fi
}
zle -N fg-bg-toggle
bindkey '^Z' fg-bg-toggle

# Smart last-word insertion: skips operators/redirections, finds real args
autoload -Uz smart-insert-last-word copy-earlier-word
zle -N insert-last-word smart-insert-last-word
zle -N copy-earlier-word
bindkey '^[,' copy-earlier-word

# Ctrl-S → yazi cd-on-quit
yazi-widget() { y < /dev/tty; zle reset-prompt; }
zle -N yazi-widget
bindkey '^S' yazi-widget
