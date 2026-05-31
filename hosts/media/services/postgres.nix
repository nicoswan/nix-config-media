{
  pkgs,
  cfg,
  ...
}:
let
  dataDir = "/mnt/ntfs_drive/home-lab/data/postgres/18";
in
{
  system.activationScripts.postgresData.text = ''
    mkdir -p ${dataDir}
    chown -R postgres ${dataDir}
  '';

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    enableTCPIP = true;
    dataDir = dataDir;
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
      host     all      all     0.0.0.0/0      md5
      # ipv6
      host     all      all     ::1/128        trust
      host     all      all     ::1/0          md5
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

  systemd.services.postgresql = {
    requires = [ "mnt-ntfs_drive.mount" ];
    after = [ "mnt-ntfs_drive.mount" ];
  };
}
