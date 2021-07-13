outdir = ${OUT}
# Final target - media code
#media: out/rootfs.img
# Root fs files
rootfs_files: installer/rootfs init usrsetup shell ui coreutils
	rm -rf $(outdir)/root
	cp -r installer/rootfs $(outdir)/root
	rm -rf $(outdir)/root/.git*
	find $(outdir)/root -name .gitignore | xargs rm -f
	cp $(outdir)/parts/init $(outdir)/root/sbin/
	cp $(outdir)/parts/usrsetup $(outdir)/root/lib/system/
	cp $(outdir)/parts/initcfg $(outdir)/root/lib/system/
	cp $(outdir)/parts/shell $(outdir)/root/bin/
	cp $(outdir)/parts/ui $(outdir)/root/lib/system/
	cp $(outdir)/parts/coreutils/* $(outdir)/root/bin/
# Core utils
coreutils: pwuc $(outdir)/parts
	mkdir -p $(outdir)/parts/coreutils
	cd userspace/coreutils && ./build.sh && mv out/* $(outdir)/parts/coreutils/
# UI
ui: pwuc $(outdir)/parts shell
	cd userspace/ui && pwuc main.pwsl -o $(outdir)/parts/ui
# Shell
shell: pwuc $(outdir)/parts
	cd userspace/shell && pwuc main.pwsl -o $(outdir)/parts/shell
# User setup service
usrsetup: pwuc $(outdir)/parts
	cd userspace/usrsetup && pwuc usrsetup.pwsle -o $(outdir)/parts/usrsetup && pwuc initcfg.pwsle -o $(outdir)/parts/initcfg
# Init system
init: pwuc $(outdir)/parts
	cd userspace/init && pwuc main.pwsl -o $(outdir)/parts/init
# Boot fs files
bootfs_files: $(outdir)/parts lbl kernel
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
