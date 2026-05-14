# ── Shell tool initialization ────────────────────────
# Profile startup with: fish --profile-startup /tmp/fish.prof -ic exit
# Then: sort -rn /tmp/fish.prof | head -20

# starship: cross-shell prompt
if command -q starship
    starship init fish | source
end

# zoxide: smarter cd with frecency
if command -q zoxide
    zoxide init fish --cmd z | source
end

# navi: interactive cheatsheets (Ctrl-G)
if command -q navi
    navi widget fish | source
end

# 1Password CLI: skip completion at startup (~108ms).
# Completions load lazily when fish parses `op` commands.
