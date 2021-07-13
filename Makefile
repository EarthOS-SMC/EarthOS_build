outdir = ${OUT}
# Final target - media code
#media: out/rootfs.img
# Init system
init: pwuc $(outdir)/parts
	cd userspace/init && pwuc main.pwsl -o $(outdir)/parts/init
# Boot fs files
bootfs: $(outdir)/parts lbl kernel
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
