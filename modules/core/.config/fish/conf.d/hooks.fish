# ── Podman compatibility ─────────────────────────────
# macOS needs no DOCKER_HOST: podman-mac-helper links /var/run/docker.sock.
if command -q podman; and test (uname) != Darwin
    set -gx DOCKER_HOST "unix://$XDG_RUNTIME_DIR/podman/podman.sock"
end
