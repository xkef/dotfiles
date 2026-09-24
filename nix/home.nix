# The user's environment on every machine. Each file under home/ becomes a
# symlink at the same path under $HOME, pointing into this checkout, so an
# edit applies at once and an app that rewrites its file, such as lazy.nvim's
# lockfile, writes back into the repo. A new or removed file needs
# `dots switch`.
#
# Nix generates the few files that depend on settings.nix or
# nix/agents.toml. Activation steps cover the rest: state that apps own, and
# secrets, which Nix never sees.
{
  config,
  lib,
  pkgs,
  settings,
  ...
}:
let
  dotfiles = "${config.home.homeDirectory}/${settings.dotfiles}";

  # Every file under home/, as a path relative to it.
  files =
    dir:
    lib.concatLists (
      lib.mapAttrsToList (
        name: type:
        let
          path = if dir == "" then name else "${dir}/${name}";
        in
        if type == "directory" then files path else [ path ]
      ) (builtins.readDir (if dir == "" then ../home else ../home + "/${dir}"))
    );
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/${path}";

  # Runs a step with the tools it needs and Homebrew's `op` on PATH.
  step =
    tools: script:
    pkgs.writeShellScript "dots-step" ''
      set -euo pipefail
      export PATH=${lib.makeBinPath tools}:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin
      ${script}
    '';
in
{
  imports = [ ./agents.nix ];

  home.username = settings.user;
  home.stateVersion = "25.11";
  home.packages = import ./packages.nix pkgs;

  home.file =
    lib.genAttrs (files "") (path: {
      source = link path;
    })
    // {
      ".config/fish/conf.d/dotfiles.fish".text = ''
        # ── Dotfiles directory ───────────────────────────────
        # Written by home-manager from nix/settings.nix, so dots, sb, and the
        # LazyVim <leader>fC picker all agree on the repo path.
        set -gx DOTFILES_DIR ${dotfiles}
      '';
    };

  home.activation = {
    gitIdentity = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${
        step [ pkgs.coreutils ] ''
          ${dotfiles}/home/.local/bin/git-identity \
            ${lib.escapeShellArgs [
              settings.identity.name
              settings.identity.email
              settings.identity.signingkey
            ]}
        ''
      }
    '';

    # mise installs the toolchains in ~/.config/mise/config.toml. It skips
    # the ones already installed. aqua has no maven-mvnd build for
    # linux/arm64.
    miseInstall = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${
        step [ pkgs.mise pkgs.git pkgs.coreutils ] ''
          cd ~
          if [ "$(uname -sm)" = "Linux aarch64" ]; then
            export MISE_DISABLE_TOOLS=mvnd
          fi
          mise trust ~/.config/mise/config.toml 2>/dev/null || true
          mise install
        ''
      }
    '';

    # The first switch downloads the vale style packages and tinty's
    # templates and applies the default scheme. `dots update` refreshes
    # them later.
    valeSync = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${
        step [ pkgs.vale pkgs.coreutils ] ''
          test -d ~/.config/vale/styles/Google ||
            vale --config ~/.config/vale/.vale.ini sync
        ''
      }
    '';
    tintyInit = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${
        step [ pkgs.tinty pkgs.git pkgs.fish pkgs.coreutils ] ''
          test -d ~/.local/share/tinted-theming/tinty/repos || tinty sync
          tinty init
        ''
      }
    '';
  }
  // lib.optionalAttrs pkgs.stdenv.isDarwin {
    screenshots = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run mkdir -p ~/Pictures/Screenshots
    '';
  };
}
