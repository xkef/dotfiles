function sb -d "Run a command inside a nono sandbox"
    if test (count $argv) -eq 0
        echo "Usage: sb <command> [args...]" >&2
        echo "Runs <command> in a nono sandbox using a matching profile." >&2
        echo "Known profiles: claude, codex, opencode, pi" >&2
        return 1
    end

    set -l cmd $argv[1]
    set -l rest $argv[2..-1]
    set -l dots (test -f $HOME/.config/dotfiles/dir; and cat $HOME/.config/dotfiles/dir; or echo $HOME/dotfiles)

    if not command -q nono
        printf '\033[33mNo sandbox available (install nono)\033[0m\n' >&2
        read -P "Continue without sandbox? [y/N] " reply
        string match -qi y -- $reply; or return 1
        exec $cmd $rest
    end

    set -l nono_args --silent --log-file /dev/null --allow-cwd --read $dots

    switch $cmd
        case claude
            touch $HOME/.claude.json.lock
            set -a nono_args --profile claude
            test "$CLAUDE_ALLOW_LAUNCH_SERVICES" = 1; and set -a nono_args --allow-launch-services
        case codex
            set -a nono_args --profile codex
            test "$CODEX_ALLOW_LAUNCH_SERVICES" = 1; and set -a nono_args --allow-launch-services
            set -a rest --sandbox danger-full-access --ask-for-approval on-request
        case opencode
            set -a nono_args --profile opencode
            test "$OPENCODE_ALLOW_LAUNCH_SERVICES" = 1; and set -a nono_args --allow-launch-services
        case '*'
            set -a nono_args --profile $cmd
    end

    exec nono run $nono_args -- $cmd $rest
end
