{
  description = "Personal home-lab NixOS infrastructure";

  inputs = {
    # NixOS
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # User packages
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative partitioning and formatting
    disko = {
      url = "git+https://github.com/nix-community/disko.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management
    sops-nix.url = "github:mic92/sops-nix";

    # Secrets
    nix-secrets = {
      url = "git+file:///home/nicoswan/development/personal/home-lab/nix-secrets";
      flake = false;
    };

    distro-grub-themes = {
      url = "github:AdisonCavani/distro-grub-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rcw-crawler = {
      url = "git+ssh://git@gitlab.com/cygnus-labs/development/ai/cygnus-law/rcw-crawler.git?ref=main";
    };

    cygnus-monitor-probe = {
      url = "git+ssh://git@gitlab.com/cygnus-labs/development/platform/cygnus-monitor-probe.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , home-manager
    , ...
    }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;

      # Systems that can run tests:
      supportedSystems = [ "x86_64-linux" ];

      # Function to generate a set based on supported systems:
      forAllSystems = inputs.nixpkgs.lib.genAttrs supportedSystems;

      mkSystem = import ./lib/mkSystem.nix {
        inherit
          nixpkgs
          nixpkgs-unstable
          outputs
          inputs
          lib
          home-manager
          ;
      };

      # Common Configuration
      commonConfig = {
        username = "nicoswan";
        fullname = "Nico Swan";
        email = "hi@nicoswan.com";
        locale = "en_ZA.UTF-8";
        timezone = "Africa/Johannesburg";
      };

      x86_64-config = lib.recursiveUpdate commonConfig {
        system = "x86_64-linux";
        extraModules = [
          inputs.distro-grub-themes.nixosModules.x86_64-linux.default
        ];
      };

    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          customPkgs = import ./packages/default.nix { inherit pkgs; };
        in
        customPkgs
        // {
          disko-install = inputs.disko.packages.${system}.disko-install;
        }
      );

      # Nix formatter available through 'nix fmt'
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      # Shell configured with packages that are typically only needed when working on or with nix-config.
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./shell.nix { inherit pkgs; }
      );

      nixosConfigurations = {
        media = mkSystem "media" x86_64-config;
      };
    };
}
