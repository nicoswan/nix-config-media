# home-lab nix-config justfile
# Provides recipes for building, testing, deploying, and managing NixOS configurations.

set shell := ["bash", "-uc"]

SOPS_FILE := "../nix-secrets/hosts/media.yaml"
DEFAULT_HOST := "media"
DEFAULT_TARGET := "192.168.1.223"

# Display available recipes and help information
default:
    @just --list

# ==============================================================================
# Local Rebuild Recipes
# ==============================================================================

# Ensure flake files are tracked in git and secrets are synced
rebuild-pre: update-nix-secrets
    git add -N . || true

# Verify that sops-nix activated successfully in systemd journal
rebuild-post:
    scripts/check-sops.sh

# Rebuild and switch local system configuration (optionally specify HOST)
rebuild HOST="": rebuild-pre
    scripts/system-flake-rebuild.sh {{HOST}}

# Rebuild with full post-activation check (requires sops to be active)
rebuild-full HOST="": rebuild-pre && rebuild-post
    scripts/system-flake-rebuild.sh {{HOST}}

# Rebuild with detailed evaluation trace output
rebuild-trace HOST="": rebuild-pre
    scripts/system-flake-rebuild.sh {{HOST}} --show-trace

# Build and set as boot default without immediately switching
rebuild-boot HOST="": rebuild-pre
    HOST="${HOST:-$(hostname)}"; sudo nixos-rebuild boot --flake ".#${HOST}"

# Build and activate configuration temporarily (no bootloader update)
rebuild-test HOST="": rebuild-pre
    HOST="${HOST:-$(hostname)}"; sudo nixos-rebuild test --flake ".#${HOST}"

# Dry run build and activation
rebuild-dry HOST="": rebuild-pre
    HOST="${HOST:-$(hostname)}"; sudo nixos-rebuild dry-activate --flake ".#${HOST}"

# Update flake inputs and rebuild
rebuild-update HOST="": update
    just rebuild {{HOST}}

# ==============================================================================
# Remote Deployment Recipes
# ==============================================================================

# Deploy configuration to remote target (defaults to media / 192.168.1.223)
deploy HOST=DEFAULT_HOST TARGET=DEFAULT_TARGET: rebuild-pre
    nixos-rebuild switch --target-host nicoswan@{{TARGET}} --flake .#{{HOST}} --sudo

# Deploy with --show-trace for detailed error traces
deploy-trace HOST=DEFAULT_HOST TARGET=DEFAULT_TARGET: rebuild-pre
    nixos-rebuild switch --target-host nicoswan@{{TARGET}} --flake .#{{HOST}} --sudo --show-trace

# Deploy and set as boot default without immediately switching
deploy-boot HOST=DEFAULT_HOST TARGET=DEFAULT_TARGET: rebuild-pre
    nixos-rebuild boot --target-host nicoswan@{{TARGET}} --flake .#{{HOST}} --sudo

# Deploy and test without modifying the bootloader
deploy-test HOST=DEFAULT_HOST TARGET=DEFAULT_TARGET: rebuild-pre
    nixos-rebuild test --target-host nicoswan@{{TARGET}} --flake .#{{HOST}} --sudo

# ==============================================================================
# Flake & Secrets Maintenance
# ==============================================================================

# Update flake lockfile (optional: specify specific INPUT like nixpkgs)
update INPUT="":
    @if [ -n "{{INPUT}}" ]; then \
        nix flake update {{INPUT}}; \
    else \
        nix flake update; \
    fi

# Pull latest secrets from nix-secrets repo and update flake input
update-nix-secrets:
    @if [ -d "../nix-secrets" ]; then \
        (cd ../nix-secrets && git fetch && git rebase) || true; \
    fi
    nix flake update nix-secrets

# Format all Nix files using nix fmt (nixpkgs-fmt)
fmt:
    nix fmt .

# Show uncommitted git diff excluding flake.lock
diff:
    git diff ':!flake.lock'

# ── SOPS Secrets Management ───────────────────────────────────────────────────

# Edit secrets file
sops FILE=SOPS_FILE:
    @if [ -f "{{FILE}}" ]; then \
        echo "Editing {{FILE}}"; \
        nix-shell -p sops --run "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops {{FILE}}"; \
    elif [ -f "../nix-secrets/{{FILE}}" ]; then \
        echo "Editing ../nix-secrets/{{FILE}}"; \
        nix-shell -p sops --run "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops ../nix-secrets/{{FILE}}"; \
    else \
        echo "Secrets file {{FILE}} not found"; \
    fi

# Print decrypted secrets file
sops-print FILE=SOPS_FILE:
    @if [ -f "{{FILE}}" ]; then \
        nix-shell -p sops --run "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d {{FILE}}"; \
    elif [ -f "../nix-secrets/{{FILE}}" ]; then \
        nix-shell -p sops --run "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d ../nix-secrets/{{FILE}}"; \
    else \
        echo "Secrets file {{FILE}} not found"; \
    fi

# Rekey secrets
rekey FILE=SOPS_FILE:
    cd ../nix-secrets && (\
        sops updatekeys -y {{FILE}} && \
        git add -u && (git commit -m "chore: rekey" || true) && git push \
    )

# Verify sops secrets are accessible
check-sops:
    scripts/check-sops.sh

# ── Disko & Hardware Installation ─────────────────────────────────────────────

disko-install HOST DISK:
    sudo nix run .#disko-install -- \
        --flake .#{{HOST}} --disk main {{DISK}}

install-mmcblk0:
    just disko-install media /dev/mmcblk0
