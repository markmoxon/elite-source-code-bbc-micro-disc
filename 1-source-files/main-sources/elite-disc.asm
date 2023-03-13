\ ******************************************************************************
\
\ DISC ELITE DISC IMAGE SCRIPT
\
\ Elite was written by Ian Bell and David Braben and is copyright Acornsoft 1984
\
\ The code on this site has been reconstructed from a disassembly of the version
\ released on Ian Bell's personal website at http://www.elitehomepage.org/
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ The terminology and notations used in this commentary are explained at
\ https://www.bbcelite.com/about_site/terminology_used_in_this_commentary.html
\
\ The deep dive articles referred to in this commentary can be found at
\ https://www.bbcelite.com/deep_dives
\
\ ------------------------------------------------------------------------------
\
\ This source file produces one of the following SSD disc images, depending on
\ which release is being built:
\
\   * elite-disc-sth.ssd
\   * elite-disc-ib-disc.ssd
\
\ This can be loaded into an emulator or a real BBC Micro.
\
\ ******************************************************************************

INCLUDE "1-source-files/main-sources/elite-build-options.asm"

PUTFILE "3-assembled-output/ELITE2.bin", "ELITE2", &FF2F00, &FF2F23
PUTFILE "3-assembled-output/ELITE3.bin", "ELITE3", &FF5700, &FF5700
PUTFILE "3-assembled-output/ELITE4.bin", "ELITE4", &FF1900, &FF197B

PUTFILE "3-assembled-output/D.CODE.bin", "D.CODE", &0011E3, &0011E3
PUTFILE "3-assembled-output/T.CODE.bin", "T.CODE", &0011E3, &0011E3

PUTFILE "3-assembled-output/D.MOA.bin", "D.MOA", &005600, &005600
PUTFILE "3-assembled-output/D.MOB.bin", "D.MOB", &005600, &005600
PUTFILE "3-assembled-output/D.MOC.bin", "D.MOC", &005600, &005600
PUTFILE "3-assembled-output/D.MOD.bin", "D.MOD", &005600, &005600
PUTFILE "3-assembled-output/D.MOE.bin", "D.MOE", &005600, &005600
PUTFILE "3-assembled-output/D.MOF.bin", "D.MOF", &005600, &005600
PUTFILE "3-assembled-output/D.MOG.bin", "D.MOG", &005600, &005600
PUTFILE "3-assembled-output/D.MOH.bin", "D.MOH", &005600, &005600
PUTFILE "3-assembled-output/D.MOI.bin", "D.MOI", &005600, &005600
PUTFILE "3-assembled-output/D.MOJ.bin", "D.MOJ", &005600, &005600
PUTFILE "3-assembled-output/D.MOK.bin", "D.MOK", &005600, &005600
PUTFILE "3-assembled-output/D.MOL.bin", "D.MOL", &005600, &005600
PUTFILE "3-assembled-output/D.MOM.bin", "D.MOM", &005600, &005600
PUTFILE "3-assembled-output/D.MON.bin", "D.MON", &005600, &005600
PUTFILE "3-assembled-output/D.MOO.bin", "D.MOO", &005600, &005600
PUTFILE "3-assembled-output/D.MOP.bin", "D.MOP", &005600, &005600

PUTFILE "1-source-files/other-files/E.MAX.bin", "E.MAX", &000000, &000000

PUTFILE "3-assembled-output/README.txt", "README", &FFFFFF, &FFFFFF

PUTFILE "1-source-files/boot-files/$.!BOOT.bin", "!BOOT", &FFFFFF, &FFFFFF
PUTBASIC "1-source-files/music/load-music.bas", "ELITEM"
PUTFILE "1-source-files/music/elite-music-disc.rom", "MUSIC", &008000, &008000
PUTFILE "1-source-files/music/SRLoad.bin", "SRLOAD", &FF0900, &FF093D
