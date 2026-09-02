# ── Shell tool initialization ────────────────────────
# Profile startup with: fish --profile-startup /tmp/fish.prof -ic exit
# Then: sort -rn /tmp/fish.prof | head -20
# Prompt, cd hooks, and widgets only matter to a human at a prompt; scripts
# (`theme`, `dots`, tmux's `fish -c`) skip the subprocess spawns entirely.
status is-interactive; or return

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
