{ pkgs, ... }:
{
  imports = [
    ./fail2ban.nix

    # Media services
    ./plex.nix
    ./sonarr.nix
    ./radarr.nix
    ./ombi.nix
    #./tautulli.nix
    ./qbittorrent.nix
    ./jackett.nix

    # Server services
    #./traefik.nix
    #./arion.nix
    ./portal.nix
    ./postgres.nix

    ./nginx-proxy.nix

  ];

  services.portal-relay.enable = true;

  users.groups.media.gid = 1001;
  users.users.media = {
    isNormalUser = true;
    group = "media";
    description = "Media user";
  };
}
