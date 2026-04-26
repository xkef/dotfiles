# ── Tool initialization ──────────────────────────────
# Profile startup with: fish --profile-startup /tmp/fish.prof -ic exit
# Then: sort -rn /tmp/fish.prof | head -20

# mise: keep shims available at startup, but defer project [env] until a
# command is about to run. Full activation was ~30ms of startup time.
if command -q mise
    fish_add_path -gP $XDG_DATA_HOME/mise/shims
    command mise activate fish --no-hook-env | source

    set -g __mise_env_dirty 1

    function __mise_mark_env_dirty --on-variable PWD
        set -g __mise_env_dirty 1
    end

    function __mise_apply_env --on-event fish_preexec
        set -q __mise_env_dirty; or return
        command mise hook-env -s fish | source
        set -e __mise_env_dirty
    end
end

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
