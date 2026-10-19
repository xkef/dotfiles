# ── Mise ─────────────────────────────────────────────
# Disables Homebrew's vendor mise-activate.fish. Shims stay available at
# startup. Project [env] waits until a command is about to run.
set -gx MISE_ACTIVATE_AGGRESSIVE 0
set -gx MISE_FISH_AUTO_ACTIVATE 0

command -q mise; or return

# Shims cover scripts and go last, behind Homebrew. A shim for an
# inactive tool costs about 25ms before it falls through. The activation
# below removes them, as global.toml sets activate_shims = false, and
# installs the cd and preexec hooks that apply project [env].
fish_add_path -gPam $XDG_DATA_HOME/mise/shims

status is-interactive; or return
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
