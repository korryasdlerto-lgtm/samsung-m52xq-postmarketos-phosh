# postmarketOS + Phosh on a mainline kernel for the Samsung Galaxy M52 5G (m52xq) — full manual

Release "unofficial v1", 2026-11-18. Russian version: [MANUAL-RU.md](MANUAL-RU.md).

## 1. What this is

postmarketOS edge with systemd and Phosh 0.58 on a mainline Linux 7.1.13 kernel for the Samsung Galaxy M52 5G
(SM-M526B / SM-M526BR, Snapdragon 778G / SM7325 "yupik"). No Halium, no libhybris, no Android kernel or Android services.
The hardware layer (kernel, device tree, `m52xq-*` services) is shared with the Plasma Mobile, Ubuntu Lomiri and
postmarketOS Lomiri ports of the same phone. Personal, unofficial project; tested on one SM-M526B.

## 2. What works

See the table in the [README](../README.md#what-works). In short: calls, SMS and mobile data on two SIMs, Wi-Fi, Bluetooth
(with audio), GPS, sensors, sound, a GPU-accelerated Phosh, all four cameras (64 MP photos, Venus video up to 4K), deep sleep
with wake-ups for calls, SMS and alarms. Not working: fingerprint, VoLTE.

Known issues are listed in the README as well: camera image quality in dim light, rare viewfinder freeze, the screen at the
ear now and then, about 80 mA in deep sleep, rare Wi-Fi firmware crash on suspend, short black pause on rotation.

## 3. Requirements

- Unlocked bootloader (OEM unlock), TWRP for m52xq:
  <https://github.com/saadelasfur/Action-Recovery-Builder/releases/tag/20261004173308>.
- Backups of EFS, persist, modem, boot, vendor_boot and vbmeta (TWRP Backup) and the stock firmware for Odin.
- A Samsung-based ROM installed before (stock, UN1CA or LineageOS): the installer copies the device firmware from its
  `vendor`, `apnhlos`, `modem`, `persist` and `efs` partitions. UN1CA_3.1.0 gives the largest `system` partition.

## 4. Installation

### 4.1. Flashable zip (TWRP)

1. Download [postmarketos-phosh-m52xq-mainline-v1-UNOFFICIAL.zip](https://drive.google.com/file/d/1j3U80MAcUWkaXCpt41vcyFUClD5SpIIp/view?usp=sharing) (md5 `946280ae620d3f04feb7e25a009fb492`) and copy it to the microSD card (or `adb push` it to `/data` after
   Format Data in TWRP).
2. In TWRP:

```
Wipe - Format Data - yes - enter - Back - Back - Advanced Wipe - Data - Repair or Change File System - Change File System - EXT4 - Swipe to Change - Back - Back - Back - Back - Back - Install - Select Storage - Micro SD card - postmarketos-phosh-m52xq-mainline-v1-UNOFFICIAL.zip - Swipe to confirm Flash - Reboot System
```

3. Wait for `Updater process ended with RC=0`. The first boot takes longer.

What the installer does: grows `system` to 8 000 000 000 bytes in the LP metadata, checks that the root image fits,
writes the image from its two chunks, writes boot, vendor_boot and dtbo, copies the device firmware from the phone's own
partitions (read-only), adds the IPA firmware to the boot ramdisk, sets up the sensor registry for the ADSP, puts the
`m52xq-*` overlay over the root and enables the services, and moves `/home` to the userdata partition on the first boot.

The phone gets warm during the install. If the display already shows vertical coloured lines, do not install: the heat may
make them worse.

### 4.2. Password and access

- Default password (screen unlock, `user`, `root`): `1111`. Change it with `passwd` in the Console app.
- SSH over USB (RNDIS, about 30 s after boot): `ssh root@172.16.42.1`, password `1111`.
- Screenshot: Volume Up + Volume Down, saved to `~/Pictures/Screenshots`.
- "Reboot menu" app: reboot, reboot into recovery (TWRP), power off.
- "SIM cards manager" app (`m52xq-sim-manager`): both SIMs / only SIM 1 / only SIM 2, data SIM.
- Mobile data: Settings - Mobile Network, or the data tile in the Phosh quick settings (connection "Mobile data",
  APN `internet`; change the APN in Settings - Mobile Network if your operator needs another one).

## 5. Going back to Android

Enter TWRP ("Reboot menu" - "Reboot into recovery", or power + volume keys). Copy the ROM zip to the microSD card first.

```
Wipe - Format Data - yes - enter - Back - Back - Back - Advanced Wipe - Data - Repair or Change File System - Change File System - EXT4 - Swipe to Change - Back - Back - Back - Back - Back - Install - lineage-23.2-2026-nightly-m52xq-signed.zip - Back - Back - Wipe - Format Data - enter - Reboot System
```

The LineageOS and UN1CA zips rewrite boot, vendor_boot and dtbo themselves. Stock firmware: Odin or Heimdall (BL, AP, CP, CSC).

## 6. Kernel

Mainline Linux 7.1.13, source <https://github.com/korryasdlerto-lgtm/sc7280-mainline-linux-m52xq>, config and the
patches of this release in [`../kernel/`](../kernel/README.md). The boot, vendor_boot and dtbo images are in the zip
(`firmware/`). The DTB comes from [`../device-tree/`](../device-tree).

## 7. Building from scratch

1. pmbootstrap 3.x with its own work dir; config [`../image/pmbootstrap-phosh.cfg`](../image/pmbootstrap-phosh.cfg)
   (device `samsung-m52xq`, UI `phosh`, systemd, `build_pkgs_on_install = False`).
2. Device package: [`../device-pkg/device-samsung-m52xq`](../device-pkg/device-samsung-m52xq) into pmaports
   `device/testing`.
3. Rebuilt packages: copy each folder of [`../build/`](../build) to pmaports `temp/` and run
   `pmbootstrap build --arch aarch64 <name>` (calls, snapshot, libcamera, phosh, phosh-mobile-settings, modemmanager,
   chatty, ffmpeg7, libssc, m52xq-rawphoto). Snapshot needs `options="net !check"` while building under qemu (its cargo tests
   hang there).
4. Root image and zip: [`../image/build-image.sh`](../image/build-image.sh). It runs `pmbootstrap install`, makes a 5 GB
   image with 4096-byte sectors, replaces the packages pmbootstrap picks newer than the tested ones (Phosh 0.59, phoc 0.59,
   ModemManager git20261005), prepares the first-boot state, shrinks the file system (+ about 200 MB for the firmware the
   installer adds), cuts the image into two chunks and zips the folder.
5. Zip folder layout: `META-INF/` ([`../installer/`](../installer)), `mainline-extras/rootfs-files/`
   ([`../rootfs-overlay/`](../rootfs-overlay) + the binaries of `EXCLUDED-FILES.txt`), `firmware/` (boot, vendor_boot,
   dtbo-frag), `data/rootfs-chunks/`.

Every command of the release build with its output: [ИНСТРУКЦИЯ.md](ИНСТРУКЦИЯ.md) (Russian), section
"в8: сборка релизного архива" (the last internal build = this release).

## 8. Repository layout

See the [README](../README.md#repository-layout).

## 9. Rebuilt packages (`build/`)

See the [README](../README.md#rebuilt-packages-build).

## 10. Services and scripts (overlay)

| Name | What it does |
|---|---|
| `m52xq-adsp-start`, `m52xq-audio-reprobe`, `m52xq-audio-rescue` | start the ADSP once the firmware is on the root; bring the sound card up after the ADSP start race |
| `m52xq-modem-setup`, `m52xq-sim-mode*`, `m52xq-dds`, `m52xq-nas-mode`, `m52xq-flight-mode` | modem session and GNSS setup, SIM mode (both / SIM 1 / SIM 2), data SIM, network modes, cellular flight mode |
| `m52xq-voicecall`, `m52xq-callaudiod`, `m52xq-voice-mixers.sh`, `m52xq-usb-call-bridge` | modem voice path for a call (q6voice + codec mixers), CallAudio D-Bus API for Calls, USB headset bridge |
| `m52xq-tfa-guard` | re-opens the loudspeaker if the TFA9878 amplifier setup fails |
| `m52xq-audio-route`, `m52xq-voip-audio`, `m52xq-speakerphone` | sound of apps (Telegram calls, media): loudspeaker, earpiece, headsets |
| `m52xq-incall-proximity` | screen off and touch locked at the ear in calls |
| `m52xq-idle-suspend` | own idle suspend (no suspend while an app inhibits idle, e.g. video recording) |
| system-sleep hooks | dark resume (panel stays dark on network wake-ups), GPS pause, modem 2G in sleep, keep Wi-Fi, UFS power level, cameras off, fewer self-caused wake-ups |
| `m52xq-wake-restore`, `m52xq-bt-restore` | give back Bluetooth, network modes and GPS when the user is really there |
| `m52xq-wow-params`, `m52xq-wpss-guard`, `m52xq-wpss-restart` | Wi-Fi wake-on-LAN flags, WPSS crash-loop guard and cold restart |
| `m52xq-bt-firmware`, `m52xq-bt-addr.py`, `m52xq-bt-autoconnect` | Bluetooth firmware reload, the phone's own BD address, reconnect paired headphones |
| `m52xq-sensor-kick` | starts iio-sensor-proxy again once the ADSP sensors are up (auto-rotation) |
| `m52xq-virtualcam` | virtual V4L2 webcams (libcamera to v4l2loopback) for Telegram and browsers |
| `m52xq-home-on-userdata` | `/home` on the userdata partition |
| `m52xq-vol-screenshot`, `m52xq-reboot-menu`, `m52xq-sim-manager` | screenshot keys, reboot menu, SIM cards app |
| `m52xq-backlight-min` | no almost-black brightness after a reboot from a dimmed screen |

## 11. Pitfalls (short)

- Write the GPT of the image to the loop device with 4096-byte sectors, never to the image file (512-byte sectors).
- The e2fsck of an older host does not understand the ext4 features of the image (`orphan_file`): use the one of the
  pmbootstrap native chroot.
- pmbootstrap installs the newest Phosh, phoc and ModemManager: replace them with the tested ones (see the build script).
- Two libcamera instances (PipeWire and an app with libcamerasrc) used to leave camss links enabled behind each other's back;
  the libcamera patch 0010 sets the links up without trusting the cached flags.
- The proximity sensor is under the OLED panel and sees nothing while the panel is off.
- `MODVERSIONS` is off: kernel modules only with the same Image.

## 12. Credits

postmarketOS and pmbootstrap, Phosh / phoc / GNOME (Calls, Snapshot), libcamera, ModemManager, the mainline Linux
developers for Qualcomm SC7280 / QCM6490, LineageOS (reference sources), the TWRP maintainers for m52xq.
