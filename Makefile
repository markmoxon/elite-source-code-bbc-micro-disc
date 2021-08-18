BEEBASM?=beebasm
PYTHON?=python

# You can set the release that gets built by adding 'release=<rel>' to
# the make command, where <rel> is one of:
#
#   ib-disc
#   sth
#
# So, for example:
#
#   make encrypt verify release=ib-disc
#
# will build the version from the game disc on Ian Bell's site. If you omit
# the release parameter, it will build the Stairway to Hell version.

ifeq ($(release), ib-disc)
  rel-disc=1
  folder-disc=/ib-disc
  suffix-disc=-ib-disc
else
  rel-disc=2
  folder-disc=/sth
  suffix-disc=-sth
endif

.PHONY:build
build:
	echo _VERSION=2 > sources/elite-header.h.asm
	echo _RELEASE=$(rel-disc) >> sources/elite-header.h.asm
	echo _REMOVE_CHECKSUMS=TRUE >> sources/elite-header.h.asm
	echo _MATCH_EXTRACTED_BINARIES=FALSE >> sources/elite-header.h.asm
	$(BEEBASM) -i sources/elite-text-tokens.asm -v > output/compile.txt
	$(BEEBASM) -i sources/elite-missile.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-loader1.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-loader2.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-loader3.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-source-flight.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-source-docked.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-a.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-b.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-c.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-d.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-e.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-f.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-g.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-h.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-i.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-j.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-k.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-l.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-m.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-n.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-o.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-p.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-readme.asm -v >> output/compile.txt
	$(PYTHON) sources/elite-checksum.py -u
	$(BEEBASM) -i sources/elite-disc.asm -do elite-disc-flicker-free$(suffix-disc).ssd -boot ELITE2 -title "E L I T E"

.PHONY:encrypt
encrypt:
	echo _VERSION=2 > sources/elite-header.h.asm
	echo _RELEASE=$(rel-disc) >> sources/elite-header.h.asm
	echo _REMOVE_CHECKSUMS=FALSE >> sources/elite-header.h.asm
	echo _MATCH_EXTRACTED_BINARIES=TRUE >> sources/elite-header.h.asm
	$(BEEBASM) -i sources/elite-text-tokens.asm -v > output/compile.txt
	$(BEEBASM) -i sources/elite-missile.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-loader1.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-loader2.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-loader3.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-source-flight.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-source-docked.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-a.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-b.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-c.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-d.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-e.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-f.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-g.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-h.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-i.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-j.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-k.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-l.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-m.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-n.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-o.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-ships-p.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-readme.asm -v >> output/compile.txt
	$(PYTHON) sources/elite-checksum.py
	$(BEEBASM) -i sources/elite-disc.asm -do elite-disc-flicker-free$(suffix-disc).ssd -boot ELITE2 -title "E L I T E"

.PHONY:verify
verify:
	@$(PYTHON) sources/crc32.py extracted$(folder-disc) output
