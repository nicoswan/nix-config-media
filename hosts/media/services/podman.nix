{ config, pkgs, ... }:
{
  virtualisation = {
    podman = {
      enable = true;
      autoPrune = {
        enable = true;
        flags = [ ];
        dates = "weekly";
      };

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers.backend = "podman";
  };
  # Enable container name DNS for non-default Podman networks.
  # https://github.com/NixOS/nixpkgs/issues/226365
  networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

}
