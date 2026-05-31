{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    ./networking.nix
    ./nfs-server.nix
    ./boot-loader.nix
    ./nix-settings.nix
    ./usb-optimizations.nix
  ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };
}
