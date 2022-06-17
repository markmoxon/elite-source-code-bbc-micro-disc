\ ******************************************************************************
\
\ DISC ELITE README
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
\ This source file produces the following binary file:
\
\   * README.txt
\
\ ******************************************************************************

INCLUDE "1-source-files/main-sources/elite-header.h.asm"

_IB_DISC                = (_VARIANT = 1)
_STH_DISC               = (_VARIANT = 2)

.readme

 EQUB 10, 13
 EQUS "---------------------------------------"
 EQUB 10, 13
 EQUS "Acornsoft Elite"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "Version: BBC Micro disc"
 EQUB 10, 13

IF _IB_DISC

 EQUS "Variant: Ian Bell's game disc"
 EQUB 10, 13
 EQUS "Product: Acornsoft SNG38"
 EQUB 10, 13

ELIF _STH_DISC

 EQUS "Variant: Stairway to Hell archive"
 EQUB 10, 13
 EQUS "Product: Acornsoft SNG38"
 EQUB 10, 13
 EQUS "         Acornsoft SNG47"
 EQUB 10, 13

ENDIF

 EQUB 10, 13
 EQUS "See www.bbcelite.com for details"
 EQUB 10, 13
 EQUS "---------------------------------------"
 EQUB 10, 13

SAVE "3-assembled-output/README.txt", readme, P%

