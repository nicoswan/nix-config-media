{ pkgs, ... }: {

  # Install addition packages via home manager
  home.packages = with pkgs.unstable; [
    (writeShellScriptBin "tmux-cycle-windows"
      (builtins.readFile ../../../../scripts/tmux-cycle-windows.sh))
    (writeShellScriptBin "tmux-dashboard"
      (builtins.readFile ../../../../scripts/tmux-dashboard.sh))
    systemctl-tui
    lnav
    #lunarvim
  ];

  # home = {
  #   file.".kube/cygnus-labs-kubernetes-ca.pem".source = "${config.sops.secrets."ca.pem".path}";
  # };

}
