{ pkgs, ... }:
{

  # Install addition packages via home manager
  home.packages = with pkgs.unstable; [
    systemctl-tui
    lnav
  ];
}
