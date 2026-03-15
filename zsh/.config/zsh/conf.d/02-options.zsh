# ── Shell options ─────────────────────────────────
setopt AUTO_CD              # type dir name to cd
setopt AUTO_PUSHD           # cd pushes to dir stack
setopt COMBINING_CHARS      # handle combining chars (essential for macOS)
setopt CORRECT              # "did you mean?" for commands
setopt EXTENDED_GLOB        # ^, ~, # as glob operators
setopt GLOB_STAR_SHORT      # **.c instead of **/*.c
setopt HASH_EXECUTABLES_ONLY # only hash executables for command completion
setopt INTERACTIVE_COMMENTS # allow # comments in interactive shell
setopt NO_FLOW_CONTROL      # disable XON/XOFF (frees Ctrl-S/Ctrl-Q)
setopt PIPE_FAIL            # pipeline exit = rightmost non-zero
setopt PUSHD_IGNORE_DUPS    # no dup entries in dir stack
setopt PUSHD_MINUS          # swap +/- for cd -N

CORRECT_IGNORE='[._]*'

# ── History ──────────────────────────────────────
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY      # save timestamps
setopt HIST_FCNTL_LOCK       # kernel-level locking (reliable with SHARE_HISTORY)
setopt SHARE_HISTORY         # share across sessions (implies INC_APPEND_HISTORY)
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_ALL_DUPS  # remove older duplicate entries
setopt HIST_FIND_NO_DUPS     # skip duplicates in reverse search
setopt HIST_IGNORE_SPACE     # leading-space commands stay out of history
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY           # expand !! before running
HISTORY_IGNORE='(ls|ll|la|lt|cd|z|y|pwd|exit|reload|cls|clear)'

# ── Pager ──────────────────────────────────────
export PAGER=less
export LESS="-iFMRX --mouse -#.25"

export LESS_TERMCAP_mb=$'\E[01;31m'      # begin blink (red)
export LESS_TERMCAP_md=$'\E[01;38;5;208m' # begin bold (orange)
export LESS_TERMCAP_me=$'\E[0m'           # end mode
export LESS_TERMCAP_se=$'\E[0m'           # end standout
export LESS_TERMCAP_ue=$'\E[0m'           # end underline
export LESS_TERMCAP_us=$'\E[04;38;5;111m' # begin underline (light blue)

# ── Named directories ───────────────────────────
hash -d dots="${DOTFILES_DIR:-$HOME/dotfiles}"
hash -d cfg="$XDG_CONFIG_HOME"
hash -d data="$XDG_DATA_HOME"
hash -d cache="$XDG_CACHE_HOME"
