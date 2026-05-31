# Nico Swan NixOS Configuration

A fully declarative, single-host NixOS and Home Manager configuration for my personal laptop (`dell-laptop`).

## Overview

This repository has been streamlined from a complex multi-host configuration into a clean, maintainable setup tailored specifically for a single developer machine.

### Key Features
* **OS**: [NixOS](https://nixos.org/)
* **Desktop Environment**: GNOME (Wayland)
* **User Environment**: [Home Manager](https://github.com/nix-community/home-manager)
* **Secrets Management**: [sops-nix](https://github.com/Mic92/sops-nix) integrated with an external private `nix-secrets` repository
* **Task Runner**: `just` for simplified commands and rebuilds
* **Development**: Customized Neovim (via LazyVim), robust shell utilities (Zsh/Tmux), and container tools (Podman).

## Repository Structure

```
├── base/
│   ├── home-manager/   # Shared user configurations (terminals, git, fonts)
│   └── nixos/          # Shared system configurations (system packages, users)
├── hosts/
│   └── dell-laptop/    # Machine-specific configuration
│       ├── configuration.nix   # Hardware & boot configurations
│       ├── system/             # Networking, mounts, & GUI setup
│       ├── services/           # Systemd services (Postgres, Podman)
│       └── users/nicoswan/     # Home Manager user configurations and packages
├── scripts/            # Helper scripts (tmux session management, rebuilding)
├── flake.nix           # Entrypoint and inputs definition
└── justfile            # Command runner tasks
```

## Usage & Commands

This repository uses [`just`](https://github.com/casey/just) to manage common tasks securely.

* `just rebuild` - Rebuilds the system configuration using `nixos-rebuild switch`.
* `just update` - Updates the flake locks.
* `just rebuild-update` - Updates inputs and performs a system rebuild.
* `just sops` - Opens the encrypted secrets file for editing.
* `just nixgc` - Collects garbage from the Nix store to free up space.
* `just nixos-clean` - Performs a deep clean of the NixOS store and channels.
* `just --list` - See all available commands.

## Secrets Management

Secrets are managed using `sops-nix` and `age` encryption. 
* Age keys should be stored at `~/.config/sops/age/keys.txt`.
* Encrypted variables are pulled from the private `nix-secrets` repository input defined in `flake.nix`.