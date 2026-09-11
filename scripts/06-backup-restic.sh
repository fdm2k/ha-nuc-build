#!/usr/bin/env bash
# 06-backup-restic.sh — sets up two independent restic repositories:
#   1. Primary  — local NAS over CIFS/SMB
#   2. Secondary — Dropbox, via restic's rclone backend
# Backs up: /opt/platform-data/homeassistant/config
#           /opt/platform-data/emulation/saves
#           /opt/platform-data/emulation/states
# (ROMs are intentionally excluded — large, static, and re-obtainable; back them
#  up separately/manually if you want that covered too.)
set -euo pipefail

SECRETS_DIR="/opt/platform-data/secrets"
sudo mkdir -p "$SECRETS_DIR"
sudo chmod 700 "$SECRETS_DIR"

echo "== 1. NAS CIFS mount =="
sudo mkdir -p /mnt/nas-backup
if [ ! -f "$SECRETS_DIR/nas-credentials" ]; then
    echo ">> Create $SECRETS_DIR/nas-credentials manually (chmod 600, root-owned) containing:"
    echo "   username=<nas-user>"
    echo "   password=<nas-password>"
    echo "   domain=<workgroup-or-domain, if applicable>"
    echo ">> Then re-run this script."
    exit 1
fi
sudo chmod 600 "$SECRETS_DIR/nas-credentials"

if ! grep -q "/mnt/nas-backup" /etc/fstab; then
    echo ">> Edit /etc/fstab manually — server/share path is site-specific. Example line:"
    echo "//<nas-ip-or-hostname>/<share-name> /mnt/nas-backup cifs credentials=$SECRETS_DIR/nas-credentials,uid=$USER,iocharset=utf8 0 0"
fi
sudo mount -a || echo ">> Mount not active yet — add the /etc/fstab line above and re-run."

echo "== 2. rclone Dropbox remote =="
if ! rclone listremotes | grep -q "^dropbox:"; then
    echo ">> Run interactively once (needs browser auth): rclone config"
    echo "   Create a remote named exactly 'dropbox', type 'dropbox'."
    echo "   Docs: https://rclone.org/dropbox/"
    exit 1
fi

echo "== 3. restic repo passwords =="
for repo in nas dropbox; do
    PW_FILE="$SECRETS_DIR/restic-password-$repo"
    if [ ! -f "$PW_FILE" ]; then
        openssl rand -base64 32 > "$PW_FILE"
        chmod 600 "$PW_FILE"
        echo ">> Generated $PW_FILE — back this up separately (outside this repo/NAS/Dropbox) or you cannot restore."
    fi
done

RESTIC_NAS_REPO="/mnt/nas-backup/restic-nuc-platform"
RESTIC_DBX_REPO="rclone:dropbox:restic-nuc-platform"

restic -r "$RESTIC_NAS_REPO" --password-file "$SECRETS_DIR/restic-password-nas" snapshots &>/dev/null \
    || restic -r "$RESTIC_NAS_REPO" --password-file "$SECRETS_DIR/restic-password-nas" init
restic -r "$RESTIC_DBX_REPO" --password-file "$SECRETS_DIR/restic-password-dropbox" snapshots &>/dev/null \
    || restic -r "$RESTIC_DBX_REPO" --password-file "$SECRETS_DIR/restic-password-dropbox" init

echo "== 4. Backup script + systemd timer =="
sudo tee /usr/local/bin/nuc-platform-backup.sh > /dev/null <<EOF
#!/usr/bin/env bash
set -euo pipefail
SOURCE="/opt/platform-data/homeassistant/config /opt/platform-data/emulation/saves /opt/platform-data/emulation/states"
restic -r "$RESTIC_NAS_REPO" --password-file "$SECRETS_DIR/restic-password-nas" backup \$SOURCE
restic -r "$RESTIC_NAS_REPO" --password-file "$SECRETS_DIR/restic-password-nas" forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
restic -r "$RESTIC_DBX_REPO" --password-file "$SECRETS_DIR/restic-password-dropbox" backup \$SOURCE
restic -r "$RESTIC_DBX_REPO" --password-file "$SECRETS_DIR/restic-password-dropbox" forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
EOF
sudo chmod 700 /usr/local/bin/nuc-platform-backup.sh

sudo tee /etc/systemd/system/nuc-platform-backup.service > /dev/null <<'EOF'
[Unit]
Description=NUC platform backup (HA config + emulation saves) to NAS and Dropbox

[Service]
Type=oneshot
ExecStart=/usr/local/bin/nuc-platform-backup.sh
EOF

sudo tee /etc/systemd/system/nuc-platform-backup.timer > /dev/null <<'EOF'
[Unit]
Description=Daily NUC platform backup

[Timer]
OnCalendar=03:30
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now nuc-platform-backup.timer

echo ">> Backup configured. Check status any time with: systemctl list-timers nuc-platform-backup.timer"
echo ">> Test a manual run with: sudo /usr/local/bin/nuc-platform-backup.sh"
