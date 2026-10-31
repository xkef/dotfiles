# ── FIDO2 security keys ──────────────────────────────
# ssh hands the touch prompt to SSH_ASKPASS when its stderr isn't a
# terminal, as under jj, but only with a display or with force. macOS has
# no DISPLAY, so force it. ssh-prompt asks other questions in the
# terminal.
set -gx SSH_ASKPASS ~/.local/bin/ssh-prompt
set -gx SSH_ASKPASS_REQUIRE force
