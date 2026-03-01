# ── Completion ────────────────────────────────────────
setopt COMPLETE_IN_WORD
setopt AUTO_MENU
setopt ALWAYS_TO_END

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no                              # disable default menu (fzf-tab handles it)

# fzf-tab settings
zstyle ':fzf-tab:*' fzf-flags --height=~15 --layout=reverse --border
zstyle ':fzf-tab:*' switch-group '<' '>'
