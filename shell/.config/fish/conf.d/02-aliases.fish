# ── Abbreviations ────────────────────────────────────
# Fish abbreviations expand inline (like aliases but you see the full command).
# Use `abbr` for commands you type; `alias` for transparent replacements.

# Quick edit
alias v nvim
alias vi nvim
alias vim nvim

# Tmux
abbr -a t tmux
abbr -a ta 'tmux attach -t'
abbr -a tn 'tmux new -s'
abbr -a tl 'tmux list-sessions'

# Claude Code
alias claude claude-sandboxed

# Pipe --help through bat with syntax highlighting (via folke/dot)
abbr -a --position anywhere --set-cursor -- -h "-h 2>&1 | bat --plain --language=help"

# Misc
abbr -a reload 'exec fish'
alias cls clear
alias mkdir 'mkdir -pv'
alias grep 'grep --color=auto'
alias help man

# ── Modern replacements ─────────────────────────────
if command -q eza
    alias eza 'eza --group-directories-first'
    alias ls eza
    alias ll 'eza -la --git'
    alias lt 'eza -T --level=2'
    alias la 'eza -a'
else if test (uname) = Darwin
    alias ls 'ls -G'
    alias ll 'ls -Gla'
    alias la 'ls -Ga'
else
    alias ls 'ls --color=auto'
    alias ll 'ls -la'
    alias la 'ls -a'
end

if command -q bat
    alias cat 'bat -pp'
    alias catn bat
end

if command -q dust
    alias du dust
else
    alias du 'du -h'
end
if command -q duf
    alias df duf
else
    alias df 'df -h'
end
if command -q procs
    alias ps procs
end

if command -q ouch
    alias extract 'ouch decompress'
    alias compress 'ouch compress'
end
