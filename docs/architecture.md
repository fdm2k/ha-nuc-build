# Logical Architecture

Single host, no hypervisor. The iGPU (Iris Plus 655) is shared by device node (`/dev/dri`), not virtualization passthrough — there's nothing to isolate since there's no discrete GPU.

```mermaid
flowchart TB
    subgraph Internet["Internet"]
        Family["Family devices\n(phones, laptops, off-site)"]
        GHome["Google Home speakers/displays\n(voice control)"]
        CFEdge["Cloudflare Edge\n(TLS termination, tunnel endpoint)"]
    end

    subgraph LAN["Home LAN"]
        Router["Home router\n(no inbound ports opened)"]
        NAS["NAS\n(CIFS/SMB share)"]
        ESP["ESPHome BT proxy device(s)\n(optional, remote BLE — see appendix)"]

        subgraph NUC["Intel NUC8i7BEH — Ubuntu Server 24.04 LTS"]
            direction TB

            subgraph Docker["Docker Compose stack"]
                HA["Home Assistant Container\n:8123"]
                CFT["cloudflared container\n(outbound-only tunnel agent)"]
            end

            subgraph HostProcs["Host processes (not containerised — need direct display/input/GPU)"]
                ESDE["ES-DE frontend + RetroArch cores\nkiosk session, autologin"]
            end

            XPADNEO["xpadneo driver\n(onboard Bluetooth 5.0)"]
            GPU["/dev/dri — Iris Plus 655\nshared, no passthrough needed"]
            Restic["restic + systemd timer\n(daily backup job)"]
            Data["/opt/platform-data\nHA config, RetroArch saves/states"]
        end

        TV["Living room TV\n(HDMI)"]
        Pad["Xbox Series X controllers\n(Bluetooth)"]
    end

    subgraph Dropbox["Dropbox (offsite)"]
        DBX["restic repo via rclone"]
    end

    Family -- "HTTPS, HA login (local users)" --> CFEdge
    CFEdge -- "outbound tunnel, no inbound port" --> CFT
    CFT --> HA
    GHome -- "Google Home Developer Console integration" --> HA
    Family -. "LAN-only" .-> HA
    Router -.-> NUC

    Pad -- "Bluetooth" --> XPADNEO --> ESDE
    ESDE --> GPU
    HA -.-> GPU
    ESDE --> TV
    ESP -- "WiFi, ESPHome API" --> HA

    Data --> Restic
    Restic -- "CIFS mount" --> NAS
    Restic -- "rclone" --> DBX
```

## Authentication and identity — where it sits

| Boundary | Mechanism | Notes |
|---|---|---|
| Family → Home Assistant (local or remote) | HA's own local user accounts | Single identity system for all access paths — remote access via Cloudflare Tunnel doesn't add a second login, it's the same HA auth screen |
| Remote reachability | Cloudflare Tunnel | Outbound-only from the NUC — no inbound firewall/router rule. Cloudflare terminates TLS at its edge, then proxies to the NUC over the tunnel. Cloudflare sees encrypted-in-transit traffic but is a party in the path (this trade-off was chosen deliberately over WireGuard for family UX — see prior discussion) |
| Google Home voice control | Google Home Developer Console (service account) ↔ HA `google_assistant` integration | No Nabu Casa dependency since self-hosted was preferred; this path replaced the deprecated "Actions on Google" console |
| GitHub | `fdm2k` account, SSH deploy key scoped to this repo only (not full-account key) | Generated on the NUC, private key never leaves it |
| NAS backup | CIFS credentials file, `chmod 600`, root-only, git-ignored | Not a shared identity with anything else |
| Dropbox backup | rclone OAuth token, git-ignored | Scoped to a single Dropbox App folder, not full-account access |
| Local admin | SSH, LAN-only, key-based | No WAN exposure — this was an explicit requirement |

## Containerisation layout

Only Home Assistant and the Cloudflare Tunnel agent are containerised (Docker Compose, one stack, private bridge network between the two containers). The emulation frontend runs directly on the host OS because it needs the display server, audio, and controller input paths that don't gain anything from containerisation here — the earlier "GPU passthrough" framing was virtualisation terminology; what's actually happening is both HA (rarely) and ES-DE/RetroArch (constantly) share the same `/dev/dri` device node on one shared OS.
