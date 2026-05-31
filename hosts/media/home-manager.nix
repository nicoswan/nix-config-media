{ cfg, ... }: {
  imports = [
    ../../base/home-manager
    ./users/${cfg.username}/home-manager.nix
    ../../base/home-manager/terminals/tmux.nix
  ];
}
