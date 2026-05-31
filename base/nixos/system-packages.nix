{ pkgs, ... }:
{

  environment.systemPackages =
    with pkgs;
    [
      # Shell & System tools
      zsh
      zsh-history-substring-search
      vim
      sops
      just
      nil
      nix-output-monitor
      nixd
      nixpkgs-fmt
      nixfmt

      # Archives
      zip
      xz
      unzip
      p7zip

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
      ncdu
      rmlint
      rsync
      rclone
      fd
      wget
      duf
      cmatrix

      # Networking & Storage
      nfs-utils

      # Desktop (GNOME)
      gtop
      libgtop
      gparted
      gnome-extension-manager
      gnome-settings-daemon

      # Virtualisation & Containers
      dive
      podman-tui
      podman-desktop
      podman-compose
      qemu
      lima

      # Dev & Ops tools
      oci-cli
      termshark
      portal
      nixpacks
      gnumake
      gitlab-ci-ls
      minio-client
      gemini-cli

      # Read-aloud dependencies
      xclip
      piper-tts
      alsa-utils
      glib

      # GNOME Extensions
      gnomeExtensions.clipboard-history
      gnomeExtensions.compiz-windows-effect
      gnomeExtensions.desktop-cube

    ]
    # Unstable system packages
    ++ (with pkgs.unstable; [
      # Services
      onedrive
    ]);
}
