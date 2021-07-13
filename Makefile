outdir = ${OUT}
# Final target - media code
#media: out/rootfs.img
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
# PowerSlash compiler
pwc: build/pwc/pwc.c
	mkdir -p build/bin
	gcc build/pwc/pwc.c -o build/bin/pwc
# Clean
clean:
	rm -rf build/bin
	rm -rf $(outdir)/*
