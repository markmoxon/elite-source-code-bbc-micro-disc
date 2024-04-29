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

IF _SRAM_DISC

 PUTFILE "1-source-files/boot-files/$.MENUEC.bin", "MENU", &FF1900, &FF8023
 PUTFILE "1-source-files/boot-files/$.SCREEN.bin", "ELTBS", &007800, &007BE8
 PUTFILE "3-assembled-output/ELTROM.bin", "ELTBR", &003400, &003400
 PUTFILE "3-assembled-output/MNUCODE.bin", "ELTBM", &007400, &00743B
 PUTFILE "3-assembled-output/sELITE4.bin", "ELTBI", &001900, &00197B
 PUTFILE "3-assembled-output/sD.CODE.bin", "ELTBD", &0012E3, &0012E3
 PUTFILE "3-assembled-output/sT.CODE.bin", "ELTBT", &0012E3, &0012E3

ELIF _STH_DISC OR _IB_DISC

 PUTFILE "3-assembled-output/ELITE4.bin", "ELTAI", &001900, &00197B
 PUTFILE "3-assembled-output/D.CODE.bin", "ELTAD", &0012E3, &0012E3
 PUTFILE "3-assembled-output/T.CODE.bin", "ELTAT", &0012E3, &0012E3
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

ENDIF

 PUTFILE "3-assembled-output/FixPAGE.bin", "FixPAGE", &007400, &007400

 PUTFILE "3-assembled-output/README.txt", "README", &FFFFFF, &FFFFFF
