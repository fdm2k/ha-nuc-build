# 2. Docker and Home Assistant

## Steps

1. Install Docker:
   ```
   bash scripts/02-docker-install.sh
   ```
   Log out/in (or `newgrp docker`) so your user's docker group membership applies.

2. Complete the Cloudflare Tunnel setup in `docs/04-cloudflare-tunnel.md` first — you need the tunnel token before starting the stack.

3. Configure secrets:
   ```
   cp docker/.env.example docker/.env
   ```
   Edit `docker/.env` and set `CLOUDFLARE_TUNNEL_TOKEN` from the Cloudflare dashboard.

4. Bring the stack up:
   ```
   bash scripts/03-home-assistant.sh
   ```

5. Open `http://<nuc-lan-ip>:8123` on the LAN and complete HA's first-run onboarding (create your admin account — this is the one identity used for both local and remote access).

## Notes

- Home Assistant runs with `network_mode: host`, not a published port mapping. This is required for mDNS-based local discovery (Google Home devices finding HA on the local network for fast local control) to work — bridged Docker networking breaks that discovery.
- `cloudflared` also runs with `network_mode: host` for the same reason it needs to reach `127.0.0.1:8123` directly on the NUC, not the Docker bridge.
- Config lives at `/opt/platform-data/homeassistant/config` on the host, bind-mounted in — this is what gets backed up in step 6, and what you'd restore onto a freshly rebuilt NUC to recover your whole HA setup.
- Google Home voice control: set this up after HA is running, via **Settings → Devices & services → Google Assistant** integration in HA, following Home Assistant's current docs for the Google Home Developer Console flow (the old "Actions on Google" console is deprecated): https://www.home-assistant.io/integrations/google_assistant/
