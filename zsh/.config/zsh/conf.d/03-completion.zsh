# ── Completion ────────────────────────────────────────
setopt COMPLETE_IN_WORD
setopt AUTO_MENU
setopt ALWAYS_TO_END

# Matching: exact → case-insensitive → partial-word → substring
zstyle ':completion:*' matcher-list \
  '' \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no # disable default menu (fzf-tab handles it)

# Group completions by category
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'

# Order: local files → named dirs → path dirs → recent dirs
zstyle ':completion:*' file-sort modification
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories

# Process completion: enrich the candidate list (fzf-tab renders it)
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Caching for expensive completions (dpkg, apt, brew, etc.)
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# ── fzf-tab ──────────────────────────────────────────
zstyle ':fzf-tab:*' fzf-flags --height=~15 --layout=reverse --border
zstyle ':fzf-tab:*' switch-group '<' '>'

# General file preview (bat for files, eza for dirs)
zstyle ':fzf-tab:complete:*:*' fzf-preview \
  '({ [[ -d $realpath ]] && eza -1 --color=always --icons --group-directories-first $realpath; } ||
   { [[ -f $realpath ]] && bat --color=always --style=numbers --line-range :100 $realpath; } ||
   echo $realpath) 2>/dev/null'

# Process previews for kill
zstyle ':fzf-tab:complete:kill:*' fzf-preview 'ps -p $word -o pid,user,%cpu,%mem,start,command 2>/dev/null'
zstyle ':fzf-tab:complete:kill:*' fzf-flags --height=~20 --preview-window=down:3:wrap

# Git previews
zstyle ':fzf-tab:complete:git-(checkout|switch|merge|rebase|diff):*' fzf-preview \
  'git log --oneline --graph --color=always --date=short $word 2>/dev/null | head -20'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
  'git show --color=always --stat $word 2>/dev/null | head -20'

# Environment variable preview
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview \
  'echo ${(P)word}'
