{
  description = "NixOS configuration for media server";

  inputs = {

    # NixOS
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable"; # also see 'unstable-packages' overlay at 'overlays/default.nix"

    # User packages
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management
    sops-nix.url = "github:mic92/sops-nix";

    # Declarative partitioning and formatting
    disko = {
      url = "git+https://github.com/nix-community/disko.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets
    nix-secrets = {
      url = "git+ssh://git@github.com/nico-swan-com/nix-secrets.git?ref=main&shallow=1";
      flake = false;
    };

    distro-grub-themes = {
      url = "github:AdisonCavani/distro-grub-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      # Systems that can run tests:
      supportedSystems = [ "x86_64-linux" ];

      # Function to generate a set based on supported systems:
      forAllSystems = inputs.nixpkgs.lib.genAttrs supportedSystems;

      # Media Server inline configuration arguments
      cfg = {
        hostname = "media";
        username = "nicoswan";
        fullname = "Nico Swan";
        email = "hi@nicoswan.com";
        locale = "en_ZA.UTF-8";
        timezone = "Africa/Johannesburg";
      };

      specialArgs = {
        inherit inputs cfg;
      };

      # Import custom overlays
      overlays = import ./overlays { inherit inputs; };

    in
    {
      inherit overlays;

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
        media = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          inherit specialArgs;
          modules = [
            # Apply our overlays globally
            {
              nixpkgs.overlays = [
                overlays.additions
                overlays.modifications
                overlays.unstable-packages
              ];
            }

            # System settings (Locale, Timezone, Nix settings)
            {
              i18n.defaultLocale = lib.mkDefault cfg.locale;
              time.timeZone = lib.mkDefault cfg.timezone;
              nixpkgs.config.allowUnfree = true;
              nix.settings = {
                experimental-features = "nix-command flakes";
                trusted-users = [
                  "root"
                  cfg.username
                ];
              };
            }

            # User account setup
            {
              users.users.${cfg.username} = {
                name = cfg.username;
                home = "/home/${cfg.username}";
                description = cfg.fullname;
              };
            }

            # Disko configuration
            inputs.disko.nixosModules.disko

            # Import host-specific NixOS configuration
            ./hosts/media/configuration.nix

            # Global/default modules
            inputs.distro-grub-themes.nixosModules.x86_64-linux.default

            # Home Manager configuration
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                extraSpecialArgs = specialArgs;
                users.${cfg.username} = import ./hosts/media/home-manager.nix {
                  inherit cfg;
                };
                sharedModules = [ ./modules/home-manager ];
              };
            }

            # Expose specialArgs so modules can parameterize
            { config._module.args = specialArgs; }
          ];
        };
      };
    };
}
