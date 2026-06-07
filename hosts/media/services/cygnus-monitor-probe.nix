{ inputs, ... }: {
  imports = [
    inputs.cygnus-monitor-probe.nixosModules.default
  ];

  services.cygnus-monitor-probe = {
    enable = true;

    # Option 1: Declarative configuration via Nix (recommended)
    settings = {
      git_enabled = false;
      hostname = "media";
      poll_interval_secs = 300;
      checks = {
        fail2ban = {
          enabled = true;
        };
        database = {
          enabled = true;
          services = [
            "postgresql"
          ];
        };
      };
    };

    # Option 2: Point directly to the legacy configuration file on the system
    # configFile = "/home/nicoswan/deploy/cygnus-monitor-probe/config.json";
  };
}
