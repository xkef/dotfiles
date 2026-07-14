# ── Auto-ls on cd ────────────────────────────────────
function __auto_ls --on-variable PWD
    ls
end

# ── Podman compatibility ─────────────────────────────
if command -q podman
    if test (uname) = Darwin
        function lazydocker --wraps lazydocker
            set -l sock (podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)
            DOCKER_HOST="unix://$sock" command lazydocker $argv
        end
    else
        set -gx DOCKER_HOST "unix://$XDG_RUNTIME_DIR/podman/podman.sock"
    end
end
