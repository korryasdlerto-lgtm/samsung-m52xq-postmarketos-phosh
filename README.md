# samsung-m52xq-postmarketos-phosh

**postmarketOS (edge, systemd) + Phosh** on a **mainline Linux kernel** for the
**Samsung Galaxy M52 5G** (codename `m52xq`, SM-M526B / SM-M526BR, Qualcomm Snapdragon 778G / SM7325, platform "yupik").

It is not Halium, not libhybris and not the Android kernel. The phone runs a mainline Linux 7.1.13 kernel with device drivers
and fixes, and a postmarketOS edge root with systemd and Phosh 0.58. The hardware layer (kernel, `m52xq-*` services) is the
same as in the sister ports [samsung-m52xq-mainline](https://github.com/korryasdlerto-lgtm/samsung-m52xq-mainline)
(Plasma Mobile), [samsung-m52xq-ubuntu-lomiri](https://github.com/korryasdlerto-lgtm/samsung-m52xq-ubuntu-lomiri) and
`samsung-m52xq-postmarketos-lomiri`. Personal, unofficial project (not a postmarketOS release), tested on one SM-M526B.

**Status (release "unofficial v1", 2026-11-18, see [changes](docs/CHANGES-v1.md) / [на русском](docs/CHANGES-v1-RU.md)):
usable, but not yet ready as your only phone.** It has calls, SMS and mobile data on two SIMs, Wi-Fi, Bluetooth, a GPU-accelerated Phosh,
sound, GPS, sensors, all four cameras with 64 MP photos and hardware-encoded 4K video, and deep sleep that wakes for calls,
SMS and alarms.

## Repositories

| | |
|---|---|
| This repository | installer, rootfs overlay (scripts, services, configs), recipes and patches of the rebuilt packages, device package, image build script, device tree, kernel config and patches, documentation |
| Kernel source | [sc7280-mainline-linux-m52xq](https://github.com/korryasdlerto-lgtm/sc7280-mainline-linux-m52xq); the patches of this release on top of it are in [`kernel/patches/`](kernel/patches) |
| Kernel binaries | boot.img, vendor_boot.img and dtbo of this release are inside the flashable zip (`firmware/`) |

## What works

| Feature | Status | Notes |
|---|---|---|
| Boot, UFS storage | works | `system` grown to 8 GB by the installer; `/home` on the userdata partition (about 100 GB) |
| Display | works | Samsung S6E3HAB AMOLED, brightness, auto-rotation; the panel stays dark on network wake-ups |
| GPU (Adreno 642L) | works | Mesa freedreno, Phosh/phoc composited on the GPU |
| Touchscreen, keyboard | works | Synaptics; Phosh on-screen keyboard |
| Wi-Fi, Bluetooth, BT audio | works | WCN6750 / ath11k; Bluetooth address from the phone's EFS; Wi-Fi wake-on-LAN while asleep |
| Calls, SMS, mobile data | works | **dual SIM** (DSDS, both active, "SIM 1 / SIM 2" in Phosh and GNOME Calls); hold, second call, swap, speaker/earpiece, USB and BT headsets in calls; mobile data is a manual connection ("Mobile data", APN `internet`, IPv4) |
| Audio | works | loudspeaker (TFA9878), earpiece, microphones, in-call noise suppression, USB audio |
| GPS | works | ModemManager GNSS, GeoClue |
| Sensors | works | light, proximity (screen off at the ear in calls), accelerometer (auto-rotation) |
| Battery, charging | works | SM5714 fuel gauge and charger |
| Suspend | works | s2idle; wakes for calls, SMS and alarms (RTC); the screen stays off on network wake-ups |
| Camera | works, partial | GNOME Snapshot with all four cameras (Main 64 MP, Front 32 MP, Wide, Macro), **64 MP / 32 MP photos**, tap to focus, digital zoom, **video with the hardware encoder (Venus), up to 4K at 24 fps**; image processing in software |
| Video playback | works | software decoding |
| Telegram | works | Telegram Desktop is preinstalled |
| Fingerprint | no | |
| VoLTE | no | calls use 2G/3G |

### Known issues

- **Camera image quality:** the viewfinder and videos are processed by the libcamera software ISP with generic colour
  matrices and no noise reduction: in dim light they look hazy and noisy. 64 MP / 32 MP photos are developed by an own GPU
  pipeline (`m52xq-rawphoto`) and look better.
- **Camera viewfinder:** rarely, after many camera and mode switches, the viewfinder of the main camera freezes for a moment;
  it comes back by itself. Photos are saved anyway.
- **Screen at the ear in calls:** the proximity sensor sits under the OLED and sees nothing while the panel is off, so the
  screen may turn on again near the ear now and then.
- **Sleep current:** about 80 mA in deep sleep (the audio DSP does not sleep yet); a full battery lasts about two days on standby.
- **Wi-Fi after a long sleep:** rarely the Wi-Fi firmware (WPSS) crashes on suspend with wake-on-LAN on; switch Wi-Fi off
  and on, or reboot.
- **Rotation:** a short black pause (about 1 s) when the screen turns.

## Install

Requirements: unlocked bootloader, TWRP for m52xq
(<https://github.com/saadelasfur/Action-Recovery-Builder/releases/tag/20261004173308>), the zip on the phone's `/data`
(adb push in TWRP) or on a microSD card, backups of EFS, persist, modem, boot, vendor_boot and vbmeta. If you are not
comfortable restoring a Samsung phone with Odin, do not install this.

- Video guide: <https://www.youtube.com/watch?v=F3BdpIiWePo> (switching from another Linux port, so UN1CA is not flashed there)
- Flashable zip (0.9 GB): [postmarketos-phosh-m52xq-mainline-v1-UNOFFICIAL.zip](https://drive.google.com/file/d/1j3U80MAcUWkaXCpt41vcyFUClD5SpIIp/view?usp=sharing), md5 `946280ae620d3f04feb7e25a009fb492`

The phone gets warm during the install. If your display already shows vertical coloured lines, do not install this: the
heat may make them worse.

Flash **UN1CA_3.1.0** first to get the maximum system partition size (the installer grows `system` to 8 000 000 000 bytes).
After LineageOS 23 the partition is 1 GB smaller, but the install still works.

TWRP steps:

```
Wipe - Format Data - yes - enter - Back - Back - Advanced Wipe - Data - Repair or Change File System - Change File System - EXT4 - Swipe to Change - Back - Back - Back - Back - Back - Install - Select Storage - Micro SD card - postmarketos-phosh-m52xq-mainline-v1-UNOFFICIAL.zip - Swipe to confirm Flash - Reboot System
```

The install takes a few minutes; wait for `Updater process ended with RC=0`. The first boot takes longer.

The installer writes boot, vendor_boot and dtbo, writes the root image to `system`, adds the device services and moves
`/home` to the userdata partition. The Samsung/Qualcomm device firmware is **not** in the zip: the installer copies it,
read-only, from the phone's own partitions. ADSP, GPU zap shader, IPA (mobile data) and Venus come from `apnhlos`.
Bluetooth firmware and sensor configs come from `vendor`, the modem from `modem`, the sensor registry from `persist` and the
Bluetooth address from `EFS`. The IPA firmware is added to the boot ramdisk, because the built-in IPA driver needs it before
the root is mounted. `vendor` must come from a Samsung-based ROM (stock, UN1CA or LineageOS). SSH host keys and the machine
ID are created on the first boot.

- Default password (screen unlock, `user` and `root`): `1111`. Change it with `passwd` in the Console app.
- SSH over USB (about 30 s after boot): `ssh root@172.16.42.1` (password `1111`).
- Screenshot: press **Volume Up + Volume Down** at the same time; the picture goes to `~/Pictures/Screenshots`.
- Reboot into recovery: app "Reboot menu" - "Reboot into recovery".

### Back to Android

Video guide: <https://www.youtube.com/watch?v=0lgLbtdl4rA&t=89s>

Enter TWRP (app "Reboot menu" - "Reboot into recovery", or the power and volume button combination). Copy the firmware zip to
the microSD card first. The LineageOS and UN1CA zips rewrite boot, vendor_boot and dtbo themselves.

```
Wipe - Format Data - yes - enter - Back - Back - Back - Advanced Wipe - Data - Repair or Change File System - Change File System - EXT4 - Swipe to Change - Back - Back - Back - Back - Back - Install - lineage-23.2-2026-nightly-m52xq-signed.zip - Back - Back - Wipe - Format Data - enter - Reboot System
```

Latest LineageOS build: <https://download.lineageos.org/devices/m52xq/builds>. Stock firmware can always be restored with
Odin or Heimdall (BL, AP, CP, CSC).

## Repository layout

| Path | Content |
|---|---|
| `installer/` | `META-INF/.../update-binary` of the flashable zip (TWRP shell installer) |
| `rootfs-overlay/` | files over the postmarketOS root: `m52xq-*` scripts and services, system-sleep hooks, systemd drop-ins, udev and polkit rules, WirePlumber / PulseAudio / NetworkManager configs, GSettings overrides, libcamera tuning, locales. Binaries (kernel modules, libssc) are not here: see `rootfs-overlay/EXCLUDED-FILES.txt` (path, size, md5) |
| `build/` | APKBUILDs and patches of every rebuilt package (table below) |
| `device-pkg/` | `device-samsung-m52xq` (pmaports `device/testing`) |
| `kernel/` | kernel config (`config-7.1.13`) and `patches/` on top of the kernel repository |
| `device-tree/` | `sm7325-samsung-m52xq.dts` (upstream-style) and `sm7325-samsung-m52xq-local.dts` (local additions, RTC enabled): the DTB in vendor_boot of this release |
| `image/` | `build-image.sh` (root image and zip, step by step), pmbootstrap config, package list (`world.txt`), repositories |
| `docs/` | manuals (EN/RU), change list of v1, step-by-step build commands and the full change log (Russian), list of the packages in the image |

### Rebuilt packages (`build/`)

| Folder | What and why |
|---|---|
| `calls` | GNOME Calls 51.1 + patches 0001–0013: hold, "Add call" on the same SIM, second call, swap (also in the main window), the call window comes to the front for a second call, SIM in the history, landscape call display, no hang-up when the window is hidden |
| `phosh` | Phosh 0.58 + dual-SIM indicators and tiles, rotation tile, hold / add call on the lock screen |
| `phosh-mobile-settings` | keeps the on/off switch of the Bluetooth and Wi-Fi panels |
| `modemmanager` | ModemManager 1.25.95 + patches 0100–0106: dual SIM (DSDS) with two modem objects, data SIM, netlink use-after-free fix, always power up online |
| `snapshot` | GNOME Snapshot 51 + one patch: frames turned by the display rotation, all four cameras, tap to focus, zoom, 64 MP photos through `m52xq-rawphoto`, Venus video up to 4K (libcamerasrc), retries when a camera is still busy |
| `libcamera` | libcamera 0.8.0 + patches: soft-IPA sensor info on configure, NV12 output of the GPU debayer, pipeline links set up without the cached flags (two libcamera instances), faster auto exposure for sensors without a helper; `tuning-m52xq/` sensor tuning files; `tools/m52xq-blacklevel.py` |
| `chatty` | Chatty 0.8.9 + SMS on both SIMs and chat actions |
| `ffmpeg7` | ffmpeg 7.1.5 from the Raspberry Pi fork (V4L2 request API) for Firefox and Telegram |
| `libssc` | libssc 0.4.4 + proximity sensor fixes and a report dump (used by the in-call proximity service) |
| `m52xq-rawphoto` | own helper: raw 64 MP / 32 MP capture through libcamera and development on the GPU (quad-Bayer remosaic, white balance, noise reduction, JPEG with EXIF) |

The `.apk` packages themselves are not in the repository.

## Building

- Kernel: `make ARCH=arm64 LLVM=1 Image` with clang/LLD 22 (the pmbootstrap Alpine chroot) using `kernel/config-7.1.13`
  and the patches in `kernel/patches/`; the boot image is the previous boot.img with the new `Image` and the appended DTB
  tail. The Venus modules of this release are built with `make M=drivers/media/platform/qcom/venus modules`.
  `MODVERSIONS` is off: use the modules only with the same Image.
- Packages: copy a folder of `build/` to pmaports (`temp/<name>`) and run `pmbootstrap build --arch aarch64 <name>`.
- Root image and zip: [`image/build-image.sh`](image/build-image.sh); every command of the release build with its output is in
  [docs/ИНСТРУКЦИЯ.md](docs/ИНСТРУКЦИЯ.md), section "в8: сборка релизного архива".

## Manuals

| Language | Markdown |
|---|---|
| English | [docs/MANUAL-EN.md](docs/MANUAL-EN.md) |
| Русский | [docs/MANUAL-RU.md](docs/MANUAL-RU.md) |

Step-by-step commands with output (Russian): [docs/ИНСТРУКЦИЯ.md](docs/ИНСТРУКЦИЯ.md); change log by build: [docs/ПРАВКИ.md](docs/ПРАВКИ.md).

## Bug reports

Please write your model (SM-M526B / SM-M526BR), what you did and what happened. Logs help a lot: `journalctl -b` and
`dmesg` over SSH or in the Console app.

## Credits

postmarketOS and pmbootstrap, the Phosh and GNOME developers (Phosh, phoc, Calls, Snapshot), libcamera, ModemManager, the
mainline Linux developers for Qualcomm SC7280 / QCM6490 (Fairphone 5 and others), LineageOS (device and kernel sources used
as reference), the TWRP maintainers for m52xq.

## License

Kernel code: GPL-2.0 (see the kernel repository). Patches follow the license of the patched project. Scripts and
documentation in this repository: GPL-2.0.
