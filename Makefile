BEEBASM?=beebasm
PYTHON?=python

# A make command with no arguments will build the Stairway to Hell variant
# with encrypted binaries, checksums enabled, the standard commander and
# crc32 verification of the game binaries
#
# Optional arguments for the make command are:
#
#   variant=<release>   Build the specified variant:
#
#                         sth (default)
#                         ib-disc
#
#   commander=max       Start with a maxed-out commander
#
#   encrypt=no          Disable encryption and checksum routines
#
#   match=no            Do not attempt to match the original game binaries
#                       (i.e. omit workspace noise)
#
#   verify=no           Disable crc32 verification of the game binaries
#
# So, for example:
#
#   make variant=ib-disc commander=max encrypt=no match=no verify=no
#
# will build an unencrypted Ian Bell disc variant with a maxed-out commander,
# no workspace noise and no crc32 verification

ifeq ($(commander), max)
  max-commander=TRUE
else
  max-commander=FALSE
endif

ifeq ($(encrypt), no)
  unencrypt=-u
  remove-checksums=TRUE
else
  unencrypt=
  remove-checksums=FALSE
endif

ifeq ($(match), no)
  match-original-binaries=FALSE
else
  match-original-binaries=TRUE
endif

ifeq ($(variant), ib-disc)
  variant-number=1
  folder=/ib-disc
  suffix=-bbc-master-ib-disc
else
  variant-number=2
  folder=/sth
  suffix=-bbc-master-sth
endif

.PHONY:all
all:
	echo _VERSION=2 > 1-source-files/main-sources/elite-build-options.asm
	echo _VARIANT=$(variant-number) >> 1-source-files/main-sources/elite-build-options.asm
	echo _REMOVE_CHECKSUMS=$(remove-checksums) >> 1-source-files/main-sources/elite-build-options.asm
	echo _MATCH_ORIGINAL_BINARIES=$(match-original-binaries) >> 1-source-files/main-sources/elite-build-options.asm
	echo _MAX_COMMANDER=$(max-commander) >> 1-source-files/main-sources/elite-build-options.asm
	$(BEEBASM) -i 1-source-files/main-sources/elite-text-tokens.asm -v > 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-missile.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-loader1.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-loader2.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-loader3.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-source-flight.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-source-docked.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-ships-a.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-ships-b.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-ships-c.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-ships-d.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-ships-e.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-ships-f.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-ships-g.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-ships-h.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-ships-i.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-ships-j.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-ships-k.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-ships-l.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-ships-m.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-ships-n.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-ships-o.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-ships-p.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-readme.asm -v >> 3-assembled-output/compile.txt
	$(PYTHON) 2-build-files/elite-checksum.py $(unencrypt) -rel$(variant-number)
	$(BEEBASM) -i 1-source-files/main-sources/elite-disc.asm -do 5-compiled-game-discs/elite-disc$(suffix).ssd -boot ELITE2 -title "E L I T E"
ifneq ($(verify), no)
	@$(PYTHON) 2-build-files/crc32.py 4-reference-binaries$(folder) 3-assembled-output
endif

.PHONY:b2
b2:
	curl -G "http://localhost:48075/reset/b2"
	curl -H "Content-Type:application/binary" --upload-file "5-compiled-game-discs/elite-disc$(suffix).ssd" "http://localhost:48075/run/b2?name=elite-disc$(suffix).ssd"
