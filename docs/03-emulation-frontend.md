# 3. Emulation Frontend

## Steps

1. Pair your Xbox Series X controller(s) over the NUC's onboard Bluetooth:
   ```
   bash scripts/04-xpadneo-bluetooth.sh
   ```
   Follow the pairing instructions it prints.

2. Install the emulation stack and kiosk autostart:
   ```
   bash scripts/05-emulation-stack.sh
   ```

3. Copy ROMs onto the NUC into `/opt/platform-data/emulation/roms/<system>/` (e.g. `.../roms/nes/`, `.../roms/genesis/`) — `scp` or a network share both work. **You are responsible for the legality of ROM sourcing in your jurisdiction; this build doesn't provide or link to ROMs.**

4. Reboot. The NUC will autologin on the local console and launch ES-DE fullscreen on the TV.

5. Inside ES-DE (first boot), point it at `/opt/platform-data/emulation/roms` as the ROM directory and let it scan — this is a one-time in-app step, not scriptable safely since it depends on exactly which systems you've populated.

## System coverage and expectations

| System | Engine | Expectation |
|---|---|---|
| NES | RetroArch (fceumm) | Full speed, no issues |
| SNES/Famicom | RetroArch (snes9x) | Full speed, no issues |
| Genesis/Mega Drive | RetroArch (genesis_plus_gx) | Full speed, no issues |
| N64 | RetroArch (mupen64plus) | Generally solid, a handful of demanding titles may need tuning |
| Arcade | RetroArch (FBNeo) | Full speed, no issues |
| Neo Geo | RetroArch (FBNeo) | Full speed, no issues |
| PS1 | RetroArch (Beetle PSX) | Full speed, no issues |
| PS2 | Standalone PCSX2 (Flatpak) | Best-effort — Iris Plus 655 has no discrete GPU; expect some titles to underperform. Test your actual library once running. |
| GameCube/Wii | Standalone Dolphin (Flatpak) | Best-effort, same caveat as PS2 |

## Getting out of the kiosk

`Ctrl+Alt+F2` drops to a local text console for admin work (SSH remains available regardless). `Alt+F4` or ES-DE's own quit option exits back to a shell on tty1.
