#!/bin/bash
# Build the root image of the release (postmarketOS edge + systemd + Phosh, Samsung Galaxy M52 5G / m52xq)
# and the flashable zip. This is the procedure used for the release zip, step by step (see docs/ИНСТРУКЦИЯ.md,
# section "в8: сборка релизного архива", for the output of every step).
#
# Needs: pmbootstrap 3.x with its own work dir (pmbootstrap-phosh.cfg), pmaports with
# device/testing/device-samsung-m52xq (../device-pkg) and the packages of ../build/ built into the local repo
# ($PMBP build --arch aarch64 calls snapshot libcamera phosh phosh-mobile-settings modemmanager m52xq-rawphoto),
# phoc / phosh-tour 0.58.0-r0 apks (Alpine edge cache), sudo, sgdisk, the firmware files of ../kernel/README.md.
#
# Usage: PMBP="pmbootstrap -c /path/pmbootstrap-phosh.cfg" W=/path/to/pmbootstrap/work \
#        B=/path/to/build-dir Z=/path/to/zip-folder FW=/path/to/fw ./build-image.sh
# Z is the zip folder: META-INF (../installer), mainline-extras/rootfs-files (../rootfs-overlay + binaries),
# firmware (boot, vendor_boot, dtbo-frag of the kernel release), data/rootfs-chunks (written here).
set -eu
PMBP=${PMBP:?pmbootstrap command with -c config}
W=${W:?pmbootstrap work dir}
B=${B:?build dir}
Z=${Z:?zip folder}
FW=${FW:?folder with wpss.*, a660_sqe.fw, a660_gmu.bin, ath11k/WCN6750/hw1.0/board-2.bin}
IMG=$B/samsung-m52xq.img
M=$B/mnt
mkdir -p $M

# 1. root image from pmbootstrap
$PMBP install --zap --password 1111 --add gnome-sound-recorder,hexagonrpcd,hexagonrpcd-systemd,hexagonrpcd-udev,rmtfs,rmtfs-systemd,rmtfs-udev,tqftpserv,tqftpserv-systemd,qrtr,qmi-utils,util-linux-misc,telegram-desktop,ffmpeg7-libavcodec,ffmpeg7-libavutil,ffmpeg7-libswresample,iw,libcamera-gstreamer
SRC=$W/chroot_native/home/pmos/rootfs/samsung-m52xq.img

# 2. 5 GB image with 4096-byte sectors. The partition table is written to the LOOP DEVICE (4096-byte sectors),
#    never to the image file (sgdisk on the file assumes 512-byte sectors and the partitions do not appear).
truncate -s 5368709120 $IMG
LD=$(sudo losetup -P --sector-size 4096 -f --show $IMG)
sudo sgdisk -o -n1:2048:133119 -c1:pmOS_boot -n2:133120:0 -t2:B921B045-1DF0-41C3-AF44-4C6F280D3FAE -c2:pmOS_root $LD
sudo partprobe $LD; sleep 1
test -b ${LD}p1 && test -b ${LD}p2
LS=$(sudo losetup -r -P --sector-size 4096 -f --show $SRC); sleep 1
sudo dd if=${LS}p1 of=${LD}p1 bs=4M status=none
sudo dd if=${LS}p2 of=${LD}p2 bs=4M status=none
sudo losetup -d $LS
# e2fsck of the host may be too old for the ext4 features of the image (orphan_file): use the one of the native chroot
N=$(basename $LD)p2; MM=$(lsblk -no MAJ:MIN ${LD}p2 | tr -d ' ')
$PMBP chroot -- apk add e2fsprogs-extra
sudo rm -f $W/chroot_native/dev/$N; sudo mknod $W/chroot_native/dev/$N b ${MM%:*} ${MM#*:}
$PMBP chroot -- e2fsck -fy /dev/$N || [ $? -le 1 ]
$PMBP chroot -- resize2fs /dev/$N
sudo mount ${LD}p2 $M

# 3. packages tested on the phone instead of the newer ones pmbootstrap picks (phosh 0.59, phoc 0.59,
#    ModemManager git20261005); calls, snapshot and libcamera come from the local repo already
A="sudo $W/apk.static --root $M --arch aarch64 --allow-untrusted --no-scripts --no-cache --keys-dir $M/etc/apk/keys --repositories-file $M/etc/apk/repositories"
SE=$W/packages/systemd-edge/aarch64; E=$W/packages/edge/aarch64; C=$W/cache_apk_aarch64
$A add $SE/phosh-99990.58.0-r101.apk $SE/libphosh-99990.58.0-r101.apk $SE/phosh-lang-99990.58.0-r101.apk \
  $SE/phosh-schemas-99990.58.0-r101.apk $SE/phosh-portalsconf-99990.58.0-r101.apk $SE/phosh-systemd-99990.58.0-r101.apk \
  $C/phoc-0.58.0-r0.*.apk $C/phoc-lang-0.58.0-r0.*.apk $E/phoc-schemas-0.58.0-r90.apk \
  $C/phosh-tour-0.58.0-r0.*.apk $C/phosh-tour-lang-0.58.0-r0.*.apk $C/phosh-tour-systemd-0.58.0-r0.*.apk \
  $E/modemmanager-1.25.95_git20260709-r11.apk $E/modemmanager-systemd-1.25.95_git20260709-r11.apk \
  $E/modemmanager-udev-1.25.95_git20260709-r11.apk $E/modemmanager-lang-1.25.95_git20260709-r11.apk \
  $E/libmm-glib-1.25.95_git20260709-r11.apk $E/m52xq-rawphoto-1-r3.apk

# 4. first-boot state: default password 1111, timesync dir, GPU/Wi-Fi firmware, empty machine-id, release tag, services
sudo touch $M/etc/.m52xq-default-password-set
sudo install -d -o 988 -g 988 -m 755 $M/var/lib/systemd/timesync
sudo install -o 988 -g 988 -m 644 /dev/null $M/var/lib/systemd/timesync/clock
sudo cp -a $FW/. $M/usr/lib/firmware/
H=$(openssl passwd -6 1111)
sudo awk -v h="$H" 'BEGIN{FS=OFS=":"} ($1=="root"||$1=="user"){$2=h} {print}' $M/etc/shadow | sudo tee $M/etc/shadow.new >/dev/null
sudo mv $M/etc/shadow.new $M/etc/shadow; sudo chown root:shadow $M/etc/shadow; sudo chmod 640 $M/etc/shadow
sudo sh -c ": > $M/etc/machine-id"
sudo install -d -m 755 $M/etc/m52xq; echo "postmarketos-phosh v1" | sudo tee $M/etc/m52xq/phosh-release >/dev/null
for s in audio-reprobe audio-rescue sensor-kick vol-screenshot; do
  sudo ln -sfn ../m52xq-$s.service $M/etc/systemd/system/multi-user.target.wants/m52xq-$s.service
done
test -z "$(sudo ls -A $M/home/user)"; test -z "$(sudo ls $M/etc/ssh | grep key || true)"
sudo umount $M

# 5. shrink: minimum size + 51200 blocks (~200 MB, the installer adds the phone's firmware), cut the image
$PMBP chroot -- e2fsck -fy /dev/$N || [ $? -le 1 ]
$PMBP chroot -- resize2fs -M /dev/$N; $PMBP chroot -- resize2fs -M /dev/$N
BL=$(sudo dumpe2fs -h ${LD}p2 2>/dev/null | awk -F: '/^Block count/{gsub(/ /,"",$2);print $2}')
NB=$((BL+51200))
$PMBP chroot -- resize2fs /dev/$N $NB
$PMBP chroot -- e2fsck -fn /dev/$N
sudo sgdisk -d2 -n2:133120:$((133120+NB-1)) -t2:B921B045-1DF0-41C3-AF44-4C6F280D3FAE -c2:pmOS_root $LD
sudo losetup -d $LD; sudo rm -f $W/chroot_native/dev/$N
truncate -s $(((133120+NB+33)*4096)) $IMG
LD=$(sudo losetup -P --sector-size 4096 -f --show $IMG)
sudo sgdisk -e $LD      # "invalid backup GPT header ... regenerating" is expected after the cut
sudo sgdisk -v $LD      # must say "No problems found"
sudo losetup -d $LD
md5sum $IMG | tee $IMG.md5

# 6. chunks (vfat on the SD card: < 4 GB per file)
mkdir -p $Z/data/rootfs-chunks
split -b 2684354560 -d -a 1 $IMG $Z/data/rootfs-chunks/samsung-m52xq.img.part-
cat $Z/data/rootfs-chunks/samsung-m52xq.img.part-* | md5sum
test -z "$(find $Z -xtype l)"

# 7. zip (from inside the folder, so META-INF is at the root of the zip)
cd $Z && zip -9 -r ../postmarketos-phosh-m52xq-mainline-v1.zip . -x 'test-images/*' -x 'kernel-src/*' -x 'patches/*' \
  -x 'packages/*' -x 'libcamera-tuning/*' -x 'ЗАДАЧИ_*.txt'
unzip -tq ../postmarketos-phosh-m52xq-mainline-v1.zip
