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

    # Warm mise's caches off the critical path so the in-process apply on the
    # next command is fast. Single-flight (skip if a prewarm is still running)
    # and edge-triggered on PWD only — never on the prompt — so it cannot loop.
    function __mise_prewarm --on-variable PWD
        if set -q __mise_prewarm_pid; and command kill -0 $__mise_prewarm_pid 2>/dev/null
            return
        end
        if command -q timeout
            command timeout 2 mise hook-env -s fish >/dev/null 2>&1 &
        else
            command mise hook-env -s fish >/dev/null 2>&1 &
        end
        set -g __mise_prewarm_pid $last_pid
        disown $last_pid 2>/dev/null
    end

    function __mise_apply_env --on-event fish_preexec
        set -q __mise_env_dirty; or return
        command mise hook-env -s fish | source
        set -e __mise_env_dirty
    end
end
