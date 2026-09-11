# 1. Base OS Setup

**Prerequisite (manual, one-time):** Install Ubuntu Server 24.04 LTS on the NUC from a USB installer (https://ubuntu.com/tutorials/create-a-usb-stick-on-ubuntu). During install: enable OpenSSH server, create your local admin user. This is the only step that can't be done remotely — everything after this point runs over SSH.

## Steps

1. SSH in: `ssh <your-user>@<nuc-lan-ip>`
2. Clone this repo (first time only — no deploy key yet, so clone with your personal GitHub credentials or HTTPS):
   ```
   git clone https://github.com/fdm2k/<repo-name>.git /opt/platform
   cd /opt/platform
   ```
3. Run the base script:
   ```
   bash scripts/01-base-os.sh
   ```
   This installs base packages, creates `/opt/platform-data` (all persistent application data lives here, kept separate from the git-tracked repo), sets timezone, and generates an SSH deploy key for GitHub.
4. Add the printed public key to the repo: **GitHub → repo → Settings → Deploy keys → Add deploy key → check "Allow write access"**. This scopes the NUC's push/pull access to this one repo only, not the whole `fdm2k` account.
5. From here on, `git pull`/`git push` from the NUC uses the deploy key automatically via the SSH config entry the script added.

## Why /opt/platform vs /opt/platform-data

`/opt/platform` is the git repo — code, docker-compose files, scripts. `/opt/platform-data` is real application state (HA config, save games, secrets) and is git-ignored. Keeping them separate means a `git pull` to update scripts never risks touching live data, and the backup job (step 6) only needs to know about one directory tree.
