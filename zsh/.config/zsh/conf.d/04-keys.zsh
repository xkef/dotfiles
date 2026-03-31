# ── Key bindings ──────────────────────────────────────
# Use emacs keybinding mode (Ctrl-A/E/K/W etc.). This is the default for
# most shells and matches readline behavior. Vi mode would be `bindkey -v`.
# See: man zshzle "KEYMAPS"
bindkey -e

# Remove right-prompt indent (the 1-char gap zsh adds before RPROMPT)
ZLE_RPROMPT_INDENT=0

# ── Defensive unbinds ────────────────────────────────
# Disable sequences that cause accidental behavior. bindkey -r removes a
# binding without adding a new one.

# Ctrl-Q: flow control resume (XON) — redundant since we set NO_FLOW_CONTROL
bindkey -r '^Q'
# Alt-Enter / ESC-Enter: some terminals send this accidentally
bindkey -r '^[^M'

# @key shell :: Alt-H :: Context-aware man page (run-help)
# Pressing Alt-H while typing "git commit" opens man git-commit (not man git).
# See: man zshcontrib "ACCESSING ON-LINE HELP"
autoload -Uz run-help run-help-git run-help-sudo run-help-openssl run-help-ip
unalias run-help 2>/dev/null
bindkey '^[H' run-help
bindkey '^[h' run-help

# Unbind keys that are easy to fat-finger and rarely useful:
bindkey -r '^[?'          # Alt-? (which-command)
bindkey -r '^[l' '^[L'    # Alt-L (downcase-word — too close to Ctrl-L)
bindkey -r '^[t' '^[T'    # Alt-T (transpose-words — rebound to tv in 06-fzf.zsh)
bindkey -r '^[u' '^[U'    # Alt-U (upcase-word — rarely intended)

# ── Word boundaries ────────────────────────────────
# By default, Ctrl-W deletes back to the previous whitespace. With bash
# word style, it stops at / . _ - boundaries instead, which is much better
# for editing paths (Ctrl-W on "/usr/local/bin" deletes just "bin").
# WORDCHARS='' ensures NO punctuation is treated as part of a word.
# See: man zshcontrib "ZLE FUNCTIONS", select-word-style
autoload -Uz select-word-style
select-word-style bash
WORDCHARS=''

# ── History navigation ────────────────────────────
# up-line-or-beginning-search: if the line has text, search history for
# commands starting with that text (prefix search). If empty, browse history.
# This is superior to the default up-line-or-history which doesn't filter.
# See: man zshcontrib "ZLE FUNCTIONS"
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
# @key shell :: Ctrl-P / N :: Prefix history search (also arrows)
bindkey '^p' up-line-or-beginning-search    # Ctrl-P
bindkey '^n' down-line-or-beginning-search  # Ctrl-N
bindkey '^[[A' up-line-or-beginning-search  # Up arrow (CSI A)
bindkey '^[[B' down-line-or-beginning-search # Down arrow (CSI B)
bindkey '^[[3~' delete-char                  # Delete key (CSI 3~)

# ── Edit command in $EDITOR ──────────────────────
# @key shell :: Ctrl-X Ctrl-E :: Edit command in nvim
# Save and quit to execute; empty buffer cancels.
# See: man zshzle "edit-command-line"
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# ── Ctrl-Z toggle ────────────────────────────────
# @key shell :: Ctrl-Z :: Toggle fg/bg (undo if no jobs)
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

# ── Smart last-word insertion ────────────────────
# Alt-. inserts the last argument of the previous command (standard behavior).
# smart-insert-last-word improves this by skipping operators and redirections.
# Alt-, (copy-earlier-word) cycles through earlier arguments of the same command.
# See: man zshcontrib "ZLE FUNCTIONS"
autoload -Uz smart-insert-last-word copy-earlier-word
zle -N insert-last-word smart-insert-last-word
zle -N copy-earlier-word
bindkey '^[,' copy-earlier-word

# ── Ctrl-S → yazi cd-on-quit ────────────────────
# @key shell :: Ctrl-S :: Yazi file manager (cd-on-quit)
# `< /dev/tty` ensures yazi gets terminal input even inside a ZLE widget.
yazi-widget() { y < /dev/tty; zle reset-prompt; }
zle -N yazi-widget
bindkey '^S' yazi-widget
