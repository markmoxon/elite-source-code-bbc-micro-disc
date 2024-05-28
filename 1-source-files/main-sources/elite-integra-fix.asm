\ ******************************************************************************
\
\ DISC ELITE INTEGRA FIX SOURCE
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
\ This source file produces the following binary file:
\
\   * Integra
\
\ ******************************************************************************

 ZP = &70

 CODE% = &4000

 ORG CODE%

.IntegraFix

 SEI                    \ Disable all interrupts

 LDA &FFB7              \ Set ZP(1 0) to the location stored in &FFB7-&FFB8,
 STA ZP                 \ which contains the address of the default vector table
 LDA &FFB8
 STA ZP+1

 LDY #&A                \ Set Y to &A so we reset vectors &020A to &0211 (BYTEV,
                        \ WORDV and WRCHV)

.prlp1

 LDA (ZP),Y             \ Copy the Y-th byte from the default vector table into
 STA &0200,Y            \ the vector table in &0200

 INY                    \ Increment the loop counter

 CPY #&12               \ Loop back for the next vector until we have done them
 BNE prlp1              \ all

 LDY #&2A               \ Set Y to &2A so we reset vectors &022A to &022F (INSV,
                        \ REMV and CNPV)

.prlp2

 LDA (ZP),Y             \ Copy the Y-th byte from the default vector table into
 STA &0200,Y            \ the vector table in &0200

 INY                    \ Increment the loop counter

 CPY #&30               \ Loop back for the next vector until we have done them
 BNE prlp2              \ all

 CLI                    \ Re-enable interrupts

 RTS                    \ Return from the subroutine

 SAVE "3-assembled-output/Integra.bin", CODE%, P%, CODE%
