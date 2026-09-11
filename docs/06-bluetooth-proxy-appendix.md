# 6. Appendix: ESPHome Bluetooth Proxy (for BLE devices out of the NUC's range)

Optional, separate from the core NUC build — solves the "NUC is in the living room, some BLE devices aren't" problem. Home Assistant/ESPHome maintain official, tested proxy device configs: https://github.com/esphome/bluetooth-proxies

## What it is

A cheap ESP32 board (~AU$10-15 — an M5Stack AtomS3 Lite or any generic ESP32 dev board both work) placed near the out-of-range BLE devices, on your WiFi. It forwards BLE advertisements/GATT traffic to Home Assistant over the network — it doesn't need any wired connection to the NUC.

## Steps

1. Buy a supported board — check the tested list at the link above, or any ESP32 works with the generic ESPHome Bluetooth Proxy config even if not in that curated list.
2. Flash it via the official browser-based installer (no software install needed on your machine): https://esphome.io/components/bluetooth_proxy.html — plug the board in via USB, follow the on-page flow.
3. In Home Assistant: **Settings → Devices & services** — it should auto-discover via mDNS once flashed and on the network. Add it.
4. Repeat per area that needs coverage (kitchen, bedrooms, etc.) — each proxy only needs to be in Bluetooth range of the devices it's covering, not of the NUC.

No changes to the NUC build are required for this — it's purely additive on the Home Assistant side once a proxy device shows up as a discovered integration.
