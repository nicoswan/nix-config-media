{ nixpkgs, nixpkgs-unstable, inputs, outputs, lib, home-manager, ... }:
name:
{ system
, username
, fullname
, email
, locale
, timezone
, extraModules ? [ ]
, useStable ? false
, sharedHMModules ? [ ]
, isMinimal ? false
}:

let
  inherit (nixpkgs) lib;
  cfg = {
    hostname = name;
    username = username;
    fullname = fullname;
    email = email;
    locale = locale;
    timezone = timezone;
    isMinimal = isMinimal;
    useStable = useStable;
  };

  configLib = import ../lib { inherit lib; };

  overlays = import ../overlays { inherit inputs outputs; };

  # The config files for this system.
  configuration = ../hosts/${name}/configuration.nix;
  homeManagerConfig = ../hosts/${name}/home-manager.nix;

  systemFunc = nixpkgs.lib.nixosSystem;
  homeManagerModules = inputs.home-manager.nixosModules;
  userHomeDirectory = "/home/${username}";

  specialArgs = {
    inherit nixpkgs inputs outputs cfg configLib nixpkgs-unstable;
  };

in
systemFunc rec {
  inherit specialArgs;
  inherit system;
  modules = [
    { nixpkgs.hostPlatform = system; }
    # Apply our overlays globally
    {
      nixpkgs.overlays = [
        overlays.additions
        overlays.modifications
        overlays.unstable-packages
      ];
    }

    {
      i18n.defaultLocale = lib.mkDefault locale;
      time.timeZone = lib.mkDefault timezone;
    }
    {
      nixpkgs.config.allowUnfree = true;
      nix = {
        settings = {
          experimental-features = "nix-command flakes";
          auto-optimise-store = true;
          trusted-users = [ "root" "${cfg.username}" ];
          substituters = [
            "https://cache.nixos.org"
            "https://law.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "law.cachix.org-1:ooSOR+DxWjRJehE4+q/j8rYecitsUolCYtXU/lKV/rA="
          ];
        };
      };
    }
    {
      # Users
      users.users."${username}" = {
        name = "${username}";
        home = userHomeDirectory;
        description = "${fullname}";
      };
    }
    inputs.disko.nixosModules.disko
    configuration
    homeManagerModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        extraSpecialArgs = specialArgs;
        users.${username} = import homeManagerConfig {
          inherit cfg;
          pkgs = nixpkgs;
          inputs = inputs;
        };
        sharedModules = [ ../modules/home-manager ] ++ sharedHMModules;
      };
    }
    # Expose extra arguments for modules
    { config._module.args = specialArgs; }
  ] ++ extraModules;
}
