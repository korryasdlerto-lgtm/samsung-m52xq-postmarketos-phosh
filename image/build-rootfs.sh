#!/bin/bash
# Build the postmarketOS (edge, systemd) + Phosh root image for the Samsung Galaxy M52 5G (m52xq)
# in a pmbootstrap work directory of its own, so the Plasma / Lomiri work directories are not touched.
#
# Needs: pmbootstrap 3.11, pmaports with device/testing/device-samsung-m52xq (../device-pkg) and the
# already built packages device-samsung-m52xq and linux-samsung-m52xq (the kernel package is only a
# placeholder: the real kernel is boot.img 7.1.13 #444, see ../kernel/README.md), sudo.
#
# Usage: OUT=/path/to/output PKGS=/path/to/apks MODULES=/path/to/lib/modules/7.1.13 ./build-rootfs.sh
set -eu
OUT=${OUT:?output folder}
MODULES=${MODULES:?folder with the 7.1.13 modules (23 .ko + modules.*)}
PMB=${PMB:-pmbootstrap}
OLDWORK=${OLDWORK:-$HOME/.local/var/pmbootstrap}   # work dir that holds the signing key and the "version" file
PKGS=${PKGS:?folder with device-samsung-m52xq-1-r7.apk and linux-samsung-m52xq-7.1.2-r1.apk (pmbootstrap build --arch aarch64 ...)}
W=$OUT/work
CFG=$OUT/pmbootstrap-phosh.cfg
here=$(cd "$(dirname "$0")" && pwd)

# 1. separate work dir: version file, local repo with the two device packages, signing key
mkdir -p $W/packages/edge/aarch64 $W/config_apk_keys $W/config_abuild
cp $OLDWORK/version $W/
cp $PKGS/device-samsung-m52xq-1-r7.apk $PKGS/linux-samsung-m52xq-7.1.2-r1.apk $W/packages/edge/aarch64/
cp $OLDWORK/config_apk_keys/pmos@local-*.rsa.pub $W/config_apk_keys/
sudo cp -a $OLDWORK/config_abuild/. $W/config_abuild/
sudo chown -R 12345:12345 $W/config_abuild $W/packages          # pmbootstrap writes them as user "pmos" (uid 12345)

# 2. config (build_pkgs_on_install = False: nothing from the dirty pmaports temp/ gets built by surprise)
sed "s#^work = .*#work = $W#; s#^aports = ~#aports = $HOME#" $here/pmbootstrap-phosh.cfg > $CFG

# 3. index the local repo, install, shut the chroots down
$PMB -c $CFG index
$PMB -c $CFG -y install --password 1111 --split
$PMB -c $CFG shutdown
cp $W/chroot_native/home/pmos/rootfs/samsung-m52xq-root.img $W/chroot_native/home/pmos/rootfs/samsung-m52xq-boot.img $OUT/

# 4. kernel modules of the real kernel (merged /usr: lib -> usr/lib)
M=$OUT/mnt; mkdir -p $M
sudo mount -o loop $OUT/samsung-m52xq-root.img $M
sudo mkdir -p $M/usr/lib/modules
sudo cp -a $MODULES $M/usr/lib/modules/7.1.13
sudo chown -R 0:0 $M/usr/lib/modules/7.1.13
sudo depmod -b $M 7.1.13 || true      # an old host kmod prints "unexpected string without modname prefix"; modules.dep is still written
sudo umount $M; rmdir $M

# 5. check with a new e2fsck (the image has orphan_file; e2fsck < 1.47 reports it as an error) and record md5
md5sum $OUT/samsung-m52xq-root.img $OUT/samsung-m52xq-boot.img | tee $OUT/images.md5
