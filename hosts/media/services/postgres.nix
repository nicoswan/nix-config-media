{
  pkgs,
  cfg,
  ...
}:
{
  # Create a loopback filesystem image on the NTFS drive to support native POSIX permissions for PostgreSQL
  fileSystems."/var/lib/postgresql/18" = {
    device = "/mnt/ntfs_drive/home-lab/data/postgres/postgres-data.img";
    fsType = "ext4";
    options = [ "loop" "noatime" "nodiscard" ];
  };

  systemd.services.create-postgres-loopback = {
    description = "Create and format loopback image for PostgreSQL";
    requires = [ "mnt-ntfs_drive.mount" ];
    after = [ "mnt-ntfs_drive.mount" ];
    before = [ "var-lib-postgresql-18.mount" ];
    requiredBy = [ "var-lib-postgresql-18.mount" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "create-postgres-loopback" ''
        img_dir="/mnt/ntfs_drive/home-lab/data/postgres"
        img_file="$img_dir/postgres-data.img"
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

  systemd.services.postgresql-prepare-mount = {
    description = "Set correct permissions on PostgreSQL loopback mount";
    requires = [ "var-lib-postgresql-18.mount" ];
    after = [ "var-lib-postgresql-18.mount" ];
    before = [ "postgresql.service" ];
    requiredBy = [ "postgresql.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "postgresql-prepare-mount" ''
        chown postgres:postgres /var/lib/postgresql/18
        chmod 750 /var/lib/postgresql/18
        mkdir -p /var/lib/postgresql/18/data
        chown postgres:postgres /var/lib/postgresql/18/data
        chmod 700 /var/lib/postgresql/18/data
      '';
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    enableTCPIP = true;
    dataDir = "/var/lib/postgresql/18/data";
    settings = {
      port = 5432;
      listen_addresses = "*";

      # Memory optimization settings for a small footprint (development / laptop)
      max_connections = 20;
      shared_buffers = "32MB";
      work_mem = "2MB";
      maintenance_work_mem = "16MB";
      effective_cache_size = "128MB";
      huge_pages = "off";

      # Reduce background worker memory overhead
      max_worker_processes = 4;
      max_parallel_workers = 2;
      max_parallel_workers_per_gather = 1;

      # Reduce WAL memory buffer and size overhead
      wal_buffers = "1MB";
      min_wal_size = "80MB";
      max_wal_size = "512MB";
    };
    ensureDatabases = [ "${cfg.username}" ];
    ensureUsers = [
      {
        name = cfg.username;
        ensureDBOwnership = true;
        ensureClauses = {
          superuser = true;
          replication = true;
          login = true;
          createrole = true;
          createdb = true;
          bypassrls = true;
        };
      }
    ];
    extensions =
      ps: with ps; [
        pgvector # Vector similarity search. Only needed for local LLM/embedding/AI work.
      ];
    authentication = pkgs.lib.mkOverride 10 ''
      #type    database DBuser  origin-address auth-method
      local    all      all                    trust
      # ipv4
      host     all      all     127.0.0.1/32   trust
      host     all      all     192.168.1.0/24 md5
      # ipv6
      host     all      all     ::1/128        trust
    '';
    identMap = ''
      # ArbitraryMapName systemUser DBUser
      superuser_map      root                    postgres
      superuser_map      postgres                postgres
      superuser_map      ${cfg.username}         postgres
      # Let other names login as themselves
      superuser_map      /^(.*)$                 \1
    '';
  };
}
