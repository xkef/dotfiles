# ── Completion ────────────────────────────────────────
# See: man zshcompsys for the full completion system documentation.

setopt COMPLETE_IN_WORD   # complete from both ends of a word (cursor in middle)
setopt AUTO_MENU          # show completion menu on second Tab press
setopt ALWAYS_TO_END      # move cursor to end of word after completing

# Matching: cascading strategy for fuzzy completion.
# Tried in order; first match wins:
#   1. exact match
#   2. case-insensitive match (a↔A)
#   3. partial-word match (anchored at . _ - boundaries, e.g., f.b → foo.bar)
#   4. substring match (anywhere in the candidate)
# See: man zshcompsys "COMPLETION MATCHING CONTROL"
zstyle ':completion:*' matcher-list \
  '' \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

# Color candidates using LS_COLORS (files get type-based coloring)
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Disable zsh's default completion menu — fzf-tab provides a better one
zstyle ':completion:*' menu no

# Group completions by category with a header
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'

# Directory completion order: local dirs → dir stack → PATH dirs
# file-sort modification: show recently modified files first
zstyle ':completion:*' file-sort modification
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories

# Process completion: colorize PID and show full command for kill/killall
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Skip path completion for components that already resolve as directories
# (avoids slow stat calls on network mounts)
zstyle ':completion:*' accept-exact-dirs true

# Cache expensive completions (dpkg, apt, brew, etc.)
# See: man zshcompsys "USE OF COMPINIT WITH A CACHE"
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# ── fzf-tab ──────────────────────────────────────────
# fzf-tab replaces the default completion menu with fzf. Configuration uses
# zstyle under the ':fzf-tab:' namespace. The fzf-flags style passes options
# directly to the fzf binary.
# See: https://github.com/Aloxaf/fzf-tab#configure

# --height=~15: inline fzf popup (~15 lines, expands as needed)
# --layout=reverse: results above prompt (top-down)
# --border: draw a box around the picker
zstyle ':fzf-tab:*' fzf-flags --height=~15 --layout=reverse --border

# Switch between completion groups (e.g., files vs commands) with < and >
zstyle ':fzf-tab:*' switch-group '<' '>'

# General file preview: bat for files, eza for directories.
# $realpath is a special fzf-tab variable containing the resolved path.
zstyle ':fzf-tab:complete:*:*' fzf-preview \
  '({ [[ -d $realpath ]] && eza -1 --color=always --icons --group-directories-first $realpath; } ||
   { [[ -f $realpath ]] && bat --color=always --style=numbers --line-range :100 $realpath; } ||
   echo $realpath) 2>/dev/null'

# Process previews for kill — show process details in the preview window
zstyle ':fzf-tab:complete:kill:*' fzf-preview 'ps -p $word -o pid,user,%cpu,%mem,start,command 2>/dev/null'
zstyle ':fzf-tab:complete:kill:*' fzf-flags --height=~20 --preview-window=down:3:wrap

# Git previews — show branch log or commit details
zstyle ':fzf-tab:complete:git-(checkout|switch|merge|rebase|diff):*' fzf-preview \
  'git log --oneline --graph --color=always --date=short $word 2>/dev/null | head -20'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
  'git show --color=always --stat $word 2>/dev/null | head -20'

# Environment variable preview — expand the variable's value
# ${(P)word} is a zsh parameter expansion flag: indirect reference (like ${!var} in bash)
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview \
  'echo ${(P)word}'
