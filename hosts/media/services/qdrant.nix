{

  # Create a loopback filesystem image on the NTFS drive to support native POSIX permissions for Qdrant
  fileSystems."/var/lib/qdrant" = {
    device = "/mnt/ntfs_drive/home-lab/data/qdrant/qdrant-data.img";
    fsType = "ext4";
    options = [
      "loop"
      "noatime"
      "nodiscard"
    ];
  };

  services.qdrant = {
    enable = true;
    settings = {
      service = {
        host = "0.0.0.0";
        http_port = 6333;
        grpc_port = 6334;
      };
      hsnw_index = {
        on_disk = true;
      };
      storage = {
        snapshots_path = "/var/lib/qdrant/snapshots";
        storage_path = "/var/lib/qdrant/storage";
      };
      telemetry_disabled = true;
    };
  };
}
