function sb -d "Run a command inside a nono sandbox"
    # The agent launchers in conf.d/agents.fish route through here, so every
    # interactive launch runs sandboxed. Use `command <tool>` to skip it.
    # --strict picks the <command>-strict profile and drops the tokens and
    # the SSH agent from the environment, for an unfamiliar repository.
    set -l strict false
    if test "$argv[1]" = --strict
        set strict true
        set -e argv[1]
    end

    if test (count $argv) -eq 0
        echo "Usage: sb [--strict] <command> [args...]" >&2
        echo "Runs <command> in a nono sandbox using a matching profile." >&2
        echo "Known profiles: claude, claude-strict, pi" >&2
        return 1
    end

    set -l cmd $argv[1]
    set -l rest $argv[2..-1]
    set -l profile $cmd
    set -l env_args
    if test $strict = true
        set profile $cmd-strict
        set env_args -u GH_TOKEN -u GITHUB_TOKEN -u SSH_AUTH_SOCK
    end

    switch $cmd
        case claude pi
            command -q agent-skills; and agent-skills ensure $cmd
    end

    if not command -q nono
        printf '\033[33mNo sandbox available (install nono)\033[0m\n' >&2
        read -P "Continue without sandbox? [y/N] " reply
        string match -qi y -- $reply; or return 1
        command $cmd $rest
        return $status
    end

    set -l nono_args --silent --log-file /dev/null --allow-cwd --read $DOTFILES_DIR --profile $profile
    test "$SB_ALLOW_LAUNCH_SERVICES" = 1; and set -a nono_args --allow-launch-services
    set -l cmd_args

    switch $cmd
        case claude
            # The repo settings override the keys they name in the settings
            # file Claude Code rewrites. nono is the OS-level sandbox, and
            # macOS can't nest Seatbelt, so Claude Code's own bash sandbox
            # stays off. With it on, every Bash command fails with
            # "sandbox_apply: Operation not permitted".
            touch $HOME/.claude.json.lock
            set -a cmd_args --settings (jq -c '.sandbox.enabled = false' $HOME/.claude/settings.dotfiles.json)
    end

    # Not exec: the launchers call this function and clear the agent state
    # after the agent exits.
    env $env_args nono run $nono_args -- $cmd $cmd_args $rest
    set -l rc $status

    # macOS logs the sandbox denials where only an unsandboxed process may
    # read them, so the run's denials get cached here for `agent-trace
    # sandbox`. It runs in the background because it scans the log.
    if command -q agent-trace
        agent-trace collect >/dev/null 2>&1 &
        disown
    end
    return $rc
end
