# ── Tool initialization ──────────────────────────────
# Profile startup with: fish --profile-startup /tmp/fish.prof -ic exit
# Then: sort -rn /tmp/fish.prof | head -20

# mise: full activation so per-project [env] (e.g. PATH overlays in .mise.toml) loads on cd.
# Shims-only is faster (~26ms) but doesn't apply [env]; that broke `cargo build` in
# repos like seance that need tools/ on PATH for an xcrun wrapper.
if command -q mise
    mise activate fish | source
end

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
