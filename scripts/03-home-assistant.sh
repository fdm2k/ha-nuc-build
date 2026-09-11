#!/usr/bin/env bash
# 03-home-assistant.sh — bring up Home Assistant + cloudflared via Docker Compose.
# Prerequisite: docker/.env populated (see docker/.env.example) and Cloudflare
# tunnel + public hostname already created in the Cloudflare Zero Trust dashboard
# (see docs/04-cloudflare-tunnel.md — that part is a manual, one-time UI step).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT/docker"

if [ ! -f .env ]; then
    echo "ERROR: docker/.env not found. Copy .env.example to .env and fill in CLOUDFLARE_TUNNEL_TOKEN first."
    exit 1
fi

echo "== Starting Home Assistant + Cloudflare Tunnel =="
docker compose up -d

echo "== Status =="
docker compose ps

echo ">> Local UI: http://<nuc-lan-ip>:8123"
echo ">> Remote UI: whatever public hostname you set in the Cloudflare dashboard"
