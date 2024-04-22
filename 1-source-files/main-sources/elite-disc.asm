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
\ https://www.bbcelite.com/terminology
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

 _IB_DISC               = (_VARIANT = 1)
 _STH_DISC              = (_VARIANT = 2)
 _SRAM_DISC             = (_VARIANT = 3)

 PUTFILE "1-source-files/boot-files/$.MENUEC.bin", "MENU", &FF1900, &FF8023
 PUTFILE "1-source-files/boot-files/$.SCREEN.bin", "ELTBS", &007800, &007BE8
 PUTFILE "3-assembled-output/ELTROM.bin", "ELTBR", &003400, &003400
 PUTFILE "3-assembled-output/MNUCODE.bin", "ELTBM", &007400, &00743B
 PUTFILE "3-assembled-output/ELITE4.bin", "ELTBI", &001900, &00197B
 PUTFILE "3-assembled-output/D.CODE.bin", "ELTBD", &0012E3, &0012E3
 PUTFILE "3-assembled-output/T.CODE.bin", "ELTBT", &0012E3, &0012E3

 PUTFILE "3-assembled-output/README.txt", "README", &FFFFFF, &FFFFFF
