#!/usr/bin/env bash
# 01-base-os.sh — baseline packages, directory layout, GitHub deploy key.
# Run via: ssh <user>@<nuc> 'bash -s' < 01-base-os.sh   (or clone repo locally on the NUC and run directly)
set -euo pipefail

echo "== Updating base system =="
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y \
    curl git vim htop unzip ca-certificates gnupg lsb-release \
    software-properties-common cifs-utils rclone restic \
    intel-media-va-driver mesa-vulkan-drivers vainfo

echo "== Creating platform data layout =="
sudo mkdir -p /opt/platform-data/{homeassistant/config,emulation/roms,emulation/saves,emulation/states}
sudo chown -R "$USER":"$USER" /opt/platform-data

echo "== Timezone (edit if not Adelaide) =="
sudo timedatectl set-timezone Australia/Adelaide

echo "== GitHub deploy key (fdm2k) =="
KEY_PATH="$HOME/.ssh/id_ed25519_nuc_platform"
if [ ! -f "$KEY_PATH" ]; then
    ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "nuc-platform-deploy-key"
    echo ">> Public key below. Add it as a DEPLOY KEY (not account key) on the GitHub repo:"
    echo ">> Repo Settings > Deploy keys > Add deploy key > check 'Allow write access'"
    cat "$KEY_PATH.pub"
else
    echo ">> Deploy key already exists at $KEY_PATH — skipping generation."
fi

cat <<EOF >> "$HOME/.ssh/config"

Host github-nuc-platform
    HostName github.com
    User git
    IdentityFile $KEY_PATH
    IdentitiesOnly yes
EOF

echo "== Done. Clone the repo with: =="
echo "git clone git@github-nuc-platform:fdm2k/<repo-name>.git /opt/platform"
