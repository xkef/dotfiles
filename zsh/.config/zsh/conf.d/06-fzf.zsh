# ── FZF ──────────────────────────────────────────────
# fzf is a general-purpose fuzzy finder for the terminal.
# It reads lines from stdin (or a command), lets you search interactively,
# and outputs the selected line(s) to stdout.
# See: https://github.com/junegunn/fzf
#
# fzf is used here for:
#   1. Shell keybindings (Ctrl-T, Alt-C) — via `fzf --zsh` in 07-tools.zsh
#   2. fzf-tab completion UI — configured in 03-completion.zsh
#   3. Custom widgets and functions (below)
#
# Television (tv) is also used as a complementary picker on Alt-T.
# See: https://github.com/alexpasmantier/television
if ! (( $+commands[fzf] )); then
  return
fi

# ── Source command (fd) ──────────────────────────────
# fd is a faster alternative to find. When available, fzf uses it instead
# of the default `find` command.
# See: https://github.com/sharkdp/fd
if (( $+commands[fd] )); then
  # Ctrl-T source: show recently modified files first (within 1 week),
  # then all files. awk deduplicates (recent wins over the full listing).
  export FZF_CTRL_T_COMMAND="\
    { fd --type f --changed-within 1week --hidden --follow --exclude .git; \
      fd --type f --hidden --follow --exclude .git; \
    } | awk '!seen[\$0]++'"

  # Alt-C source: directories only
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git .'

  # ** tab completion generators — used by fzf's built-in completion system
  # (e.g., `vim **<Tab>` triggers _fzf_compgen_path)
  _fzf_compgen_path() { fd --hidden --follow --exclude .git . "$1"; }
  _fzf_compgen_dir() { fd --type d --hidden --follow --exclude .git . "$1"; }
fi

# ── Default fzf options ─────────────────────────────
# FZF_DEFAULT_OPTS applies to every fzf invocation (widgets, fzf-tab, scripts).
#
# Colors use ANSI indices (0-15) which map to the terminal's palette.
# When you run `theme <name>`, the terminal palette changes via OSC sequences,
# and fzf automatically adapts — no hex codes to maintain per theme.
#   fg:-1  = terminal default foreground
#   bg:-1  = terminal default background (transparent)
#   hl:6   = highlight matches in cyan (ANSI 6)
#   bg+:8  = selected line background = bright black (ANSI 8)
#   gutter:-1 = transparent gutter (no background strip on the left)
# See: https://github.com/junegunn/fzf/wiki/Color-schemes
export FZF_DEFAULT_OPTS=" \
  --height 60% --layout=reverse --border --info=inline-right \
  --tiebreak=chunk,length \
  --color=fg:-1,bg:-1,hl:6,fg+:-1,bg+:8,hl+:6:bold \
  --color=info:5,prompt:4,pointer:4,marker:2,spinner:5,header:3,border:8,gutter:-1 \
  --bind 'ctrl-/:toggle-preview' \
  --bind 'ctrl-y:execute-silent(echo -n {+} | pbcopy 2>/dev/null || echo -n {+} | wl-copy 2>/dev/null || echo -n {+} | xclip -sel clip 2>/dev/null)' \
  --bind 'ctrl-d:half-page-down,ctrl-u:half-page-up' \
  --bind 'ctrl-f:preview-page-down,ctrl-b:preview-page-up'"

# Ctrl-T options: file search with bat preview
# --scheme=path: score paths by their components (exact basename match ranks highest)
export FZF_CTRL_T_OPTS=" \
  --scheme=path \
  --preview 'bat --color=always --style=numbers --line-range :300 {} 2>/dev/null || cat {}' \
  --preview-window 'right:50%:border-left' \
  --header 'CTRL-/ toggle preview │ CTRL-Y copy'"

# Alt-C options: directory search with eza tree preview
export FZF_ALT_C_OPTS=" \
  --scheme=path \
  --preview 'eza -T --color=always --icons --level=2 {} 2>/dev/null || ls -la {}' \
  --preview-window 'right:50%:border-left'"

# fzf shell integration (Ctrl-T, Ctrl-R, Alt-C widgets) is loaded in
# _deferred_tool_init (07-tools.zsh) via `_cached_source fzf --zsh`.
# The widgets defined by `fzf --zsh` use the FZF_*_COMMAND and FZF_*_OPTS
# variables set above.

# @key shell :: Ctrl-T :: File search (fzf)
# @key shell :: Alt-C :: Directory jump under cwd (fzf + fd)
# @key shell :: Ctrl-X d :: Directory jump fallback
bindkey '^Xd' fzf-cd-widget

# ── Custom widgets ───────────────────────────────────
# ZLE widgets: functions registered with `zle -N` that can be bound to keys.
# They modify BUFFER/LBUFFER (the command line) and call `zle accept-line`
# to execute, or `zle reset-prompt` to redraw without executing.
# See: man zshzle "WIDGETS", man zshzle "SPECIAL PARAMETERS"

# @key shell :: Alt-Z :: Jump to visited directory (fzf+zoxide)
# Pipes zoxide's scored directory list into fzf with a tree preview.
# --nth=2: fuzzy match only on the path (column 2), not the score (column 1).
# See: https://github.com/ajeetdsouza/zoxide
fzf-zoxide-widget() {
  setopt localoptions pipefail no_aliases 2>/dev/null
  local dir
  dir=$(zoxide query --list --score 2>/dev/null |
    awk '{print $1, $2}' |
    fzf --scheme=default --no-sort --nth=2 \
      --preview 'eza -T --color=always --icons --level=2 {2} 2>/dev/null || ls -la {2}' \
      --preview-window 'right:50%:border-left' \
      --header 'Visited directories (zoxide)' |
    awk '{print $2}')
  if [[ -n "$dir" ]]; then
    zoxide add "$dir"
    BUFFER="builtin cd -- ${(q)dir}"
    zle accept-line
  fi
  zle reset-prompt
}
zle -N fzf-zoxide-widget
# @key shell :: Ctrl-X z :: Visited directory jump fallback
bindkey '^[z' fzf-zoxide-widget   # Alt-Z
bindkey '^Xz' fzf-zoxide-widget   # Ctrl-X z (fallback)

# @key shell :: Alt-/ :: Live grep file contents (rg + fzf)
# fzf starts with --disabled (no fuzzy filtering); instead, every keystroke
# triggers `rg {query}` via the change:reload binding.
# See: https://github.com/junegunn/fzf/blob/master/ADVANCED.md#using-fzf-as-interactive-ripgrep-launcher
fzf-grep-widget() {
  setopt localoptions pipefail no_aliases 2>/dev/null
  local selected file line
  local RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case"
  selected=$(
    : | fzf --ansi --disabled \
      --bind "change:reload:$RG_PREFIX {q} || true" \
      --delimiter ':' \
      --preview 'bat --color=always --highlight-line {2} --line-range {2}:+100 {1} 2>/dev/null' \
      --preview-window 'right:50%:+{2}-5' \
      --header 'Live grep │ CTRL-/ toggle preview │ CTRL-Y copy'
  )
  if [[ -n "$selected" ]]; then
    IFS=':' read -r file line _ <<< "$selected"
    if [[ -n "$file" ]]; then
      BUFFER="${EDITOR:-nvim} ${(q)file} +${line}"
      zle accept-line
    fi
  fi
  zle reset-prompt
}
zle -N fzf-grep-widget
# @key shell :: Ctrl-X g :: Live grep fallback
bindkey '^[/' fzf-grep-widget    # Alt-/
bindkey '^Xg' fzf-grep-widget   # Ctrl-X g (fallback)

# @key shell :: Alt-T :: Television smart picker
# tv is a channel-oriented fuzzy finder — press Alt-T to open it, then
# Ctrl-T inside tv to switch between channels (files, git-branch, env, etc.).
# See: https://github.com/alexpasmantier/television
tv-smart-widget() {
  setopt localoptions pipefail no_aliases 2>/dev/null
  local result
  result=$(tv 2>/dev/tty)
  if [[ -n "$result" ]]; then
    LBUFFER+="$result"
  fi
  zle reset-prompt
}
zle -N tv-smart-widget
# @key shell :: Ctrl-X t :: Television fallback
bindkey '^[t' tv-smart-widget    # Alt-T
bindkey '^Xt' tv-smart-widget    # Ctrl-X t (fallback)

# ── FZF-powered functions ────────────────────────────
# These are regular shell functions (not ZLE widgets) invoked by name.

# fbr: interactive git branch switch — sorted by most recent commit
fbr() {
  local branch
  branch=$(git for-each-ref --sort=-committerdate refs/heads/ \
    --format='%(refname:short) %(committerdate:relative) %(subject)' |
    fzf --height 40% --reverse --nth=1 \
      --preview 'git log --oneline --graph --color=always {1} -- | head -20' |
    awk '{print $1}')
  [ -n "$branch" ] && git switch "$branch"
}

# flog: interactive git log browser — navigate commits with preview
flog() {
  git log --oneline --graph --color=always --decorate |
    fzf --ansi --no-sort --reverse --height 80% \
      --preview 'echo {} | grep -o "[a-f0-9]\{7,\}" | head -1 | xargs git show --color=always' \
      --bind 'enter:execute(echo {} | grep -o "[a-f0-9]\{7,\}" | head -1 | xargs git show --color=always | less -R)'
}

# fgd: pick dirty files to edit — multi-select with Tab, preview shows diff
fgd() {
  git rev-parse --is-inside-work-tree &>/dev/null || return
  local files
  files=$(git -c color.status=always status --short |
    fzf --ansi --multi --nth=2.. --scheme=path \
      --preview 'git diff --color=always -- {2} 2>/dev/null' \
      --preview-window 'right:60%:border-left' \
      --header 'Tab select │ Enter open │ CTRL-/ preview' |
    awk '{print $NF}')
  [[ -n "$files" ]] && ${EDITOR:-nvim} ${(f)files}
}

# fkill: interactive process kill — multi-select, default signal SIGTERM (15)
fkill() {
  local pid
  pid=$(command ps -eo pid,user,%cpu,command | sed 1d | awk -v u="$USER" '$2==u' | sort -k3 -rn |
    fzf --height 40% --reverse -m | awk '{print $1}')
  [[ -n "$pid" ]] && echo "$pid" | xargs kill "-${1:-15}"
}

# frg: ripgrep → fzf → editor — search files, pick a match, open at that line
frg() {
  local file line
  rg --color=always --line-number --no-heading "${@:-.}" |
    fzf --ansi --delimiter ':' \
      --preview 'bat --color=always --highlight-line {2} --line-range {2}:+100 {1} 2>/dev/null' \
      --preview-window 'right:50%:+{2}-5' |
    IFS=':' read -r file line _
  [ -n "$file" ] && ${EDITOR:-nvim} "$file" +"$line"
}
