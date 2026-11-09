# postmarketOS + Phosh on a mainline kernel for the Samsung Galaxy M52 5G (m52xq) — manual

Document version: 2026-11-09. State: **first root image built, not booted on the phone yet.**

## 1. What this is

- Device: Samsung Galaxy M52 5G, SM-M526B / SM-M526BR, Snapdragon 778G (SM7325, "yupik" platform), codename `m52xq`.
- Kernel: **mainline Linux 7.1.13**, build **#444**, the same kernel as the Ubuntu Lomiri port. No Halium, no libhybris.
- System: **postmarketOS edge** with systemd (`/etc/os-release` calls it "Nura edge"), **Phosh 0.58** shell (phoc 0.58,
  stevia keyboard). The image has 1184 packages (`docs/packages-phosh.txt`).
- The phone hardware layer (kernel, firmware, `m52xq-*` services) is shared with the Plasma port,
  [samsung-m52xq-mainline](https://github.com/korryasdlerto-lgtm/samsung-m52xq-mainline). This repository holds the Phosh work.
- Personal, unofficial port, tested on one SM-M526B.

## 2. What works

| Feature | State | Notes |
|---|---|---|
| Root image | built | pmOS edge, systemd, Phosh, our device package r7, 7.1.13 #444 modules |
| Boot, shell, display, touch | not tested | |
| Calls, SMS, mobile data | not tested | stock calls, chatty, ModemManager 1.25.95 in the image |
| Wi-Fi, Bluetooth, audio, camera, GPS, suspend | not tested | the m52xq fixes of the Plasma and Lomiri ports are not ported yet |

## 3. What is in the image

- The default Phosh set: `postmarketos-ui-phosh`, `phosh-mobile-settings`, `phosh-tour`, `calls`, `chatty`, `firefox-esr`
  (`mobile-config-firefox`), `gnome-contacts`, `gnome-clocks`, `gnome-maps`, `gnome-weather`, `gnome-calendar`, `gnome-console`,
  `nautilus`, `snapshot` (camera), `loupe`, `papers`, `showtime`, `decibels`, `g4music`, `flatpak`, `cups` and more.
  Full list of requested packages: `image/world.txt`.
- `device-samsung-m52xq-1-r7` (`device-pkg/`).
- `/usr/lib/modules/7.1.13`: the 23 modules of kernel #444 (`kernel/modules-7.1.13-444.txt`) plus `depmod`.
- User `user`, password `1111`; sshd enabled; nftables firewall enabled.

Not in the image:
- **proprietary firmware** (modem, ADSP, Venus, GPU zap, Bluetooth, sensors): as in the other ports, the installer will copy it from the phone;
- the m52xq fixes (`m52xq-*` services, ModemManager with the DSDS patches, audio, Wi-Fi sleep, camera). They are ported one by one,
  each tested on the phone;
- a TWRP installer.

## 4. Device package r7

`device-pkg/device-samsung-m52xq` is a copy of `device/testing/device-samsung-m52xq` from our pmaports.

Change r6 → r7 (2026-11-09): the post-install ran `ln -sf /usr/sbin/losetup /usr/bin/losetup`, left from the time when `/usr/sbin`
was a separate directory in edge. Edge now has a merged `/usr` (`/usr/sbin → bin`), so the command replaced the real `losetup` with a
link to itself and `mkinitfs` failed:

```
hookfiles: unable to process hook file "/usr/share/mkinitfs/files/00-initramfs-base.files":
unable to add "/usr/sbin/losetup": EvalSymlinks: too many links
```

The link is now made only when `/usr/bin/losetup` is missing and `/usr/sbin` is a separate directory. Where the loop already exists
(r6 was installed), `apk fix losetup` restores the binary.

## 5. Building the image

The build uses a pmbootstrap work directory of its own, so the work directories of the Plasma and Lomiri ports are not touched.
Script: `image/build-rootfs.sh`; config: `image/pmbootstrap-phosh.cfg`.

```sh
OUT=~/Templates/майнлайн/дроидиан/постмаркет PKGS=/path/to/apks \
MODULES=/path/to/lib/modules/7.1.13 \
PMB="/opt/python3.10/bin/python3.10 ~/Templates/майнлайн/tools/pmbootstrap/pmbootstrap.py" \
./image/build-rootfs.sh
```

What the script does:
1. creates the work directory with the `version` file, a local repository with the two already built packages
   (`device-samsung-m52xq-1-r7`, `linux-samsung-m52xq-7.1.2-r1`; the kernel package is a placeholder, the real kernel is in boot.img)
   and the signing key, owned by uid 12345 (user `pmos` inside the chroot), otherwise `pmbootstrap index` cannot sign the index;
2. writes the config with `build_pkgs_on_install = False`, so pmbootstrap does not build packages from the local `temp/` changes by itself;
3. `pmbootstrap index`, `pmbootstrap install --password 1111 --split`, `pmbootstrap shutdown`;
4. puts the 7.1.13 modules into `/usr/lib/modules` and runs `depmod`;
5. writes the md5 sums.

Result (2026-11-09):

| File | Size | md5 |
|---|---|---|
| `samsung-m52xq-root.img` | 2 463 105 024 bytes (ext4, `pmOS_root`, 4096-byte blocks) | `461bc05abc084db7e91ab3d9b9a91bf9` |
| `samsung-m52xq-boot.img` | 536 870 912 bytes | `798935345cba5ffcc2679e0e4833ce27` |

Check: `e2fsck 1.47.4 -fn` finds no errors. The image has `orphan_file` enabled. An old e2fsck (1.45 on the host) reports it as an error
("FEATURE_C12"); resize2fs and e2fsck in TWRP have to handle it once there is an installer.

## 6. Next

1. TWRP installer modelled on the Lomiri port (boot 7.1.13 #444, vendor_boot, dtbo-frag, system, firmware from the phone);
2. first boot, logs;
3. port the m52xq fixes of the Plasma and Lomiri ports one by one, testing each.
