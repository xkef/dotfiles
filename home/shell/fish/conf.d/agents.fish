# Agent launchers. Each function installs its agent on first use, then runs
# it through `sb`. `command <agent>` skips both.

function claude --wraps claude --description "Claude Code in a nono sandbox"
    if not command -q claude
        printf '  Installing claude...\n'
        curl -fsSL https://claude.ai/install.sh | bash -s -- latest; or return
    end
    # `claude update` writes a new version under ~/.local/share/claude and
    # replaces the ~/.local/bin/claude symlink. The profile grants neither,
    # and widening it would let the agent replace its own binary and every
    # other user tool in ~/.local/bin.
    if contains -- "$argv[1]" update
        command claude $argv
        return
    end

    sb claude $argv
    set -l rc $status

    # The agent may exit without removing its agent-state entry: a crash or
    # a killed sandbox.
    agent-state clear
    return $rc
end

function pi --wraps pi --description "pi.dev coding agent in a nono sandbox"
    if not command -q pi
        printf '  Installing pi...\n'
        npm install -g @earendil-works/pi-coding-agent; or return
    end

    # pi picks its theme by name from a file the tinty pi-theme hook renders.
    # A machine that has never switched themes has no file yet, and pi falls
    # back to its built-in dark theme without reporting it. Render the
    # current theme once.
    set -l pi_agent_dir (set -q PI_CODING_AGENT_DIR && echo $PI_CODING_AGENT_DIR || echo $HOME/.pi/agent)
    if command -q theme; and not test -f $pi_agent_dir/themes/dots.json
        theme (theme --current) >/dev/null
    end

    sb pi $argv
    set -l rc $status

    # The agent may exit without removing its agent-state entry: a crash or
    # a killed sandbox.
    agent-state clear
    return $rc
end
