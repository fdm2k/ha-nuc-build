# 5. Backups

Two independent restic repositories, same data, same retention policy (7 daily / 4 weekly / 6 monthly), run back-to-back once a day:

- **Primary** — local NAS, mounted over CIFS/SMB.
- **Secondary/offsite** — Dropbox, via restic's [rclone backend](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#other-services-via-rclone).

What's covered: Home Assistant config (`/opt/platform-data/homeassistant/config`) and emulation save games/states (`/opt/platform-data/emulation/saves`, `/opt/platform-data/emulation/states`). ROMs are deliberately excluded — large, static, and not something you'd typically need versioned backups of; add them to the source list in the generated `/usr/local/bin/nuc-platform-backup.sh` if you want that too.

## Steps

1. Create `/opt/platform-data/secrets/nas-credentials` manually (this is intentionally not scripted — it's a secret):
   ```
   sudo mkdir -p /opt/platform-data/secrets
   sudo nano /opt/platform-data/secrets/nas-credentials
   ```
   Contents:
   ```
   username=<nas-user>
   password=<nas-password>
   domain=<workgroup-if-applicable>
   ```
2. Add the CIFS mount to `/etc/fstab` (server/share is site-specific, so this is manual):
   ```
   //<nas-ip-or-hostname>/<share-name> /mnt/nas-backup cifs credentials=/opt/platform-data/secrets/nas-credentials,uid=<your-user>,iocharset=utf8 0 0
   ```
3. Authenticate rclone to Dropbox (interactive, needs a browser once):
   ```
   rclone config
   ```
   Create a remote named exactly `dropbox`, type `dropbox`. Docs: https://rclone.org/dropbox/
4. Run the setup script:
   ```
   bash scripts/06-backup-restic.sh
   ```
   This mounts the NAS share, initialises both restic repositories, generates a random password per repository, and installs a systemd timer that runs daily at 03:30.

## The one thing you must not lose

`/opt/platform-data/secrets/restic-password-nas` and `restic-password-dropbox` — without these, the backups are permanently unreadable, by design (restic encrypts everything). Copy these two files somewhere outside this whole system (password manager, printed and filed, etc.) the moment they're generated.

## Restoring onto a rebuilt NUC

```
restic -r /mnt/nas-backup/restic-nuc-platform --password-file <path-to-saved-password> restore latest --target /opt/platform-data
```
(or the `rclone:dropbox:restic-nuc-platform` repo, same command, if the NAS isn't available) — do this after `01-base-os.sh` has created the directory structure but before starting the Docker stack, so Home Assistant comes up with your restored config on first launch.
