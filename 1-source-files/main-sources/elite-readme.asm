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

 INCLUDE "1-source-files/main-sources/elite-build-options.asm"

 _IB_DISC               = (_VARIANT = 1)
 _STH_DISC              = (_VARIANT = 2)

.readme

 EQUB 10, 13
 EQUS "---------------------------------------"
 EQUB 10, 13
 EQUS "Acornsoft Elite (compendium version)"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "For the BBC Micro with 16K sideways RAM"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "Contains the flicker-free ship drawing"
 EQUB 10, 13
 EQUS "routines from the BBC Master version,"
 EQUB 10, 13
 EQUS "backported by Mark Moxon"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "Contains flicker-free planet drawing"
 EQUB 10, 13
 EQUS "routines by Mark Moxon"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "Based on the Acornsoft SNG38 release"
 EQUB 10, 13
 EQUS "of Elite by Ian Bell and David Braben"
 EQUB 10, 13
 EQUS "Copyright (c) Acornsoft 1984"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "Sound routines by Kieran Connell and"
 EQUB 10, 13
 EQUS "Simon Morris"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "Original music by Aidan Bell and Julie"
 EQUB 10, 13
 EQUS "Dunn (c) D. Braben and I. Bell 1985,"
 EQUB 10, 13
 EQUS "ported from the C64 by Negative Charge"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "Elite integration by Mark Moxon"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "Sideways RAM detection and loading"
 EQUB 10, 13
 EQUS "routines by Tricky and J.G.Harston"
 EQUB 10, 13
 EQUB 10, 13

 EQUS "See www.bbcelite.com for details"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "Build: ", TIME$("%F %T")
 EQUB 10, 13
 EQUS "---------------------------------------"
 EQUB 10, 13

 SAVE "3-assembled-output/README.txt", readme, P%

