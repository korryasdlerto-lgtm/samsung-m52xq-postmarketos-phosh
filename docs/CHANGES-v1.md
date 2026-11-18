# Unofficial v1 (first public release)

Audience: users of the port and developers who want to know what is in the first public release of postmarketOS + Phosh
for the Samsung Galaxy M52 5G and why. The full log of the internal test builds before it is in
[ПРАВКИ.md](ПРАВКИ.md) (Russian).

| | |
|---|---|
| Kernel | 7.1.13: q6voice in-place device switch, panel sleep at brightness 0, ath11k radio-off power save, GPI shared-SE read fix, Venus HFI 6xx QP/bitrate (`kernel/patches/`) |
| Device tree | DTB from the upstream-style `sm7325-samsung-m52xq.dts` + local nodes, RTC enabled (`device-tree/`) |
| Root | postmarketOS edge, systemd, Phosh 0.58, 1225 packages ([packages-phosh.txt](packages-phosh.txt)) |
| Image | clean image: no personal data, keys or proprietary firmware, 2 chunks |
| Zip | `postmarketos-phosh-m52xq-mainline-v1-UNOFFICIAL.zip` (0.9 GB) |

A clean install is required: Format Data as described in the README.

## Installer and image

- **No proprietary firmware in the zip.** ADSP, modem, IPA, Venus, GPU zap shader, Bluetooth firmware, sensor configs and
  the sensor registry are copied from the phone's own partitions during the install.
- The installer grows `system` to 8 GB, checks that the image fits before writing it, writes boot, vendor_boot and dtbo.
- `/home` lives on the userdata partition (`m52xq-home-on-userdata`): about 100 GB for photos and videos instead of the
  1–2 GB left in `system`.
- SSH host keys and the machine ID are created on the first boot; the Bluetooth address is read from EFS.

## Calls, SMS, mobile data

- **Dual SIM (DSDS)** in ModemManager (patches 0100–0106): both SIMs active, a second modem object for SIM 2, data SIM
  selection, "SIM 1 / SIM 2" in Phosh, Calls and Chatty, empty slots hidden.
- **GNOME Calls:** hold, "Add call" on the same SIM, a second call while the first is on hold, swap (also from the main
  window), the call window comes to the front with the connected second call, SIM shown in the history, landscape call
  display, the call is not hung up when the window is hidden.
- In-call audio: earpiece, loudspeaker (switches at once every time), USB and Bluetooth headsets; noise suppression.
- Screen off at the ear (proximity), lock screen with hold / add call.
- Mobile data: a manual connection "Mobile data" (APN `internet`, IPv4) for the Phosh data tile.

## Camera (GNOME Snapshot)

- All four cameras: Main 64 MP, Front 32 MP, Wide, Macro; frames turned by the display rotation, correct EXIF orientation.
- **64 MP / 32 MP photos** through the own helper `m52xq-rawphoto` (raw capture through libcamera, development on the GPU).
- Tap to focus with contrast autofocus on the main camera, pinch zoom.
- **Video with the hardware encoder (Venus):** 1080p at 30 fps and **4K at 24 fps** ("4K Video" in the preferences);
  sensible bitrates after the kernel Venus fix; the phone does not sleep while recording.
- libcamera fixes: correct sensor modes after a camera switch, NV12 straight from the GPU debayer, no "Resource busy" when
  Snapshot (4K) and PipeWire use the cameras one after another, faster auto exposure when a camera opens in the dark.
- Snapshot fixes: no black viewfinder and no truncated videos when the stream restarts, no 25 s freeze after a 1080p
  recording, retries while a camera is still busy.

## Sleep and power

- s2idle with "dark resume": network wake-ups (modem, Wi-Fi) do not turn the screen on; wakes for calls, SMS and alarms
  (RTC wake alarm from GNOME Clocks).
- Wi-Fi wake-on-LAN while asleep, WPSS crash guard and restart; GPS paused for sleep; no suspend while an app inhibits idle
  (video recording, calls).

## Other

- Auto-rotation works right after the first boot; dual-SIM indicators and rotation tile in Phosh.
- Volume Up + Volume Down screenshot; "Reboot menu" app with "Reboot into recovery".
- Locales for Arabic, Hindi, Japanese, Korean and Chinese.
- Telegram Desktop preinstalled; ffmpeg from the Raspberry Pi fork for hardware-friendly video in Firefox and Telegram.

## Known issues

See the README: camera image quality in dim light, rare viewfinder freeze after many switches, screen at the ear now and
then, about 80 mA in deep sleep (the audio DSP does not sleep yet), rare Wi-Fi firmware crash on suspend, short black pause
on rotation.
