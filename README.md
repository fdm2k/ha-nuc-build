# NUC Living Room Platform — Emulation + Home Assistant

### Single Intel NUC8i7BEH (i7-8559U, 64GB RAM, 256GB M.2 + 512GB 2.5" SSD) running:
- Family retro game emulation (RetroArch + ES-DE), HDMI-connected to the living room TV, Xbox Series X controllers over Bluetooth.
- Home Assistant (Docker container), reachable locally and over WAN via Cloudflare Tunnel.
- Dual backups: local NAS (CIFS/SMB) as primary, Dropbox as secondary/offsite.

Host OS: Ubuntu Server 24.04 LTS, bare metal, no hypervisor. GPU is the onboard Iris Plus 655 (no discrete GPU) — shared directly between processes via `/dev/dri`, not virtualization-style passthrough. See `docs/architecture.md` for the full logical view.

### Rebuild order

Run these in sequence via SSH against a clean NUC. Each script is idempotent — safe to re-run.

#### Script Does
1.	`scripts/01-base-os.sh`	OS hardening baseline, packages, `/opt/platform-data` layout
2.	`scripts/02-docker-install.sh`	Docker Engine + Compose plugin
3.	`scripts/03-home-assistant.sh`	HA Container + Cloudflare Tunnel via Docker Compose
4.	`scripts/04-xpadneo-bluetooth.sh`	Xbox Series X Bluetooth controller driver (onboard BT)
5.	`scripts/05-emulation-stack.sh`	RetroArch + ES-DE, kiosk autostart on HDMI
6.	`scripts/06-backup-restic.sh`	restic → NAS (CIFS) + restic → Dropbox (rclone), daily systemd timer

#### Full narrative docs:
Includes manual steps that can't be scripted (Cloudflare dashboard, GitHub deploy key, NAS/Dropbox credentials), are in `docs/`:
- `docs/00-hardware-reset.md` — start here if you don't have known-good access to the NUC (unknown BIOS state/password left over from its prior Nutanix AHV use, locked boot order, etc.). Skip straight to step 1 if you already have working BIOS/boot access.
- `docs/01-os-base-setup.md`
- `docs/02-docker-and-home-assistant.md`
- `docs/03-emulation-frontend.md`
- `docs/04-cloudflare-tunnel.md`
- `docs/05-backups.md`
- `docs/06-bluetooth-proxy-appendix.md` — optional, for BLE devices out of the living room's range
- `docs/architecture.md` — logical architecture view
- Secrets — never committed
- `docker/.env` and `scripts/secrets/` are git-ignored. They hold the Cloudflare Tunnel token, NAS CIFS credentials, rclone Dropbox token, and restic repository passwords. Every doc below tells you exactly what to put in them; nothing else in this repo needs editing to rebuild from scratch.

#### GitHub
Repo is change-controlled under the `fdm2k` GitHub account. Setup steps are in `docs/01-os-base-setup.md` (SSH deploy key generation and registration).
