# ── Tool initialization ──────────────────────────────
# Profile startup with: fish --profile-startup /tmp/fish.prof -ic exit
# Then: sort -rn /tmp/fish.prof | head -20

# mise: add shims to PATH directly (saves ~26ms vs `mise activate`)
# The mise wrapper in functions/mise.fish runs `mise reshim` after install/use.
fish_add_path -gP $HOME/.local/share/mise/shims

# starship: cross-shell prompt
if command -q starship
    starship init fish | source
end

# zoxide: smarter cd with frecency
if command -q zoxide
    zoxide init fish --cmd z | source
end

# direnv: per-directory .envrc loader
if command -q direnv
    direnv hook fish | source
end

# navi: interactive cheatsheets (Ctrl-G)
if command -q navi
    navi widget fish | source
end

# 1Password CLI: skip completion at startup (~108ms).
# Completions load lazily when fish parses `op` commands.
