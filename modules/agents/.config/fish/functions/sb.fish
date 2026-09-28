function sb -d "Run a command inside a nono sandbox"
    # The agent launchers in conf.d/agents.fish route through here, so every
    # interactive launch runs sandboxed. Use `command <tool>` to skip it.
    # Secrets are stripped; credentials come from 1Password. --strict adds
    # no GitHub token, SSH agent, or keychain.
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
    set -l cred_args
    set -l gh_ref "op://Private/GitHub agents/token"
    set -q SB_GH_TOKEN_REF; and set gh_ref $SB_GH_TOKEN_REF
    set -l claude_ref "op://Private/Claude Code/token"
    set -q SB_CLAUDE_TOKEN_REF; and set claude_ref $SB_CLAUDE_TOKEN_REF
    set -l keep MISE_GITHUB_TOKEN
    set -l env_args

    if test $strict = true
        set profile $cmd-strict
        set keep
        set -a env_args -u SSH_AUTH_SOCK
        test $cmd = claude; and set cred_args --env-credential-map $claude_ref CLAUDE_CODE_OAUTH_TOKEN
    else
        set cred_args --env-credential-map $gh_ref GH_TOKEN
    end
    for var in (set --export --names)
        contains -- $var $keep; and continue
        string match -qir 'token|secret|passw|credential|api_?key|private_?key' -- $var
        and set -a env_args -u $var
    end
    if test -n "$cred_args"; and not command -q op
        printf '\033[33mNo 1Password CLI: the agent runs without %s\033[0m\n' $cred_args[3] >&2
        set cred_args
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

    set -l nono_args --silent --log-file /dev/null --allow-cwd --read $DOTFILES_DIR --profile $profile $cred_args
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
