# ── Shell tool initialization ────────────────────────
# Profile startup with `fish --profile-startup /tmp/fish.prof -ic exit`,
# then `sort -rn /tmp/fish.prof | head -20`. Prompt, cd hooks, and widgets
# serve a prompt only. Scripts such as `theme` and `dots` skip the
# subprocess spawns.
status is-interactive; or return

# __cached_init sources each init script from a cache, so a start spawns
# none of these tools.
__cached_init starship init fish --print-full-init
__cached_init zoxide init fish --cmd z

# The 1Password CLI completion costs about 108ms at startup, so it stays
# out. fish loads it on the first `op` command.

# ── Modern replacements ──────────────────────────────
# Each alias exists only when its tool is installed, so the base command
# stays reachable. This file sorts after env.fish, which sets PATH.
if command -q eza
    alias ls 'eza --group-directories-first'
    alias ll 'ls -la --git'
    alias la 'ls -a'
    alias lt 'ls -T --level=2'
end
command -q bat; and alias cat 'bat -pp'
