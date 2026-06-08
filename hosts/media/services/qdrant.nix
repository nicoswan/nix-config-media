{ pkgs, lib, ... }:
{

  networking.firewall = {
    allowedTCPPorts = [
      6333
      6334
    ];
  };

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

  # Define static user and group to avoid systemd DynamicUser EBUSY rename errors on mount points
  users.users.qdrant = {
    isSystemUser = true;
    group = "qdrant";
  };
  users.groups.qdrant = { };

  systemd.services.qdrant.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "qdrant";
    Group = "qdrant";
  };

  systemd.services.create-qdrant-loopback = {
    description = "Create and format loopback image for Qdrant";
    requires = [ "mnt-ntfs_drive.mount" ];
    after = [ "mnt-ntfs_drive.mount" ];
    before = [ "var-lib-qdrant.mount" ];
    requiredBy = [ "var-lib-qdrant.mount" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "create-qdrant-loopback" ''
        img_dir="/mnt/ntfs_drive/home-lab/data/qdrant"
        img_file="$img_dir/qdrant-data.img"
        mkdir -p "$img_dir"
        if [ ! -f "$img_file" ]; then
          # Create a sparse 10GB file (takes no space until used, grows dynamically)
          truncate -s 10G "$img_file"
          # Format as ext4
          ${pkgs.e2fsprogs}/bin/mkfs.ext4 -F "$img_file"
        fi
      '';
    };
  };

  systemd.services.qdrant-prepare-mount = {
    description = "Set correct permissions on Qdrant loopback mount";
    requires = [ "var-lib-qdrant.mount" ];
    after = [ "var-lib-qdrant.mount" ];
    before = [ "qdrant.service" ];
    requiredBy = [ "qdrant.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "qdrant-prepare-mount" ''
        chown qdrant:qdrant /var/lib/qdrant
        chmod 750 /var/lib/qdrant
      '';
    };
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
