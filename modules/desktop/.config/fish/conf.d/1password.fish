# ── 1Password SSH agent ──────────────────────────────
# git signing runs `ssh-keygen -Y sign`, which reads $SSH_AUTH_SOCK and
# ignores IdentityAgent in ssh_config. Point it at the 1Password socket so
# signing reaches the key ~/.ssh/conf.d/1password.conf gives ssh. Skip
# over SSH to keep a forwarded agent. Deploy links the macOS socket to the
# Linux path.
if not set -q SSH_CONNECTION; and test -S ~/.1password/agent.sock
    set -gx SSH_AUTH_SOCK ~/.1password/agent.sock
end
