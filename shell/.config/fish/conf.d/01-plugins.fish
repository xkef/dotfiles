# ── Fisher (plugin manager) ──────────────────────────
# Auto-install Fisher + plugins on first run. The guard variable prevents
# re-entry (the fork bomb that happened when this ran unconditionally).
# See: https://github.com/jorgebucaran/fisher
if not functions -q fisher; and not set -q __fisher_installing
    set -g __fisher_installing 1
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher update 2>/dev/null
    set -e __fisher_installing
end

# ── fzf.fish settings ───────────────────────────────
# fzf-powered completions, file search, git log, processes.
# Equivalent to fzf-tab in zsh.
# See: https://github.com/PatrickF1/fzf.fish
set -g fzf_fd_opts --hidden --follow --exclude .git
set -g fzf_preview_dir_cmd 'eza -1 --color=always --icons --group-directories-first'
set -g fzf_preview_file_cmd 'bat --color=always --style=numbers --line-range :100'
set -g fzf_directory_opts --bind 'ctrl-o:execute(nvim {} &> /dev/tty)'

# Preview for tab completions: dirs (eza), files (bat), executables (--help).
# fzf-preview script handles PATH setup internally.
set -g FZF_COMPLETION_OPTS "\
    --preview 'fzf-preview {1}' \
    --preview-window right:50%:border-left \
    --bind 'ctrl-/:toggle-preview' \
    --bind 'ctrl-f:preview-page-down,ctrl-b:preview-page-up' \
    --bind 'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up' \
    --bind '<:change-prompt(< )+reload(complete -C {q})' \
    --bind '>:change-prompt(> )+reload(complete -C {q})' \
    --bind 'tab:down,btab:up,enter:accept'"
