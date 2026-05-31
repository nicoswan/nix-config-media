{ pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    # Shell & System tools
    zsh
    zsh-history-substring-search
    vim
    sops
    just

    # Archives
    zip
    unzip

    # CLI Utilities
    ripgrep
    jq
    yq-go
    eza
    fzf
    bat
    tldr
    dust
    btop
    lsof
    sshs
    tree
    fswatch
    git-extras
    rsync
    rclone
    fd
    wget
    duf
    cmatrix

    # Networking & Storage
    nfs-utils

    # Virtualisation & Containers
    dive
    podman-tui
    podman-compose

    # Dev & Ops tools
    portal

  ];
}
