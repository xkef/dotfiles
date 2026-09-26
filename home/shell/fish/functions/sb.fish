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

    set -l nono_args --silent --log-file /dev/null --allow-cwd --read $DOTFILES_DIR --profile $cmd
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
end
