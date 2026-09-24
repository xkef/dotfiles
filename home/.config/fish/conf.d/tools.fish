# ── Shell tool initialization ────────────────────────
# Profile startup with `fish --profile-startup /tmp/fish.prof -ic exit`,
# then `sort -rn /tmp/fish.prof | head -20`. Prompt, cd hooks, and widgets
# serve a prompt only. Scripts such as `theme` and `dots` skip the
# subprocess spawns.
status is-interactive; or return

if command -q starship
    starship init fish | source
end

if command -q zoxide
    zoxide init fish --cmd z | source
end

# The 1Password CLI completion costs about 108ms at startup, so it stays
# out. fish loads it on the first `op` command.
