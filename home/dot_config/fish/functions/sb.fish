function sb -d "Run a command inside a nono sandbox"
    if test (count $argv) -eq 0
        echo "Usage: sb <command> [args...]" >&2
        echo "Runs <command> in a nono sandbox using a matching profile." >&2
        echo "Known profiles: claude, pi" >&2
        return 1
    end

    set -l cmd $argv[1]
    set -l rest $argv[2..-1]

    switch $cmd
        case claude
            command -q dots-skills; and dots-skills ensure claude-code
        case pi
            command -q dots-skills; and dots-skills ensure pi
    end

    if not command -q nono
        printf '\033[33mNo sandbox available (install nono)\033[0m\n' >&2
        read -P "Continue without sandbox? [y/N] " reply
        string match -qi y -- $reply; or return 1
        exec $cmd $rest
    end

    set -l nono_args --silent --log-file /dev/null --allow-cwd --read $DOTFILES_DIR
    set -l cmd_args

    switch $cmd
        case claude
            touch $HOME/.claude.json.lock
            set -a nono_args --profile claude
            test "$CLAUDE_ALLOW_LAUNCH_SERVICES" = 1; and set -a nono_args --allow-launch-services
            # nono already provides the OS-level sandbox. Disable Claude Code's
            # built-in bash sandbox so it does not try to nest sandbox-exec
            # inside nono — macOS cannot nest Seatbelt, so every Bash command
            # would otherwise fail with "sandbox_apply: Operation not permitted".
            set -a cmd_args --settings '{"sandbox":{"enabled":false}}'
        case '*'
            set -a nono_args --profile $cmd
    end

    exec nono run $nono_args -- $cmd $cmd_args $rest
end
