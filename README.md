# samsung-m52xq-postmarketos-phosh

postmarketOS + **Phosh** on a **mainline Linux kernel** for the
**Samsung Galaxy M52 5G** (codename `m52xq`, SM-M526B / SM-M526BR, Qualcomm Snapdragon 778G / SM7325).

No Halium, no libhybris, no Android kernel: mainline Linux 7.1.13 (build #444), postmarketOS edge with systemd, Phosh 0.58.
Sister project of [samsung-m52xq-mainline](https://github.com/korryasdlerto-lgtm/samsung-m52xq-mainline) (Plasma Mobile),
which holds the shared hardware layer, and of `samsung-m52xq-postmarketos-lomiri` (Lomiri on the same base).
Personal, unofficial project, tested on one SM-M526B.

**Status (2026-11-09): first root image built, not booted yet.** Stock postmarketOS Phosh, our device package and the
modules of the 7.1.13 #444 kernel. The m52xq fixes of the Plasma and Lomiri ports (audio, modem, Wi-Fi sleep, camera and
others) are not in it yet; they will be added one by one, each tested on the phone. There is no installer yet.

## Manuals

| Language | Markdown |
|---|---|
| English | [docs/MANUAL-EN.md](docs/MANUAL-EN.md) |
| Русский | [docs/MANUAL-RU.md](docs/MANUAL-RU.md) |

Step-by-step build guide with every command and its result (Russian): [docs/ИНСТРУКЦИЯ.md](docs/ИНСТРУКЦИЯ.md); work log: [docs/ЖУРНАЛ-PHOSH.md](docs/ЖУРНАЛ-PHOSH.md).

## Kernel

The same kernel as the Ubuntu Lomiri port: 7.1.13 #444 (q6voice in-place device switch, panel sleep at brightness 0,
ath11k power save with the radio off, RTC). Files: release
[kernel-7.1.13](https://github.com/korryasdlerto-lgtm/samsung-m52xq-ubuntu-lomiri/releases/tag/kernel-7.1.13)
of samsung-m52xq-ubuntu-lomiri. Source: [sc7280-mainline-linux-m52xq](https://github.com/korryasdlerto-lgtm/sc7280-mainline-linux-m52xq).
The modules in the image: [kernel/modules-7.1.13-444.txt](kernel/modules-7.1.13-444.txt).

## What works

| Feature | Status | Notes |
|---|---|---|
| Root image (pmOS edge, systemd, Phosh) | built | 1184 packages, [docs/packages-phosh.txt](docs/packages-phosh.txt) |
| Everything on the phone | not tested | first boot pending |

## Layout

| Folder | Contents |
|---|---|
| `image/` | build script, pmbootstrap config, package list (`world.txt`), repositories, `local-repo/` (device package r7 and the kernel placeholder apk, SHA256SUMS, public key) |
| `device-pkg/` | `device-samsung-m52xq` (pmaports `device/testing`), r7 |
| `kernel/` | kernel notes, list of the modules in the image |
| `installer/` | TWRP installer (not written yet) |
| `rootfs-overlay/` | files put over the image (none yet); binaries listed in `EXCLUDED-FILES.txt` |
| `docs/` | manuals (EN/RU), step-by-step guide, work log, package list |

The system image is not in the repository (it is a built system); see the manual, section 5.
