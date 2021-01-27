BEEBASM?=beebasm
PYTHON?=python

.PHONY:build
build:
	echo _REMOVE_CHECKSUMS=TRUE > sources/elite-header.h.asm
	$(BEEBASM) -i sources/elite-loader1.asm -v > output/compile.txt
	$(BEEBASM) -i sources/elite-loader2.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-loader3.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-source-d.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-source-t.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-moa.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mob.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-moc.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mod.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-moe.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mof.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mog.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-moh.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-moi.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-moj.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mok.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mol.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mom.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mon.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-moo.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mop.asm -v >> output/compile.txt
	$(PYTHON) sources/elite-checksum.py -u
	$(BEEBASM) -i sources/elite-disc.asm -do elite-disc.ssd -boot ELITE2

.PHONY:encrypt
encrypt:
	echo _REMOVE_CHECKSUMS=FALSE > sources/elite-header.h.asm

	$(BEEBASM) -i sources/elite-loader1.asm -v > output/compile.txt
	$(BEEBASM) -i sources/elite-loader2.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-loader3.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-source-d.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-source-t.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-moa.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mob.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-moc.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mod.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-moe.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mof.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mog.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-moh.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-moi.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-moj.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mok.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mol.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mom.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mon.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-moo.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-mop.asm -v >> output/compile.txt
	$(PYTHON) sources/elite-checksum.py
	$(BEEBASM) -i sources/elite-disc.asm -do elite-disc.ssd -boot ELITE2

.PHONY:verify
verify:
	@$(PYTHON) sources/crc32.py extracted output
