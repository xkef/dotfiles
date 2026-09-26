function sb -d "Run a command inside a nono sandbox"
    # The agent launchers in conf.d/agents.fish route through here, so every
    # interactive launch runs sandboxed. Use `command <tool>` to skip it.
    if test (count $argv) -eq 0
        echo "Usage: sb <command> [args...]" >&2
        echo "Runs <command> in a nono sandbox using a matching profile." >&2
        echo "Known profiles: claude, pi" >&2
        return 1
    end

    set -l cmd $argv[1]
    set -l rest $argv[2..-1]

    switch $cmd
        case claude pi
            command -q dots-skills; and dots-skills ensure $cmd
    end

    if not command -q nono
        printf '\033[33mNo sandbox available (install nono)\033[0m\n' >&2
        read -P "Continue without sandbox? [y/N] " reply
        string match -qi y -- $reply; or return 1
        command $cmd $rest
        return $status
    end

    # A repository can have its own profile, <command>-<repository name>,
    # that extends the base one with what only its work needs. It sits with
    # the other profiles and never in the repository, so a cloned repository
    # can't widen its own sandbox.
    set -l profile $cmd
    set -l root (jj --ignore-working-copy root 2>/dev/null; or git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$root"; and test -f $HOME/.config/nono/profiles/$cmd-(path basename $root).json
        set profile $cmd-(path basename $root)
    end

    set -l nono_args --silent --log-file /dev/null --allow-cwd --read $DOTFILES_DIR --profile $profile
    test "$SB_ALLOW_LAUNCH_SERVICES" = 1; and set -a nono_args --allow-launch-services
    set -l cmd_args

    switch $cmd
        case claude
            # nono is the OS-level sandbox, and macOS can't nest Seatbelt, so
            # Claude Code's own bash sandbox stays off. With it on, every Bash
            # command fails with "sandbox_apply: Operation not permitted".
            touch $HOME/.claude.json.lock
            set -a cmd_args '--settings' '{"sandbox":{"enabled":false}}'
    end

    # Not exec: the launchers call this function and clear the agent state
    # after the agent exits.
    nono run $nono_args -- $cmd $cmd_args $rest
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
