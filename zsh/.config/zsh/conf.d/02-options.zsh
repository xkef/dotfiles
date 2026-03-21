# ── Shell options ─────────────────────────────────
# See: man zshoptions for the full list.
setopt AUTO_CD              # type a dir name to cd into it (no `cd` needed)
setopt AUTO_PUSHD           # cd pushes old dir onto the directory stack (cd -N to go back)
setopt COMBINING_CHARS      # handle Unicode combining characters (essential for macOS)
setopt CORRECT              # "did you mean?" for mistyped commands
setopt EXTENDED_GLOB        # enable ^, ~, # as glob operators (e.g., ^*.log = all non-.log)
setopt GLOB_STAR_SHORT      # allow **.c as shorthand for **/*.c
setopt HASH_EXECUTABLES_ONLY # only hash actual executables (not dirs) for command lookup
setopt INTERACTIVE_COMMENTS # allow # comments in interactive shell (useful for pasting)
setopt NO_FLOW_CONTROL      # disable XON/XOFF flow control (frees Ctrl-S and Ctrl-Q)
setopt PIPE_FAIL            # pipeline exit code = rightmost non-zero (bash-like behavior)
setopt PUSHD_IGNORE_DUPS    # don't push duplicate entries onto the directory stack
setopt PUSHD_MINUS          # swap +/- meaning for `cd -N` (feels more natural)

# Don't offer spelling corrections for filenames starting with . or _
CORRECT_IGNORE='[._]*'

# ── History ──────────────────────────────────────
# History file lives under XDG_STATE_HOME (state = data that should persist
# across restarts but isn't config). Atuin also indexes this file.
# See: man zshparam "HISTFILE", man zshoptions "HISTORY"
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"
HISTSIZE=100000             # in-memory history entries
SAVEHIST=100000             # on-disk history entries
setopt EXTENDED_HISTORY      # save ": timestamp:duration;command" format
setopt HIST_FCNTL_LOCK       # use fcntl locking (prevents corruption with SHARE_HISTORY)
setopt SHARE_HISTORY         # share history across all running sessions in real time
setopt HIST_EXPIRE_DUPS_FIRST # when trimming, remove duplicates before unique entries
setopt HIST_IGNORE_ALL_DUPS  # if a command is already in history, remove the old entry
setopt HIST_FIND_NO_DUPS     # when searching backward, skip duplicate entries
setopt HIST_IGNORE_SPACE     # commands starting with a space aren't recorded (for secrets)
setopt HIST_REDUCE_BLANKS    # collapse extra whitespace in recorded commands
setopt HIST_VERIFY           # expand !! inline instead of executing immediately

# Commands matching this pattern are excluded from history entirely
HISTORY_IGNORE='(ls|ll|la|lt|cd|z|y|pwd|exit|reload|cls|clear)'

# ── Pager ──────────────────────────────────────
export PAGER=less
# -i: case-insensitive search (unless uppercase in pattern)
# -F: quit immediately if output fits on one screen
# -M: long prompt (shows line numbers and percentage)
# -R: pass through ANSI color escape sequences
# -X: don't clear screen on exit (preserves output in scrollback)
# --mouse: enable mouse scrolling
# -#.25: horizontal scroll = 25% of screen width
export LESS="-iFMRX --mouse -#.25"

# LESS_TERMCAP_* — ANSI escape sequences for colored man pages in less.
# These override termcap entries so less renders bold/underline in color.
# See: man termcap, https://unix.stackexchange.com/a/108840
export LESS_TERMCAP_mb=$'\E[01;31m'      # begin blink (red)
export LESS_TERMCAP_md=$'\E[01;38;5;208m' # begin bold (orange)
export LESS_TERMCAP_me=$'\E[0m'           # end mode
export LESS_TERMCAP_se=$'\E[0m'           # end standout
export LESS_TERMCAP_ue=$'\E[0m'           # end underline
export LESS_TERMCAP_us=$'\E[04;38;5;111m' # begin underline (light blue)

# ── Directory listing on cd ─────────────────────
# chpwd_functions: array of functions zsh calls whenever the working directory
# changes. This auto-lists the new directory on every cd.
# See: man zshmisc "SPECIAL FUNCTIONS"
auto-ls() { ls; }
chpwd_functions+=( auto-ls )

# ── Named directories ───────────────────────────
# hash -d creates named directories accessible as ~name (e.g., cd ~dots).
# They also appear in prompts and completions.
# See: man zshbuiltins "hash"
hash -d dots="${DOTFILES_DIR:-$HOME/dotfiles}"
hash -d cfg="$XDG_CONFIG_HOME"
hash -d data="$XDG_DATA_HOME"
hash -d cache="$XDG_CACHE_HOME"
