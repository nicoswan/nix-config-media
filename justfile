SOPS_FILE := "../nix-secrets/secrets.yaml"

# default recipe to display help information
default:
  @just --list

# Update nix-secrets from remote before rebuilding
rebuild-pre: update-nix-secrets
  git add *.nix

# Check sops after rebuild
rebuild-post:
  just check-sops

# Rebuild the system using the hostname as the target
rebuild: rebuild-pre
  scripts/system-flake-rebuild.sh

# Rebuild with trace output
rebuild-trace: rebuild-pre
  scripts/system-flake-rebuild-trace.sh

# Update flake locks
update:
  nix flake update

# Update inputs and rebuild
rebuild-update: update rebuild

# View diff of changed files
diff:
  git diff ':!flake.lock'

# ── SOPS Secrets Management ───────────────────────────────────────────────────

# Edit secrets file
sops:
  echo "Editing {{SOPS_FILE}}"
  nix-shell -p sops --run "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops {{SOPS_FILE}}"

# Print secrets file
sops-print:
  echo "Editing {{SOPS_FILE}}"
  nix-shell -p sops --run "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d{{SOPS_FILE}}"  

# Generate a new age key
age-key:
  nix-shell -p age --run "age-keygen"

# Rekey all secrets (run after adding a new host/user key)
rekey:
  cd ../nix-secrets && (\
    sops updatekeys -y secrets.yaml && \
    (pre-commit run --all-files || true) && \
    git add -u && (git commit -m "chore: rekey" || true) && git push \
  )

# Verify sops secrets are accessible
check-sops:
  scripts/check-sops.sh

# Pull latest secrets
update-nix-secrets:
  (cd ../nix-secrets && git fetch && git rebase) || true
  nix flake update nix-secrets

# ── Maintenance ───────────────────────────────────────────────────────────────

# Collect garbage
nixgc:
  nix-collect-garbage -d

# Deep clean NixOS store and channels
nixos-clean:
  nix-channel --update 
  nix-env -u --always 
  sudo rm -rf /nix/var/nix/gcroots/auto/* 
  sudo nix-collect-garbage -d 

# Rebuild media server remotely via nixos-rebuild
rebuild-media-remote: rebuild-pre
  nixos-rebuild switch --target-host nicoswan@192.168.1.223 --flake .#media --sudo --ask-sudo-password

# Rebuild media server remotely via nixos-installer
rebuild-media: rebuild-pre
  nixos-installer rebuild -v \
      --host 192.168.1.223 \
      --user nicoswan \
      --flake-path /home/nicoswan/development/home-lab/nix-config-media \
      --flake-host media \
      --action switch \
      --yes

disko-install HOST DISK:
  sudo nix run .#disko-install -- \
    --flake .#{{HOST}} --disk main {{DISK}}

disko-install-media: 
  just disko-install media /dev/mmcblk0