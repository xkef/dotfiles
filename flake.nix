{
  description = "xkef dotfiles: nix-darwin on macOS, home-manager on Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # television's channel files, pinned to the release nixpkgs packages.
    # Bump the tag together with the package.
    television = {
      url = "github:alexpasmantier/television/0.15.9";
      flake = false;
    };
  };

  # One configuration per platform. `dots switch` picks the one for the
  # machine it runs on.
  #
  #   darwinConfigurations.mac   macOS: system settings, Homebrew casks,
  #                              and home-manager
  #   homeConfigurations.<arch>  Arch, Lima guests, and any other Linux:
  #                              home-manager alone, for x86_64-linux or
  #                              aarch64-linux
  outputs =
    {
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      television,
      ...
    }:
    let
      settings = import ./nix/settings.nix;
      args = {
        inherit settings;
        tvCable = "${television}/cable/unix";
      };

      linux =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = args;
          modules = [
            ./nix/home.nix
            { home.homeDirectory = "/home/${settings.user}"; }
          ];
        };
    in
    {
      darwinConfigurations.mac = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit settings; };
        modules = [
          ./nix/darwin.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Moves a file that isn't a home-manager link aside instead of
            # failing, as on the first switch over a chezmoi install.
            home-manager.backupFileExtension = "hm-bak";
            home-manager.extraSpecialArgs = args;
            home-manager.users.${settings.user} = import ./nix/home.nix;
          }
        ];
      };

      homeConfigurations = {
        x86_64-linux = linux "x86_64-linux";
        aarch64-linux = linux "aarch64-linux";
      };

      # `nix fmt` formats the Nix files.
      formatter = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ] (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
