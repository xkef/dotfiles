# ── FZF ──────────────────────────────────────────────
if ! (( $+commands[fzf] )); then
  return
fi

# Use fd for file/dir search, sorted by recency (recent first, then rest, deduped)
if (( $+commands[fd] )); then
  # Ctrl-T: recently modified files first, then all files (deduped)
  export FZF_CTRL_T_COMMAND="\
    { fd --type f --changed-within 1week --hidden --follow --exclude .git; \
      fd --type f --hidden --follow --exclude .git; \
    } | awk '!seen[\$0]++'"

  # Alt-C: directories under cwd
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git .'

  # ** tab completion
  _fzf_compgen_path() { fd --hidden --follow --exclude .git . "$1"; }
  _fzf_compgen_dir() { fd --type d --hidden --follow --exclude .git . "$1"; }
fi

# Colors use ANSI references (0-15) so they follow the terminal theme automatically.
# No hardcoded hex — change ghostty theme and FZF adapts.
export FZF_DEFAULT_OPTS=" \
  --height 60% --layout=reverse --border --info=inline-right \
  --tiebreak=chunk,length \
  --color=fg:-1,bg:-1,hl:6,fg+:-1,bg+:8,hl+:6:bold \
  --color=info:5,prompt:4,pointer:4,marker:2,spinner:5,header:3,border:8,gutter:-1 \
  --bind 'ctrl-/:toggle-preview' \
  --bind 'ctrl-y:execute-silent(echo -n {+} | pbcopy 2>/dev/null || echo -n {+} | wl-copy 2>/dev/null || echo -n {+} | xclip -sel clip 2>/dev/null)' \
  --bind 'ctrl-d:half-page-down,ctrl-u:half-page-up' \
  --bind 'ctrl-f:preview-page-down,ctrl-b:preview-page-up'"

# Ctrl-T: file search with bat preview, path-aware scoring
export FZF_CTRL_T_OPTS=" \
  --scheme=path \
  --preview 'bat --color=always --style=numbers --line-range :300 {} 2>/dev/null || cat {}' \
  --preview-window 'right:50%:border-left' \
  --header 'CTRL-/ toggle preview │ CTRL-Y copy'"

# Alt-C: directory search with tree preview, path-aware scoring
export FZF_ALT_C_OPTS=" \
  --scheme=path \
  --preview 'eza -T --color=always --icons --level=2 {} 2>/dev/null || ls -la {}' \
  --preview-window 'right:50%:border-left'"

# fzf shell integration is deferred — see _deferred_tool_init in 07-tools.zsh

# Alt-C works via ghostty macos-option-as-alt=left; Ctrl-X d as fallback
bindkey '^Xd' fzf-cd-widget

# Alt-C global: jump to any previously visited directory (zoxide history)
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
bindkey '^[z' fzf-zoxide-widget
bindkey '^Xz' fzf-zoxide-widget

# Alt-/: live grep (rg + fzf) — type to search file contents; Ctrl-X g as fallback
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
bindkey '^[/' fzf-grep-widget
bindkey '^Xg' fzf-grep-widget

# Alt-T: television smart picker — standalone widget, no tv init zsh needed
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
bindkey '^[t' tv-smart-widget
bindkey '^Xt' tv-smart-widget

# ── FZF-powered functions ────────────────────────────

# Interactive git branch switch
fbr() {
  local branch
  branch=$(git for-each-ref --sort=-committerdate refs/heads/ \
    --format='%(refname:short) %(committerdate:relative) %(subject)' |
    fzf --height 40% --reverse --nth=1 \
      --preview 'git log --oneline --graph --color=always {1} -- | head -20' |
    awk '{print $1}')
  [ -n "$branch" ] && git switch "$branch"
}

# Interactive git log browser
flog() {
  git log --oneline --graph --color=always --decorate |
    fzf --ansi --no-sort --reverse --height 80% \
      --preview 'echo {} | grep -o "[a-f0-9]\{7,\}" | head -1 | xargs git show --color=always' \
      --bind 'enter:execute(echo {} | grep -o "[a-f0-9]\{7,\}" | head -1 | xargs git show --color=always | less -R)'
}

# Interactive git dirty-file picker → editor (multi-select with Tab)
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

# Interactive process kill
fkill() {
  local pid
  pid=$(ps -u "$USER" -o pid,%cpu,tty,cputime,cmd | sed 1d |
    fzf --height 40% --reverse -m | awk '{print $1}')
  [[ -n "$pid" ]] && echo "$pid" | xargs kill "-${1:-15}"
}

# Interactive ripgrep → fzf → editor (live grep)
frg() {
  local file line
  rg --color=always --line-number --no-heading "${@:-.}" |
    fzf --ansi --delimiter ':' \
      --preview 'bat --color=always --highlight-line {2} --line-range {2}:+100 {1} 2>/dev/null' \
      --preview-window 'right:50%:+{2}-5' |
    IFS=':' read -r file line _
  [ -n "$file" ] && ${EDITOR:-nvim} "$file" +"$line"
}
