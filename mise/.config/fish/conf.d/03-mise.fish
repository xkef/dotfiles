# ── Mise ─────────────────────────────────────────────
# Disable Homebrew's vendor mise-activate.fish. Keep shims available at
# startup, but defer project [env] until a command is about to run.
set -q XDG_DATA_HOME; or set -gx XDG_DATA_HOME $HOME/.local/share
set -gx MISE_ACTIVATE_AGGRESSIVE 0
set -gx MISE_FISH_AUTO_ACTIVATE 0

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
