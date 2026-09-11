# 0. Hardware Reset — Getting to a Clean Slate

Use this when you can't assume anything about the NUC's current state — e.g. it still has its prior Nutanix AHV BIOS configuration, an unknown BIOS password, or an unknown boot order that blocks installing fresh from USB. This is the one part of the whole build that has to be done in person, standing in front of the NUC — nothing here is remotable, by definition.

Sourced from Intel's official NUC BIOS documentation: https://www.intel.com/content/dam/support/us/en/documents/mini-pcs/BIOS-Recovery-NUC.pdf and the NUC8i3BE/NUC8i5BE/NUC8i7BE Technical Product Specification: https://www.intel.com/content/dam/support/us/en/documents/mini-pcs/nuc-kits/NUC8i3BE_NUC8i5BE_NUC8i7BE_TechProdSpec.pdf

## Work out which situation you're actually in

Try the cheapest option first — don't open the case unless you have to.

### 1. You can boot it and reach BIOS setup — just want it clean

No hardware step needed at all. Power on, tap **F2** during POST to enter BIOS Setup, press **F9** to load factory-default BIOS settings, **F10** to save and exit. Then boot straight into the OS installer USB (**F10** during POST for the one-time boot menu) and do a fresh install — this alone wipes any prior OS, disk contents get overwritten by the installer regardless of what's currently on the SSDs. This covers the Nutanix AHV leftovers case entirely.

### 2. You can boot it, but BIOS is password-protected or boot order/USB boot is locked down and you don't know the password

This is the more likely scenario given its prior life as a virtualisation demo box — labs often lock BIOS boot order deliberately. You need the **BIOS Configuration Jumper** method, which clears BIOS settings (including any password) without knowing the password:

1. Shut down, unplug the power adapter.
2. Open the chassis (four bottom-panel screws on the NUC8i7BEH). Locate the yellow BIOS Configuration Jumper — see the Technical Product Specification PDF linked above for its exact position on the board (it varies slightly by board revision, so don't rely on a generic photo).
3. Move/remove the jumper to the configure/clear position.
4. Reconnect power, turn the system on, wait 2-5 minutes.
5. Power off, unplug, replace the jumper in its original (normal) position.
6. Power on — BIOS is now at factory defaults, no password. Proceed as in scenario 1.

**Side effect, irrelevant to this build:** this also clears TPM/Intel PTT and HDCP keys. Nothing in this deployment uses BitLocker, Windows TPM features, or HDCP, so there's nothing to lose here.

### 3. It won't POST / no display at all / suspected corrupted BIOS firmware

This is a genuine BIOS recovery, not just a settings reset — different procedure, needs a recovery BIOS image:

1. Download the matching `.BIO` recovery file for NUC8i7BEH from Intel's Download Center (search "NUC8i7BEH BIOS").
2. Copy it to a USB drive (root of the drive, don't rename it).
3. Plug the USB into the NUC while it's off.
4. Press and hold the power button for 3 seconds, release — a Power Button Menu appears.
5. Press **F4** to start BIOS recovery. Wait 2-5 minutes. The system powers off or prompts you to when done.
6. Power on, **F2** into BIOS Setup, **F9** for defaults, **F10** to save.

## After any of the above

Proceed to `docs/01-os-base-setup.md` for the clean Ubuntu Server install and the rest of the build. Whatever was on the drives before this point is irrelevant — the OS installer will overwrite it.
