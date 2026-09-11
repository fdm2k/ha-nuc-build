#!/usr/bin/env bash
# 04-xpadneo-bluetooth.sh — Xbox Series X controller Bluetooth support via onboard
# Intel Wireless-AC 9560 (Bluetooth 5.0). No 8BitDo adapter required.
# Source: https://github.com/atar-axis/xpadneo
set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y dkms linux-headers-$(uname -r) bluez git

if [ -d /usr/src/xpadneo* ] || dkms status 2>/dev/null | grep -q xpadneo; then
    echo ">> xpadneo already installed — skipping clone/install."
else
    TMP_DIR=$(mktemp -d)
    git clone --depth 1 https://github.com/atar-axis/xpadneo.git "$TMP_DIR/xpadneo"
    sudo "$TMP_DIR/xpadneo/install.sh"
    rm -rf "$TMP_DIR"
fi

sudo systemctl enable bluetooth
sudo systemctl restart bluetooth

cat <<'EOF'

== Pairing an Xbox Series X controller ==
1. Hold the Xbox button until it flashes, then hold the small pairing button on
   top until the Xbox button flashes rapidly.
2. On the NUC:
     bluetoothctl
     scan on
     # note the MAC address once it appears as "Xbox Wireless Controller"
     pair <MAC>
     trust <MAC>
     connect <MAC>
     exit
3. Controller will auto-reconnect on power-on from then on.
EOF
