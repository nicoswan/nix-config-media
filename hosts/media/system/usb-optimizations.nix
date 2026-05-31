{ ... }: {
  # RAM-backed temporary directory to prevent writes to the USB drive
  boot.tmp.useTmpfs = true;

  # Store logs in RAM rather than continuously writing them to the USB drive
  services.journald.extraConfig = ''
    Storage=volatile
  '';

  # Enable zram compressed swap in memory instead of swap files on flash storage
  zramSwap.enable = true;
}
