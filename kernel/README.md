Kernel used here: mainline Linux 7.1.13, build #444 (the same as the Ubuntu Lomiri port).
Binaries (boot, vendor_boot, dtbo-frag, Image, config, modules): release kernel-7.1.13 of
https://github.com/korryasdlerto-lgtm/samsung-m52xq-ubuntu-lomiri
Source: https://github.com/korryasdlerto-lgtm/sc7280-mainline-linux-m52xq

The pmaports package linux-samsung-m52xq (7.1.2-r1) is only a placeholder that satisfies the device package dependency;
the real kernel is flashed as boot.img. The modules put into the image are listed in modules-7.1.13-444.txt.
