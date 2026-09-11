#!/usr/bin/env bash
# 05-emulation-stack.sh — RetroArch (NES/SNES/Genesis/N64/Arcade/Neo Geo/PS1 cores),
# PCSX2 + Dolphin (PS2/Wii/GameCube — best-effort on Iris Plus 655), ES-DE frontend,
# minimal X11 kiosk session auto-starting on the HDMI output.
set -euo pipefail

echo "== X11 + minimal window manager (no full desktop environment) =="
sudo apt-get update -y
sudo apt-get install -y xserver-xorg xinit openbox flatpak

echo "== Flathub remote =="
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "== ES-DE frontend (https://es-de.org) =="
sudo flatpak install -y --noninteractive flathub org.es_de.emulationstation-de

echo "== PCSX2 (PS2 — best-effort on integrated graphics) https://flathub.org/apps/net.pcsx2.PCSX2 =="
sudo flatpak install -y --noninteractive flathub net.pcsx2.PCSX2

echo "== Dolphin (GameCube/Wii — best-effort on integrated graphics) https://flathub.org/apps/org.DolphinEmu.dolphin-emu =="
sudo flatpak install -y --noninteractive flathub org.DolphinEmu.dolphin-emu

echo "== RetroArch + cores (NES, SNES, Genesis, N64, Arcade, Neo Geo, PS1) — libretro PPA =="
sudo add-apt-repository -y ppa:libretro/stable
sudo apt-get update -y
sudo apt-get install -y retroarch \
    libretro-fceumm \
    libretro-snes9x \
    libretro-genesis-plus-gx \
    libretro-mupen64plus \
    libretro-fbneo \
    libretro-beetle-psx

echo "== ROM/save directories (already created by 01-base-os.sh) =="
echo "   Point RetroArch/ES-DE content directories at:"
echo "   /opt/platform-data/emulation/roms"
echo "   /opt/platform-data/emulation/saves"
echo "   /opt/platform-data/emulation/states"
echo "   (Do this once inside ES-DE/RetroArch's own settings UI — not scriptable safely,"
echo "   as it depends on which systems you actually load ROMs for.)"

echo "== Kiosk autostart on tty1 =="
CURRENT_USER="$USER"

sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${CURRENT_USER} --noclear %I \$TERM
EOF

mkdir -p "$HOME/.config/openbox"
cat > "$HOME/.config/openbox/autostart" <<'EOF'
xset -dpms
xset s off
flatpak run org.es_de.emulationstation-de &
EOF

# Only start X automatically when logged in on tty1 (avoids clashing with SSH sessions)
if ! grep -q "startx" "$HOME/.bash_profile" 2>/dev/null; then
cat >> "$HOME/.bash_profile" <<'EOF'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx -- -nocursor
fi
EOF
fi

if [ ! -f "$HOME/.xinitrc" ]; then
    echo "exec openbox-session" > "$HOME/.xinitrc"
fi

sudo systemctl daemon-reload

echo ">> Reboot to land straight in ES-DE on the TV. Ctrl+Alt+F2 for a local admin TTY at any time."
