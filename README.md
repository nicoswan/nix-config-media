# Nico Swan NixOS Media Server Configuration

A fully declarative, single-host NixOS and Home Manager configuration for my home media server (`media`).

## Overview

This repository is structured as a standalone, clean, and maintainable setup tailored specifically for a home media and storage server.

### Key Features
* **OS**: [NixOS](https://nixos.org/)
* **Media Services**: Plex, Sonarr, Radarr, Ombi, Qbittorrent, Jackett, Transmission, and Nginx reverse proxy with ACME TLS certificates
* **Storage**: NFS server exports, bind mounts, and [Disko](https://github.com/nix-community/disko) declarative partitioning
* **User Environment**: [Home Manager](https://github.com/nix-community/home-manager)
* **Secrets Management**: [sops-nix](https://github.com/Mic92/sops-nix) integrated with an external private `nix-secrets` repository
* **Security**: Fail2ban intrusion prevention
* **Task Runner**: `just` for simplified commands, remote updates, and builds

## Media Services & Configurations

The media server hosts a complete self-hosted media acquisition, streaming, and file-sharing suite:

### 🎬 Application Suite
The applications are deployed as system services, bound to `127.0.0.1`, and exposed securely via an Nginx reverse proxy with TLS certificates from Cloudflare DNS (ACME):

| Service | Address / Port | Local Port | Proxy Subdomain | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Plex** | `http://127.0.0.1:32400` | `32400` | `plex.home.nicoswan.com` | Active |
| **Sonarr** | `http://127.0.0.1:8989` | `8989` | `sonarr.home.nicoswan.com` | Active |
| **Radarr** | `http://127.0.0.1:7878` | `7878` | `radarr.home.nicoswan.com` | Active |
| **Ombi** | `http://127.0.0.1:5000` | `5000` | `ombi.home.nicoswan.com` | Active |
| **Qbittorrent** | `http://127.0.0.1:9010` | `9010` | `qbittorrent.home.nicoswan.com` | Active |
| **Jackett** | `http://127.0.0.1:9117` | `9117` | `jackett.home.nicoswan.com` | Active |
| **Tautulli** | `http://127.0.0.1:8181` | `8181` | `tautulli.home.nicoswan.com` | Inactive |
| **Homepage Dashboard** | `http://127.0.0.1:9888` | `9888` | `homepage.home.nicoswan.com` | Inactive |
| **Transmission** | `http://127.0.0.1:9091` | `9091` | *N/A* (Direct port access) | Inactive |
| **Traefik** | `http://127.0.0.1:8080` | `8080` | *N/A* (Admin dashboard) | Inactive |
| **Portal Relay** | `http://127.0.0.1:9500` | `9500` | *N/A* (Direct port access) | Active |

> [!NOTE]
> All services run under a dedicated system user/group `media` (GID/UID `1001`) with symlinked local storage paths pointing directly to `/mnt/media_storage/Media/`.

---

### 💾 Storage & Exports

#### Disks & Mounts (`system/disks.nix`)
* **/mnt/media_storage**: NTFS drive mounted from `/dev/disk/by-label/media` for primary media content.
* **/mnt/ntfs_drive**: NTFS drive mounted from `/dev/disk/by-label/backup` for backups and other documents.
* **System Drive**: Declaratively partitioned via Disko (`/dev/sdc` by default, containing a `vfat` `/boot` ESP and an `ext4` `/` partition).

#### NFS Server (`system/nfs-server.nix`)
The server exports storage pools to local subnets (`192.168.1.0/24`) and allowed public IPs:
* `/export/media` (bind mount of `/mnt/export/media`)
* `/export/media-storage` (bind mount of `/mnt/media-storage`)
* `/export/ntfs_drive` (bind mount of `/mnt/ntfs_drive`)
* `/export/wetink/pretoria` & `/export/wetink/capetown`

## Repository Structure

```
├── base/
│   ├── home-manager/   # Shared user configurations (git, terminals, tmux)
│   └── nixos/          # Shared system configurations (system packages, users)
├── hosts/
│   └── media/          # Media server specific configurations
│       ├── configuration.nix   # Host entrypoint configuration
│       ├── home-manager.nix    # Host Home Manager configuration
│       ├── sops.nix            # SOPS-nix configuration
│       ├── system/             # Networking, Disko, NFS server, and hardware configs
│       ├── services/           # Media application suites & server services
│       │   ├── default.nix            # Imports active services
│       │   ├── fail2ban.nix           # Security & intrusion prevention
│       │   ├── homepage-dashboard.nix # Homepage Dashboard container
│       │   ├── jackett.nix            # Jackett torrent indexer
│       │   ├── nginx-proxy.nix        # Nginx reverse proxy & ACME/Cloudflare SSL
│       │   ├── ombi.nix               # Ombi requests manager
│       │   ├── plex.nix               # Plex Media Server
│       │   ├── portal.nix             # Portal relay and rendezvous server
│       │   ├── postgres.nix           # PostgreSQL database server
│       │   ├── qbittorrent.nix        # qBittorrent client
│       │   ├── radarr.nix             # Radarr movie manager
│       │   ├── sonarr.nix             # Sonarr TV show manager
│       │   ├── tautulli.nix           # Tautulli plex monitor
│       │   ├── traefik.nix            # Traefik load balancer (inactive)
│       │   └── transmission.nix       # Transmission torrent client (inactive)
│       └── users/nicoswan/     # Home Manager user configurations and packages
├── scripts/            # Rebuild and tmux dashboard scripts
├── flake.nix           # Entrypoint and inputs definition
└── justfile            # Command runner tasks
```

## Usage & Commands

This repository uses [`just`](https://github.com/casey/just) to manage system tasks:

### Local and Remote Rebuilds
* `just rebuild` - Rebuilds the system configuration locally.
* `just rebuild-media-remote` - Rebuilds the media server remotely using `nixos-rebuild` targeting `192.168.1.223`.
* `just rebuild-media` - Rebuilds the media server remotely using `nixos-installer` targeting `192.168.1.223`.

### Installation
* `just install-mmcblk0` - Performs a declarative Disko installation of the media server to `/dev/mmcblk0`.
* `just disko-install HOST DISK` - Installs NixOS on a target disk using a local `disko-install` flake wrapper.

### Secrets and Maintenance
* `just sops` - Opens the encrypted secrets file for editing.
* `just nixgc` - Collects garbage from the Nix store to free up space.
* `just nixos-clean` - Performs a deep clean of the NixOS store and channels.
* `just --list` - See all available commands.

## Secrets Management

Secrets are managed using `sops-nix` and `age` encryption. 
* Age keys should be stored at `~/.config/sops/age/keys.txt`.
* Encrypted variables are pulled from the private `nix-secrets` repository input defined in `flake.nix`.