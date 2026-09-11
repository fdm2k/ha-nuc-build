# 4. Cloudflare Tunnel (WAN access to Home Assistant)

This part is a manual, one-time dashboard step — Cloudflare doesn't expose tunnel/hostname creation via a script-friendly API without an account-scoped API token, and doing it in the dashboard is a five-minute job.

## Prerequisite

A domain added to a (free) Cloudflare account, with Cloudflare set as its DNS provider. If you don't already own a domain, register one and point its nameservers at Cloudflare during signup.

## Steps

1. Cloudflare dashboard → **Zero Trust → Networks → Tunnels → Create a tunnel**.
2. Choose **Cloudflared**, name it (e.g. `nuc-platform`).
3. On the "Install connector" step, copy the **token** shown (it's the long string after `--token` in the example command) — this is what goes in `docker/.env` as `CLOUDFLARE_TUNNEL_TOKEN`. You don't need to run the install command it shows; the Docker container in this repo's `docker-compose.yml` does that job.
4. **Public hostname** tab: add a hostname, e.g. `ha.yourdomain.com`, pointing at:
   - Service type: `HTTP`
   - URL: `127.0.0.1:8123`
5. Save. Bring the Docker stack up as described in `docs/02-docker-and-home-assistant.md`.
6. Once `cloudflared` container is running and connected (check with `docker compose logs cloudflared` — look for a "Registered tunnel connection" line), `https://ha.yourdomain.com` reaches Home Assistant from anywhere, no router configuration and no inbound ports opened on your home connection.

## What this does and doesn't expose

- No inbound firewall/port-forward rule is created on your router — `cloudflared` makes an outbound-only connection to Cloudflare's edge.
- SSH to the NUC is **not** part of this tunnel and stays LAN-only, as required.
- Authentication is entirely Home Assistant's own login — the tunnel just gets traffic to HA, it doesn't add a separate auth layer in front of it. If you want an extra layer (e.g. Cloudflare Access), that's an optional add-on, not part of this build.
