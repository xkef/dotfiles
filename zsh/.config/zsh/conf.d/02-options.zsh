# ── Shell options ─────────────────────────────────
setopt AUTO_CD              # type dir name to cd
setopt AUTO_PUSHD           # cd pushes to dir stack
setopt PUSHD_IGNORE_DUPS    # no dup entries in dir stack
setopt PUSHD_MINUS          # swap +/- for cd -N
setopt CORRECT              # "did you mean?" for commands
setopt EXTENDED_GLOB        # ^, ~, # as glob operators
setopt INTERACTIVE_COMMENTS # allow # comments in interactive shell

# ── History ──────────────────────────────────────
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY      # save timestamps
setopt SHARE_HISTORY         # share across sessions (implies INC_APPEND_HISTORY)
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_ALL_DUPS  # remove older duplicate entries
setopt HIST_FIND_NO_DUPS     # skip duplicates in reverse search
setopt HIST_IGNORE_SPACE     # leading-space commands stay out of history
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY           # expand !! before running

# ── Named directories ───────────────────────────
hash -d dots="${DOTFILES_DIR:-$HOME/dotfiles}"
hash -d cfg="$XDG_CONFIG_HOME"
hash -d data="$XDG_DATA_HOME"
hash -d cache="$XDG_CACHE_HOME"
