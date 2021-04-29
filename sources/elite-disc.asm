\ ******************************************************************************
\
\ DISC ELITE DISC IMAGE SCRIPT
\
\ Elite was written by Ian Bell and David Braben and is copyright Acornsoft 1984
\
\ The code on this site has been disassembled from the version released on Ian
\ Bell's personal website at http://www.elitehomepage.org/
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
\ This source file produces the following SSD disc image:
\
\   * elite-disc.ssd
\
\ This can be loaded into an emulator or a real BBC Micro.
\
\ ******************************************************************************

INCLUDE "sources/elite-header.h.asm"

PUTFILE "output/ELITE2.bin", "ELITE2", &2F00, &2F00
PUTFILE "output/ELITE3.bin", "ELITE3", &5700, &5700
PUTFILE "output/ELITE4.bin", "ELITE4", &1900, &197B

PUTFILE "output/D.CODE.bin", "D.CODE", &11E3, &11E3
PUTFILE "output/T.CODE.bin", "T.CODE", &11E3, &11E3

PUTFILE "output/D.MOA.bin", "D.MOA", &5600, &5600
PUTFILE "output/D.MOB.bin", "D.MOB", &5600, &5600
PUTFILE "output/D.MOC.bin", "D.MOC", &5600, &5600
PUTFILE "output/D.MOD.bin", "D.MOD", &5600, &5600
PUTFILE "output/D.MOE.bin", "D.MOE", &5600, &5600
PUTFILE "output/D.MOF.bin", "D.MOF", &5600, &5600
PUTFILE "output/D.MOG.bin", "D.MOG", &5600, &5600
PUTFILE "output/D.MOH.bin", "D.MOH", &5600, &5600
PUTFILE "output/D.MOI.bin", "D.MOI", &5600, &5600
PUTFILE "output/D.MOJ.bin", "D.MOJ", &5600, &5600
PUTFILE "output/D.MOK.bin", "D.MOK", &5600, &5600
PUTFILE "output/D.MOL.bin", "D.MOL", &5600, &5600
PUTFILE "output/D.MOM.bin", "D.MOM", &5600, &5600
PUTFILE "output/D.MON.bin", "D.MON", &5600, &5600
PUTFILE "output/D.MOO.bin", "D.MOO", &5600, &5600
PUTFILE "output/D.MOP.bin", "D.MOP", &5600, &5600
