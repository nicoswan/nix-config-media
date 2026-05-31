{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.portal-relay;
in
{
  options.services.portal-relay = {
    enable = mkEnableOption "Portal relay server";

    port = mkOption {
      type = types.port;
      default = 9500;
      description = "Port to run the portal relay server on.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open the port in the firewall.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.portal-relay = {
      description = "Portal Relay and Rendezvous Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.portal}/bin/portal serve --port ${toString cfg.port}";
        Restart = "always";
        RestartSec = 5;
        DynamicUser = true;
        PrivateTmp = true;
        ProtectHome = true;
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };
}
