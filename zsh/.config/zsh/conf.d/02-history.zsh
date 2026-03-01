# ── History ───────────────────────────────────────────
HISTFILE="$XDG_STATE_HOME/zsh/history"
mkdir -p "$(dirname "$HISTFILE")"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY       # record timestamps
setopt HIST_EXPIRE_DUPS_FIRST # expire dups first
setopt HIST_IGNORE_DUPS       # ignore consecutive dups
setopt HIST_IGNORE_ALL_DUPS   # remove older dup entries
setopt HIST_IGNORE_SPACE      # ignore commands with leading space
setopt HIST_VERIFY            # show before executing history
setopt SHARE_HISTORY          # share across sessions
setopt INC_APPEND_HISTORY     # append immediately
