outdir = ${OUT}
ifeq ($(outdir),)
$(error Please run 'source build/envsetup.sh' first)
endif
# Final target - media code
bootcode: build/fssc-builder config mbr bootfs_files rootfs_files
	rm -rf $(outdir)/tmp
	cp -r build/fssc-builder $(outdir)/tmp
	rm $(outdir)/tmp/project.conf
	rm $(outdir)/tmp/config/*
	cp config/project.conf $(outdir)/tmp/
	cp config/*attributes* $(outdir)/tmp/config/
	rm -rf $(outdir)/tmp/content
	mkdir -p $(outdir)/tmp/content
	cp -r out/boot $(outdir)/tmp/content/boot
	cp -r out/root $(outdir)/tmp/content/earthos
	cp $(outdir)/parts/mbr  $(outdir)/tmp/
	cd $(outdir)/tmp && ./build.sh
	mv $(outdir)/tmp/output.fssc $(outdir)/EarthOS.fssc
	rm -rf $(outdir)/tmp
# Root fs files
rootfs_files: installer/rootfs build_info init usrsetup shell ui coreutils
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
	cd userspace/coreutils && ./build.sh && mv out/* $(outdir)/parts/coreutils/
# UI
ui: pwuc installer/rootfs $(outdir)/parts shell
	cd userspace/service/ui && pwuc main.pwsl -o $(outdir)/parts/ui
	mkdir -p installer/rootfs/etc/init.d
	cp userspace/service/ui/service installer/rootfs/etc/init.d/100-ui
# Shell
shell: pwuc $(outdir)/parts
	cd userspace/shell && pwuc main.pwsl -o $(outdir)/parts/shell
# User setup service
usrsetup: pwuc installer/rootfs $(outdir)/parts
	cd userspace/service/usrsetup && pwuc usrsetup.pwsle -o $(outdir)/parts/usrsetup && pwuc initcfg.pwsle -o $(outdir)/parts/initcfg
	mkdir -p installer/rootfs/etc/init.d
	cp userspace/service/usrsetup/service installer/rootfs/etc/init.d/5-users
# Init system
init: pwuc $(outdir)/parts
	cd userspace/init && pwuc main.pwsl -o $(outdir)/parts/init
# Boot fs files
bootfs_files: $(outdir)/parts lbl kernel
	rm -rf $(outdir)/boot
	mkdir -p $(outdir)/boot
	cp $(outdir)/parts/lbl $(outdir)/boot/boot.smc
	cp $(outdir)/parts/kernel $(outdir)/boot/ekrnl
# Kernel
kernel: pwc $(outdir)/parts kernel/main.pwsl
	cd kernel && pwc main.pwsl -o $(outdir)/parts/kernel --include-dir .
# Little bootloader
lbl: pwc $(outdir)/parts boot/lbl/main.pwsl
	cd boot/lbl && pwc main.pwsl -o $(outdir)/parts/lbl
# MBR
mbr: pwc $(outdir)/parts boot/mbr/main.pwsl build_tools
	cd boot/mbr && pwc main.pwsl -o $(outdir)/parts/mbr --string
	makembr $(outdir)/parts/mbr
# out/parts directory
$(outdir)/parts:
	mkdir -p $(outdir)/parts
# Build tools
build_tools: build/tools/makembr.c
	gcc build/tools/makembr.c -o build/bin/makembr
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
