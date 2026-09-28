# ── 1Password SSH agent ──────────────────────────────
# git signing runs `ssh-keygen -Y sign`, which reads $SSH_AUTH_SOCK and
# ignores IdentityAgent in ssh_config. Point it at the 1Password socket so
# signing reaches the key ~/.ssh/conf.d/1password.conf gives ssh. Skip
# over SSH to keep a forwarded agent.
if not set -q SSH_CONNECTION
    set -l _op_sock
    switch (uname -s)
        case Darwin
            set _op_sock "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        case Linux
            set _op_sock "$HOME/.1password/agent.sock"
    end
    if test -S "$_op_sock"
        set -gx SSH_AUTH_SOCK "$_op_sock"
    end
end
