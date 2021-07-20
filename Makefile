outdir = ${OUT}
ifeq ($(outdir),)
$(error Please run 'source build/envsetup.sh' first)
endif
# Final target - media code
bootcode: mbr bootfs rootfs
	mkfpt out/EarthOS.fssc --config config/disk.conf
	@echo
	@echo Build finished successfully, see the out/EarthOS.fssc file.
# Root fs
rootfs: build_tools config rootfs_files
	mkfs.fssc2 --root $(outdir)/root --attributes config/attributes.list $(outdir)/root.img
# Boot fs
bootfs: build_tools config bootfs_files
	mkfs.fssc2 --root $(outdir)/boot --attributes config/boot-attributes.list $(outdir)/boot.img
# Root fs files
rootfs_files: installer/rootfs build_info init banner usrsetup shell ui coreutils
	rm -rf $(outdir)/root
	cp -r installer/rootfs $(outdir)/root
	rm -rf $(outdir)/root/.git*
	find $(outdir)/root -name .gitignore | xargs rm -f
	mkdir -p $(outdir)/root/sbin
	mkdir -p $(outdir)/root/bin
	mkdir -p $(outdir)/root/lib/system/users
	mkdir -p $(outdir)/root/boot
	mkdir -p $(outdir)/root/dev
	mkdir -p $(outdir)/root/proc
	mkdir -p $(outdir)/root/sys
	cp $(outdir)/parts/init $(outdir)/root/sbin/
	cp $(outdir)/parts/banner $(outdir)/root/sbin/
	cp $(outdir)/parts/usrsetup $(outdir)/root/lib/system/
	cp $(outdir)/parts/initcfg $(outdir)/root/lib/system/
	cp $(outdir)/parts/shell $(outdir)/root/bin/
	cp $(outdir)/parts/ui $(outdir)/root/lib/system/
	cp $(outdir)/parts/coreutils/* $(outdir)/root/bin/
# Build info
build_info: installer/rootfs
	./build/buildsetup.sh
# Core utils
coreutils: pwuc $(outdir)/parts
	mkdir -p $(outdir)/parts/coreutils
	cd userspace/coreutils && ./build.sh && mv out/* ../../$(outdir)/parts/coreutils/
# UI
ui: pwuc installer/rootfs $(outdir)/parts shell
	cd userspace/service/ui && pwuc main.pwsl -o ../../../$(outdir)/parts/ui
	mkdir -p installer/rootfs/etc/init.d
	cp userspace/service/ui/service installer/rootfs/etc/init.d/100-ui
# Shell
shell: pwuc $(outdir)/parts
	cd userspace/shell && pwuc main.pwsl -o ../../$(outdir)/parts/shell
# User setup service
usrsetup: pwuc installer/rootfs $(outdir)/parts
	cd userspace/service/usrsetup && pwuc usrsetup.pwsle -o ../../../$(outdir)/parts/usrsetup && pwuc initcfg.pwsle -o ../../../$(outdir)/parts/initcfg
	mkdir -p installer/rootfs/etc/init.d
	cp userspace/service/usrsetup/service installer/rootfs/etc/init.d/5-users
# Banner service
banner: pwuc installer/rootfs $(outdir)/parts
	cd userspace/service/banner && pwuc main.pwsl -o ../../../$(outdir)/parts/banner
	mkdir -p installer/rootfs/etc/init.d
	cp userspace/service/banner/service installer/rootfs/etc/init.d/0-banner
# Init system
init: pwuc $(outdir)/parts
	cd userspace/init && pwuc main.pwsl -o ../../$(outdir)/parts/init
# Boot fs files
bootfs_files: $(outdir)/parts lbl kernel
	rm -rf $(outdir)/boot
	mkdir -p $(outdir)/boot
	cp $(outdir)/parts/lbl $(outdir)/boot/boot.smc
	cp $(outdir)/parts/kernel $(outdir)/boot/ekrnl
# Kernel
kernel: pwc $(outdir)/parts kernel/main.pwsl
	cd kernel && pwc main.pwsl -o ../$(outdir)/parts/kernel --include-dir .
# Little bootloader
lbl: pwc $(outdir)/parts boot/lbl/main.pwsl
	cd boot/lbl && pwc main.pwsl -o ../../$(outdir)/parts/lbl
# MBR
mbr: pwc $(outdir)/parts boot/mbr/main.pwsl build_tools
	cd boot/mbr && pwc main.pwsl -o ../../$(outdir)/mbr.img --string
	makembr $(outdir)/mbr.img
# out/parts directory
$(outdir)/parts:
	mkdir -p $(outdir)/parts
# Build tools
build_tools: build/tools/makembr.c build/tools/fssc/mkfs.fssc2.c build/tools/fssc/mkfpt.c
	gcc build/tools/makembr.c -o build/bin/makembr
	gcc build/tools/fssc/mkfs.fssc2.c -o build/bin/mkfs.fssc2
	gcc build/tools/fssc/mkfpt.c -o build/bin/mkfpt
# PowerSlash userspace compiler
pwuc: build/pwuc/pwc.c
	mkdir -p build/bin
	gcc build/pwuc/pwc.c -o build/bin/pwuc
# PowerSlash compiler
pwc: build/pwc/pwc.c
	mkdir -p build/bin
	gcc build/pwc/pwc.c -o build/bin/pwc
# Clean
clean:
	rm -rf build/bin
	rm -rf $(outdir)/*
