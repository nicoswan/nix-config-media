{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./alacritty
    ./tmux.nix
  ];
}
