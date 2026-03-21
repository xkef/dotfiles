# ── Aliases ───────────────────────────────────────────
# Modern replacements for classic Unix tools.
# $+commands[cmd] is a zsh idiom: 1 if `cmd` is in PATH, 0 otherwise.
# See: man zshexpn "PARAMETER EXPANSION FLAGS"

# eza: modern ls replacement with git integration, icons, and tree view.
# See: https://github.com/eza-community/eza
if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first'
  alias ll='eza -la --group-directories-first --git'
  alias lt='eza -T --level=2'
  alias la='eza -a --group-directories-first'
elif [[ "$OSTYPE" == darwin* ]]; then
  alias ls='ls -G'
  alias ll='ls -Gla'
  alias la='ls -Ga'
else
  alias ls='ls --color=auto'
  alias ll='ls -la'
  alias la='ls -a'
fi

# bat: cat with syntax highlighting, line numbers, and git diff markers.
# -pp: plain mode (no pager, no decorations) — acts like cat but with colors.
# See: https://github.com/sharkdp/bat
if (( $+commands[bat] )); then
  alias cat='bat -pp'
  alias catn='bat'
fi

# Quick edit — muscle memory aliases
alias v='nvim'
alias vi='nvim'
alias vim='nvim'

# Tmux shortcuts
alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux list-sessions'

# Claude Code
alias claude='claude-sandboxed'

# zmv: zsh's built-in batch rename tool. `mmv` uses -W for wildcard mode:
#   mmv *.txt *.md  →  renames all .txt files to .md
# noglob prevents zsh from expanding the globs before zmv sees them.
# See: man zshcontrib "ZMV"
autoload -Uz zmv zargs zcalc regexp-replace
alias mmv='noglob zmv -W'

# Misc
alias help='run-help'
alias reload='exec zsh'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cls='clear'
alias mkdir='mkdir -pv'
alias grep='grep --color=auto'

# Modern disk/process tools (only alias if installed)
# dust: intuitive du replacement with visual bar chart (https://github.com/bootandy/dust)
# duf: modern df with table layout and colors (https://github.com/muesli/duf)
# procs: modern ps with tree view and fuzzy search (https://github.com/dalance/procs)
if (( $+commands[dust] )); then alias du='dust'; else alias du='du -h'; fi
if (( $+commands[duf] )); then alias df='duf'; else alias df='df -h'; fi
if (( $+commands[procs] )); then alias ps='procs'; fi

# ouch: universal archive tool — auto-detects format from extension.
# See: https://github.com/ouch-org/ouch
if (( $+commands[ouch] )); then
  alias extract='ouch decompress'
  alias compress='ouch compress'
fi
