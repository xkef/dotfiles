# Sandboxed AI agents. nix/agents.toml is the registry, and this module
# renders every file that depends on it: the fish launchers, `sb` and its
# completions, the nono profiles, and each agent's global rules file. The
# agents also write their own settings files at runtime, so activation
# merges the tracked keys into those instead of replacing them.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  agents = (lib.importTOML ./agents.toml).agents;
  names = lib.attrNames agents;
  forEach = f: lib.concatMapStrings (name: f name agents.${name}) names;
  json = pkgs.formats.json { };

  launcher =
    name: agent:
    lib.concatStringsSep "\n" (
      [
        ""
        "function ${name} --wraps ${name} --description \"${agent.description} in a nono sandbox\""
        "    if not command -q ${name}"
      ]
      ++ (
        if agent ? install then
          [
            "        printf '  Installing ${name}...\\n'"
            "        ${agent.install}; or return"
          ]
        else
          [
            "        printf '  ${name}: not installed; run `dots switch`\\n' >&2"
            "        return 127"
          ]
      )
      ++ [ "    end" ]
      ++ lib.optionals (agent ? unsandboxed) [
        "    # Subcommands that rewrite the install itself run outside the sandbox."
        "    if contains -- \"$argv[1]\" ${lib.concatStringsSep " " agent.unsandboxed}"
        "        command ${name} $argv"
        "        return"
        "    end"
      ]
      ++ lib.optionals (agent ? prelaunch) (
        [ "" ] ++ map (line: "    ${line}") (lib.splitString "\n" agent.prelaunch)
      )
      ++ [
        ""
        "    sb ${name} $argv"
        "    set -l rc $status"
        ""
        "    # The agent may exit without clearing its pane's agent state: a crash,"
        "    # a killed sandbox, or Codex, which has no exit hook."
        "    agent-state clear"
        "    return $rc"
        "end"
        ""
      ]
    );

  sbCase =
    name: agent:
    lib.optionalString (agent ? args || agent ? touch) (
      "        case ${name}\n"
      + lib.concatMapStrings (file: "            touch ${file}\n") (agent.touch or [ ])
      + lib.optionalString (agent ? args) "            set -a cmd_args ${lib.escapeShellArgs agent.args}\n"
    );

  # The toolchain surface every agent needs: the Nix store, which holds the
  # tools and the linked configs, mise, jj, maven, npm, cargo, rustup, gh,
  # shared skills, and keychain. Commit signing runs `ssh-keygen
  # -Y sign`, which asks the 1Password agent for the signature. git and jj
  # inline the public key, so ~/.ssh stays denied. deny_macos_private covers
  # the 1Password container, so only the socket gets a bypass.
  sockets = [
    "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    "$HOME/.1password/agent.sock"
  ];
  profile =
    name: agent:
    let
      n = agent.nono;
    in
    lib.recursiveUpdate {
      "$schema" = "https://nono.dev/schemas/nono-profile.schema.json";
      extends = "default";
      meta = {
        inherit name;
        inherit (n) version description;
      };
      groups.include = [
        "git_config"
        "mise_manager"
        "node_runtime"
        {
          name = "user_caches_macos";
          when = "macos";
        }
        "unlink_protection"
        "nix_runtime"
      ]
      ++ n.groups or [ ];
      filesystem = {
        allow = n.allow or [ ] ++ [
          "$HOME/.agents"
          "$HOME/.m2"
          "$HOME/.npm"
          "$XDG_CACHE_HOME/mise"
          "$XDG_CONFIG_HOME/jj"
          "$XDG_DATA_HOME/cargo"
          "$XDG_DATA_HOME/rustup"
          "$HOME/Library/Keychains"
        ];
        read = [
          "$XDG_DATA_HOME/mise"
          "$XDG_STATE_HOME/mise"
          "$XDG_CONFIG_HOME/gh"
          "$XDG_CONFIG_HOME/git"
          "$XDG_CONFIG_HOME/nono/profiles"
          "$XDG_CONFIG_HOME/nono/packages"
        ];
        unix_socket = sockets;
        bypass_protection = [ "$HOME/Library/Keychains" ] ++ sockets;
      }
      // lib.optionalAttrs (n ? allow_file) { inherit (n) allow_file; };
      workdir.access = "readwrite";
    } (n.extra or { });

  # Merges the tracked keys over a settings file the agent writes at runtime.
  # Tracked keys win, and the rest stays.
  mergeSettings = pkgs.writeShellScript "merge-agent-settings" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ pkgs.bash pkgs.jq pkgs.gawk pkgs.coreutils ]}
    home=${config.home.homeDirectory}

    merge_json() {
      local target=$1 managed=$2 current='{}'
      [ -s "$target" ] && current=$(cat "$target")
      mkdir -p "$(dirname "$target")"
      printf '%s' "$current" | jq --slurpfile m "$managed" '. * $m[0]' >"$target.tmp"
      mv "$target.tmp" "$target"
    }

    merge_json "$home/.claude/settings.json" ${./files/claude-settings.json}
    merge_json "$home/.pi/agent/settings.json" ${./files/pi-settings.json}

    codex="$home/.codex/config.toml"
    mkdir -p "$(dirname "$codex")"
    touch "$codex"
    ${./files/codex-config.sh} <"$codex" >"$codex.tmp"
    mv "$codex.tmp" "$codex"
  '';
in
{
  home.file = {
    ".config/fish/conf.d/agents.fish".text = ''
      # Agent launchers, one per entry in nix/agents.toml. Each function
      # installs its agent on first use, then runs it through `sb`. `command
      # <agent>` skips both.
    ''
    + forEach launcher;

    ".config/fish/functions/sb.fish".text = ''
      function sb -d "Run a command inside a nono sandbox"
          # The agent launchers in conf.d/agents.fish route through here, so every
          # interactive launch runs sandboxed. Use `command <tool>` to skip it. The
          # per-agent cases render from nix/agents.toml.
          if test (count $argv) -eq 0
              echo "Usage: sb <command> [args...]" >&2
              echo "Runs <command> in a nono sandbox using a matching profile." >&2
              echo "Known profiles: ${lib.concatStringsSep ", " names}" >&2
              return 1
          end

          set -l cmd $argv[1]
          set -l rest $argv[2..-1]

          switch $cmd
              case ${lib.concatStringsSep " " names}
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
      ${forEach sbCase}    end

          # Not exec: the launchers call this function and clear the agent state
          # after the agent exits.
          nono run $nono_args -- $cmd $cmd_args $rest
      end
    '';

    ".config/fish/completions/sb.fish".text = ''
      complete -c sb -f
    ''
    + forEach (
      name: agent: ''
        complete -c sb -n __fish_use_subcommand -a ${name} -d '${agent.description} (sandboxed)'
      ''
    );
  }
  // lib.mapAttrs' (
    name: agent:
    lib.nameValuePair ".config/nono/profiles/${name}.json" {
      source = json.generate "${name}.json" (profile name agent);
    }
  ) agents
  // lib.mapAttrs' (
    name: agent:
    lib.nameValuePair agent.rules {
      text = builtins.replaceStrings [ "@state@" ] [ agent.state ] (builtins.readFile ./files/agents-base.md);
    }
  ) agents;

  home.activation.mergeAgentSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${mergeSettings}
  '';
}
