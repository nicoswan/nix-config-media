{ cfg, ... }: {
  imports = [
    ../../core/home-manager
    ./users/${cfg.username}/home-manager.nix
    ../../core/home-manager/terminals/tmux.nix
  ];
}
