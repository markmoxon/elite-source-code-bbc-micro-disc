\ ******************************************************************************
\
\ DISC ELITE LOADER (PART 2) SOURCE
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
\ This source file produces the following binary file:
\
\   * ELITE3.bin
\
\ ******************************************************************************

INCLUDE "1-source-files/main-sources/elite-header.h.asm"

_IB_DISC                = (_RELEASE = 1)
_STH_DISC               = (_RELEASE = 2)

GUARD &7C00             \ Guard against assembling over screen memory

\ ******************************************************************************
\
\ Configuration variables
\
\ ******************************************************************************

VIA = &FE00             \ Memory-mapped space for accessing internal hardware,
                        \ such as the video ULA, 6845 CRTC and 6522 VIAs (also
                        \ known as SHEILA)

OSNEWL = &FFE7          \ The address for the OSNEWL routine
OSWRCH = &FFEE          \ The address for the OSWRCH routine
OSBYTE = &FFF4          \ The address for the OSBYTE routine
OSWORD = &FFF1          \ The address for the OSWORD routine
OSCLI = &FFF7           \ The address for the OSCLI vector

CODE% = &5700
LOAD% = &5700

\ ******************************************************************************
\
\       Name: ZP
\       Type: Workspace
\    Address: &0004 to &0005 and &0070 to &0082
\   Category: Workspaces
\    Summary: Important variables used by the loader
\
\ ******************************************************************************

ORG &0004

.TRTB%

 SKIP 2                 \ Contains the address of the keyboard translation
                        \ table, which is used to translate internal key
                        \ numbers to ASCII

ORG &0070

.S

 SKIP 1                 \ Temporary storage, used in a number of places

.ZP

 SKIP 2                 \ Stores addresses used for moving content around

.P

 SKIP 1                 \ Temporary storage, used in a number of places

.Q

 SKIP 1                 \ Temporary storage, used in a number of places

.R

 SKIP 1                 \ Temporary storage, used in a number of places

.T

 SKIP 1                 \ Temporary storage, used in a number of places

ORG &0081

.SC

 SKIP 1                 \ Screen address (low byte)
                        \
                        \ Elite draws on-screen by poking bytes directly into
                        \ screen memory, and SC(1 0) is typically set to the
                        \ address of the character block containing the pixel
                        \ we want to draw (see the deep dives on "Drawing
                        \ monochrome pixels in mode 4" and "Drawing colour
                        \ pixels in mode 5" for more details)

.SCH

 SKIP 1                 \ Screen address (high byte)

\ ******************************************************************************
\
\ ELITE LOADER
\
\ ******************************************************************************

ORG CODE%

\ ******************************************************************************
\
\       Name: Elite loader (Part 1 of 4)
\       Type: Subroutine
\   Category: Loader
\    Summary: Various copy protection checks, plus make sure there is no Tube
\
\ ******************************************************************************

.ENTRY

 LDA #0                 \ We start by deleting the first loader from memory, so
                        \ it doesn't leave any clues for the crackers, so set A
                        \ to 0 so we can zero the memory

 TAY                    \ Set Y to 0 to act as an index in the following loop

.LOOP1

 STA &2F00,Y            \ Zero the Y-th byte of &2F00, which is where the first
                        \ loader was running before it loaded this one

 INY                    \ Increment the loop counter

 BNE LOOP1              \ Loop back until we have zeroed all 256 bytes from
                        \ &2F00 to &2FFF, leaving Y = 0

 LDA #0                 \ Set &3FFF = 0
 STA &3FFF

 LDA #64                \ Set &7FFF = 64
 STA &7FFF

 EOR &3FFF              \ Set A = 64 EOR &3FFF
                        \       = 64 EOR 0
                        \       = 64

 CLC                    \ Set A = A + 64
 ADC #64                \       = 64 + 64
                        \       = 128

 PHA                    \ Push 128 on the stack

 TAX                    \ Set X = 128

 LDA #254               \ Call OSBYTE with A = 254, X = 128 and Y = 0 to set
 LDY #0                 \ the available RAM to 32K
 JSR OSBYTE

 PLA                    \ Pull 128 from the stack into A

 AND &5973              \ &5973 contains 128, so set A = 128 AND 128 = 128

IF _REMOVE_CHECKSUMS

 NOP                    \ If we have disabled checksums, ignore the result in A
 NOP

ELSE

 BEQ P%                 \ If A = 0 then enter an infinite loop, which hangs the
                        \ computer

ENDIF

 JSR PROT1              \ Call PROT1 to display the mode 7 loading screen and
                        \ perform lots of copy protection

 LDA #172               \ Call OSBYTE 172 to read the address of the MOS
 LDX #0                 \ keyboard translation table into (Y X)
 LDY #&FF
 JSR OSBYTE

 STX TRTB%              \ Store the address of the keyboard translation table in
 STY TRTB%+1            \ TRTB%(1 0)

 LDA #234               \ Call OSBYTE with A = 234, X = 0 and Y = &FF, which
 LDX #0                 \ detects whether Tube hardware is present, returning
 LDY #&FF               \ X = 0 (not present) or X = &FF (present)
 JSR OSBYTE

 CPX #&FF               \ If X is not &FF, i.e. we are not running this over the
 BNE notube             \ Tube, then jump to notube

 LDA &5A00              \ &5A00 contains 0, so set A = 0

 BEQ P%                 \ If A = 0 then enter an infinite loop, which hangs the
                        \ computer

 JMP &5A00              \ Otherwise we jump to &5A00, though I have no idea why,
                        \ as we will only get here if the code has been altered
                        \ in some way

.notube

 LDA MPL                \ Set A = &A0, as MPL contains an LDY #0 instruction

 NOP                    \ These bytes appear to be unused
 NOP
 NOP

 JMP MPL                \ Jump to MPL to copy 512 bytes to &0400 and jump to
                        \ ENTRY2

 SKIP 8                 \ These bytes appear to be unused
 NOP
 NOP

\ ******************************************************************************
\
\       Name: Elite loader (Part 2 of 4)
\       Type: Subroutine
\   Category: Loader
\    Summary: Jump straight to part 3, as the copy protection code has been
\             removed
\
\ ******************************************************************************

.ENTRY2

 JMP ENTRY3             \ Jump to the next part, as the copy protection code has
                        \ been removed

 NOP                    \ These bytes appear to be unused
 NOP
 NOP
 NOP

\ ******************************************************************************
\
\       Name: Elite loader (Part 4 of 4)
\       Type: Subroutine
\   Category: Loader
\    Summary: Load and run the ELITE4 loader
\
\ ******************************************************************************

.ENTRY4

 LDX #LO(MESS1)         \ Set (Y X) to point to MESS1 ("LOAD Elite4")
 LDY #HI(MESS1)

 JSR OSCLI              \ Call OSCLI to run the OS command in MESS1, which loads
                        \ the ELITE4 binary to its load address of &1900

 LDA #21                \ Call OSBYTE with A = 21 and X = 0 to flush the
 LDX #0                 \ keyboard buffer
 JSR OSBYTE

 LDA #201               \ Call OSBYTE with A = 201, X = 1 and Y = 1 to re-enable
 LDX #1                 \ the keyboard, which we disabled in the first loader
 LDY #1
 JSR OSBYTE

 JMP &197B              \ Jump to the start of the ELITE4 loader code at &197B

 SKIP 15                \ These bytes appear to be unused

\ ******************************************************************************
\
\       Name: MESS1
\       Type: Variable
\   Category: Loader
\    Summary: The OS command string for loading the ELITE4 loader
\
\ ******************************************************************************

.MESS1

 EQUS "LOAD Elite4"
 EQUB 13

 SKIP 4                 \ These bytes appear to be unused

\ ******************************************************************************
\
\       Name: Elite loader (Part 3 of 4)
\       Type: Subroutine
\   Category: Loader
\    Summary: Pause for a surprisingly long time (7.67 seconds) so people can
\             enjoy the Acornsoft loading screen
\
\ ******************************************************************************

.ENTRY3

 LDA #129               \ Call OSBYTE with A = 129, X = &FF and Y = 2 to scan
 LDY #2                 \ the keyboard for &2FF centiseconds (7.67 seconds)
 LDX #&FF
 JSR OSBYTE

 LDA #15                \ Call OSBYTE with A = 129 and Y = 0 to flush the input
 LDY #0                 \ buffer
 JSR OSBYTE

 JMP ENTRY4             \ Jump to ENTRY4 to load and run the next part of the
                        \ loader

 SKIP 63                \ These bytes appear to be unused
 EQUB &32
 SKIP 13

\ ******************************************************************************
\
\       Name: MPL
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Move two pages of memory from LOADcode to LOAD and jump to ENTRY2
\
\ ******************************************************************************

.MPL

 LDY #0                 \ Set Y = 0 to act as a byte counter

 LDX #2                 \ Set X = 2 to act as a page counter

.MVBL

 LDA LOADcode,Y         \ Copy the Y-th byte of LOADcode to the Y-th byte of
 STA LOAD,Y             \ LOAD (this instruction gets modified below, so this is
                        \ a single-use, self-modifying routine)

 INY                    \ Increment the byte counter

 BNE MVBL               \ Loop back to MVBL to copy the next byte until we have
                        \ copied a whole page

 INC MVBL+2             \ Increment the high byte of the LDA instruction above,
                        \ so it now points to the next page

 INC MVBL+5             \ Increment the high byte of the STA instruction above,
                        \ so it now points to the next page

 DEX                    \ Decrement the page counter in X

 BNE MVBL               \ Loop back to MVBL to copy the next page until we have
                        \ copied X pages

 JMP ENTRY2             \ Jump to ENTRY2 to continue the loading process

\ ******************************************************************************
\
\       Name: LOADcode
\       Type: Subroutine
\   Category: Copy protection
\    Summary: LOAD routine, bundled up in the loader so it can be moved to &0400
\             to be run
\
\ ******************************************************************************

.LOADcode

ORG &0400

\ ******************************************************************************
\
\       Name: LOAD
\       Type: Subroutine
\   Category: Copy protection
\    Summary: This code accesses the disc directly (not used in this version as
\             disc protection is disabled)
\
\ ******************************************************************************

.LOAD

 JSR LOAD10

 PLA
 STA L0509
 PLA
 STA L050A
 PLA
 CLC
 ADC L0551
 STA L0557
 PLA
 STA L0559
 PLA
 STA L0558
 BEQ LOAD2

.LOAD1

 JSR LOAD7

 DEC L0558
 BNE LOAD1

.LOAD2

 LDA L0559
 BEQ LOAD3

 ORA #&20
 STA L0511
 JSR LOAD7

.LOAD3

 LDA L051A
 BEQ LOAD5

 LDY #&00

.LOAD4

 LDA &0700,Y
 STA &1000,Y
 INY
 BNE LOAD4

.LOAD5

 LDX L055B
 BEQ LOAD6

 LDX #&52
 LDY #&05
 JSR OSCLI

 LDX #&02

.LOAD6

 STX &76                \ Store the drive number in &76 for retrieval in ELITE4
 LDA #&15
 LDX #&00
 JSR OSBYTE

 LDA #&C9
 LDX #&01
 LDY #&01
 JMP OSBYTE

.LOAD7

 JSR LOAD11

 LDA #&28
 SEC
 SBC L0557
 STA L0545
 STA L050F
 LDA #&01
 JSR LOAD13

 LDA L050A
 CMP #&0E
 BNE LOAD8

 LDA L050F
 STA L051A
 STA L0525
 STA L0530
 LDA #&04
 JSR LOAD13

 LDA #&05
 JSR LOAD13

 LDA #&06
 JSR LOAD13

 JMP LOAD9

.LOAD8

 LDA #&03
 JSR LOAD13

.LOAD9

 LDA L053B
 STA L0545
 LDA #&01
 JSR LOAD13

 LDA L050A
 CLC
 ADC #&0A
 STA L050A
 INC L0557
 RTS

.LOAD10

 JSR LOAD11

 LDA L053B
 STA L054E
 LDA #&02
 JSR LOAD13

 RTS

.LOAD11

 LDA L0557
 LDX L055B
 BEQ LOAD12

 ASL A

.LOAD12

 STA L053B
 LDA #&00

.LOAD13

 STA R

.LOAD14

 LDA R
 ASL A
 TAX
 LDA L04FA,X
 LDY L04FA+1,X
 TAX
 STX P
 STY P+1
 LDA #127
 JSR OSWORD

 LDA R
 CMP #&03
 BCC LOAD15

 LDY #&0A
 LDA (P),Y
 AND #&DF
 BNE LOAD14

.LOAD15

 RTS

.L04FA

 EQUB &34

 EQUB &05, &3D, &05, &47, &05, &08, &05, &13
 EQUB &05, &1E, &05, &29, &05, &FF

.L0509

 EQUB &00

.L050A

 EQUB &0A

 EQUB &FF, &FF, &03, &57

.L050F

 EQUB &00, &F6

.L0511

 EQUB &2A, &00
 EQUB &FF, &00, &0E, &FF, &FF, &03, &57

.L051A

 EQUB &00
 EQUB &F6, &22, &00, &FF, &00, &07, &FF, &FF
 EQUB &03, &57

.L0525

 EQUB &00, &F8, &21, &00, &FF, &00
 EQUB &11, &FF, &FF, &03, &57

.L0530

 EQUB &00, &F9, &27
 EQUB &00, &FF, &FF, &FF, &FF, &FF, &01, &69

.L053B

 EQUB &00, &00, &FF, &FF, &FF, &FF, &FF, &02
 EQUB &7A, &12

.L0545

 EQUB &00, &00, &FF, &00, &07, &FF
 EQUB &FF, &03, &5B

.L054E

 EQUB &00, &00, &0A

.L0551

 EQUB &00, &44
 EQUB &52, &2E, &32, &0D

.L0557

 EQUB &03

.L0558

 EQUB &00

.L0559

 EQUB &00

 EQUB &80               \ This is location &5973, as referenced by part 1

.L055B

 EQUB &FF, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00

 EQUB &00               \ This is location &5A00, as referenced by part 1

 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00

COPYBLOCK LOAD, P%, LOADcode

ORG LOADcode + P% - LOAD

 SKIP 487               \ These bytes appear to be unused

\ ******************************************************************************
\
\       Name: ECHAR
\       Type: Variable
\   Category: Loader
\    Summary: Character definitions for the Electron to mimic the graphics
\             characters of the BBC Micro's mode 7 teletext screen
\
\ ******************************************************************************

.ECHAR

 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &E0, &E0, &00, &00, &00, &00, &00, &00
 EQUB &0E, &0E, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &0E, &0E
 EQUB &E0, &E0, &00, &E0, &E0, &00, &00, &00
 EQUB &EE, &EE, &00, &E0, &E0, &00, &00, &00
 EQUB &EE, &EE, &00, &0E, &0E, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &E0, &E0
 EQUB &E0, &E0, &00, &00, &00, &00, &E0, &E0
 EQUB &00, &00, &00, &E0, &E0, &00, &E0, &E0
 EQUB &E0, &E0, &00, &E0, &E0, &00, &E0, &E0
 EQUB &EE, &EE, &00, &E0, &E0, &00, &E0, &E0
 EQUB &EE, &EE, &00, &EE, &EE, &00, &E0, &E0
 EQUB &EE, &EE, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &0E, &0E, &00, &0E, &0E
 EQUB &0E, &0E, &00, &0E, &0E, &00, &0E, &0E
 EQUB &EE, &EE, &00, &0E, &0E, &00, &0E, &0E
 EQUB &EE, &EE, &00, &EE, &EE, &00, &0E, &0E
 EQUB &00, &00, &00, &00, &00, &00, &EE, &EE
 EQUB &EE, &EE, &00, &00, &00, &00, &EE, &EE
 EQUB &00, &00, &00, &E0, &E0, &00, &EE, &EE
 EQUB &E0, &E0, &00, &E0, &E0, &00, &EE, &EE
 EQUB &00, &00, &00, &0E, &0E, &00, &EE, &EE
 EQUB &0E, &0E, &00, &0E, &0E, &00, &EE, &EE
 EQUB &00, &00, &00, &EE, &EE, &00, &EE, &EE
 EQUB &E0, &E0, &00, &EE, &EE, &00, &EE, &EE
 EQUB &0E, &0E, &00, &EE, &EE, &00, &EE, &EE
 EQUB &EE, &EE, &00, &EE, &EE, &00, &EE, &EE

\ ******************************************************************************
\
\       Name: LOGO
\       Type: Variable
\   Category: Loader
\    Summary: Tables containing the Acornsoft logo for the BBC Micro and Acorn
\             Electron
\
\ ******************************************************************************

.LOGO

 EQUB &A0, &A1          \ For the BBC Micro, the tables below consist of offsets
 EQUB &A2, &E0          \ into this top table, so the first three characters of
 EQUB &A5, &A7          \ the Acornsoft logo are &A0 (the &00-th entry in this
 EQUB &AB, &B0          \ table), then &FC (the &18-th entry in this table),
 EQUB &B1, &B4          \ then &B4 (the &09-th entry in this table) and so on
 EQUB &B5, &B7          \
 EQUB &BF, &A3          \ The Electron ignores this top table and just uses the
 EQUB &E8, &EA          \ values below, adding &E0 to get the number of the
 EQUB &EB, &EF          \ relevant user-defined character (so the first three
 EQUB &F0, &F3          \ characters are &E0, then &F8, then &E9 and so on)
 EQUB &F4, &F5          \
 EQUB &F8, &FA          \ The Acornsoft logo is made up of 5 rows with 38
 EQUB &FC, &FD          \ graphics characters on each row, which corresponds
 EQUB &FE, &FF          \ with the tables below

 EQUB &00, &00, &00, &18, &09, &03, &18, &18
 EQUB &07, &00, &16, &18, &14, &00, &18, &18
 EQUB &18, &07, &0E, &14, &00, &0E, &09, &16
 EQUB &18, &18, &07, &00, &1A, &1B, &09, &00
 EQUB &18, &18, &18, &18, &18, &18

 EQUB &00, &00, &17, &1B, &0A, &1B, &05, &06
 EQUB &1B, &0F, &0C, &0D, &11, &0A, &1B, &0D
 EQUB &10, &0A, &0F, &1B, &09, &0F, &0A, &1B
 EQUB &08, &06, &04, &0F, &1B, &1B, &1B, &00
 EQUB &1B, &0D, &0D, &0D, &1B, &0D

 EQUB &00, &0E, &0C, &10, &0A, &1B, &00, &00
 EQUB &00, &0F, &0A, &00, &0F, &0A, &1B, &18
 EQUB &1A, &04, &0F, &0C, &1B, &17, &0A, &06
 EQUB &1B, &19, &07, &1B, &1B, &1B, &1B, &0A
 EQUB &1B, &1B, &1B, &00, &1B, &00

 EQUB &03, &1B, &19, &1A, &0A, &1B, &07, &03
 EQUB &18, &0F, &15, &00, &17, &0A, &1B, &06
 EQUB &19, &00, &0F, &0A, &10, &1B, &0A, &12
 EQUB &00, &10, &1B, &13, &13, &13, &13, &08
 EQUB &1B, &00, &00, &00, &1B, &00

 EQUB &1A, &0B, &00, &0F, &0A, &06, &1B, &1B
 EQUB &05, &02, &11, &1B, &0C, &01, &1B, &00
 EQUB &10, &15, &0F, &0A, &00, &11, &0A, &11
 EQUB &1B, &1B, &04, &11, &1B, &1B, &1B, &04
 EQUB &1B, &00, &00, &00, &1B, &00

 SKIP 28                \ These bytes appear to be unused
 EQUB &02, &0D
 SKIP 8

\ ******************************************************************************
\
\       Name: PROT1
\       Type: Subroutine
\   Category: Loader
\    Summary: Various copy protection shenanigans in preparation for showing
\             the Acornspft loading screen
\
\ ******************************************************************************

.PROT1

 LDA #&68               \ Poke the following routine into &0100 to &0108:
 STA &0100              \
 STA &0103              \   0100 : &68            PLA
 LDA #&85               \   0101 : &85 &71        STA ZP
 STA &0101              \   0103 : &68            PLA
 STA &0104              \   0104 : &85 &72        STA ZP+1
 LDX #&71               \   0106 : &6C &71 &00    JMP (ZP)
 STX &0107              \
 STX &0102              \ This routine pulls an address off the stack into a
 INX                    \ location in zero page, and then jumps to that address
 STX &0105
 LDA #&6C
 STA &0106
 LDA #&00
 STA &0108

.do

 JSR &0100              \ Call the subroutine at &0100, which does the
 EQUB 0                 \ following:
                        \
                        \   * The JSR puts the address of the last byte of the
                        \     JSR instruction on the stack (i.e. the address of
                        \     the &01), pushing the high byte first
                        \
                        \   * It then jumps to &0100, which pulls the address
                        \     off the stack and puts it in ZP(1 0)
                        \
                        \   * The final instruction of the routine at &0100
                        \     jumps to the address in ZP(1 0), i.e. it jumps to
                        \     the &01 of the JSR instruction. The &01 byte is
                        \     followed by a &00 byte, and &01 &00 is the opcode
                        \     for ORA (&00,X), which doesn't do anything apart
                        \     from affect the value of the accumulator
                        \
                        \ In other words, this whole routine is a complicated
                        \ way of pointing ZP(1 0) to the &01 byte in the JSR
                        \ instruction above, i.e. to do + 2

 LDA ZP                 \ Set ZP(1 0) = ZP(1 0) - (2 + do - PROT1)
 SEC                    \             = do + 2 - 2 - do + PROT1
 SBC #(2 + do - PROT1)  \             = PROT1
 STA ZP
 LDA ZP+1
 SBC #&00
 STA ZP+1

 LDY #(TABLE - PROT1)   \ We're now going to loop through the words in TABLE, so
                        \ set Y as an index we can add to PROT1 (i.e. ZP) to
                        \ reach TABLE

.PROT1a

 LDA (ZP),Y             \ Set SC(1 0) = ZP(1 0) + Y-th word from TABLE
 CLC                    \
 ADC ZP                 \ so, for example, the first entry in TABLE does this:
 STA SC                 \
 INY                    \   SC(1 0) = ZP + first word from TABLE
 LDA (ZP),Y             \           = PROT1 + jsr1 + 1 - PROT1
 ADC ZP+1               \           = jsr1 + 1
 STA SC+1               \
                        \ which is the address of the destination adress in the
                        \ JSR instruction at jsr1

 LDX #0                 \ Add ZP(1 0), i.e. PROT1, to the word at SC(1 0),
 LDA (SC,X)             \ starting with the low bytes
 CLC
 ADC ZP
 STA (SC,X)

 INC SC                 \ And then adding the high bytes
 BNE P%+4               \
 INC SC+1               \ So, for example, the first entry in TABLE modifies the
 LDA (SC,X)             \ destination address of the JSR at jsr1 by adding PROT1
 ADC ZP+1               \ to it, so the address now points to prstr
 STA (SC,X)

 INY                    \ Increment Y to point to the next word in TABLE

 CPY #&7D               \ Loop until we have done them all
 BNE PROT1a

 BEQ LOADSCR            \ Jump to LOADSCR (this BEQ is effectively a JMP as we
                        \ didn't take the BNE branch)

.TABLE

 EQUW jsr1 + 1 - PROT1  \ Offsets within PROT1 of JSR destination addresses that
 EQUW jsr2 + 1 - PROT1  \ we modify with the code above
 EQUW jsr3 + 1 - PROT1
 EQUW jsr4 + 1 - PROT1
 EQUW jsr5 + 1 - PROT1
 EQUW jsr6 + 1 - PROT1

 SKIP 14                \ These bytes appear to be unused

\ ******************************************************************************
\
\       Name: LOADSCR
\       Type: Subroutine
\   Category: Loader
\    Summary: Show the mode 7 Acornsoft loading screen
\
\ ******************************************************************************

.LOADSCR

 LDA ZP                 \ Set ZP(1 0) = ZP(1 0) - (PROT1 - ECHAR)
 SEC                    \             = PROT1 - PROT1 + ECHAR
 SBC #LO(PROT1 - ECHAR) \             = ECHAR
 STA ZP
 LDA ZP+1
 SBC #HI(PROT1 - ECHAR)
 STA ZP+1

 LDX #0                 \ Set S = 0, to use as a flag denoting whether this is a
 STX S                  \ BBC Micro (0) or an Electron (&FF)

 LDY #&FF               \ Call OSBYTE with A = 129, X = 0 and Y = &FF to detect
 LDA #129               \ the machine type. This call is undocumented and is not
 JSR OSBYTE             \ the recommended way to determine the machine type
                        \ (OSBYTE 0 is the correct way), but this call returns
                        \ the following:
                        \
                        \   * X = Y = 0   if this is a BBC Micro with MOS 0.1
                        \   * X = Y = 1   if this is an Electron
                        \   * X = Y = &FF if this is a BBC Micro with MOS 1.20

 CPX #1                 \ If X is not 1, then this is not an Electron, so jump
 BNE bbc                \ to bbc

 DEC S                  \ Decrement S to &FF, to denote that this is an Acorn
                        \ Electron

                        \ We now define a character set consisting of "fake"
                        \ mode 7 graphics characters so the Electron can print
                        \ its own version of the Acornsoft loading screen
                        \ despite not having the BBC Micro's teletext mode 7
                        \
                        \ The comand to define a character is as follows:
                        \
                        \   VDU 23, n, b0, b1, b2, b3, b4, b5, b6, b7
                        \
                        \ where n is the character number and b0 through b7 are
                        \ the bytes for each pixel row in the character (there
                        \ are 8 rows of 8 pixels in a character)
                        \
                        \ So in the following, we perform the above command
                        \ for each character using the values from the ECHAR
                        \ table

 LDY #0                 \ Set Y to act as an index into the table at ECHAR

.eloop

 LDX #7                 \ Set a counter in X for the 8 bytes we need to print
                        \ from the table for each character definition (one byte
                        \ per pixel row)

 LDA #23                \ Print character 23 (i.e. VDU 23)
 JSR OSWRCH

 TYA                    \ We will increase Y by 8 for each character, so this
 LSR A                  \ sets A = Y / 8 to give the character number, starting
 LSR A                  \ from 0 and counting up by 1 for each new character
 LSR A

 ORA #&E0               \ This adds &E0 to A, so our new character set starts
                        \ with character number &E0, then character number &E1,
                        \ and so on

 JSR OSWRCH             \ Print the character number (so we have now done the
                        \ VDU 23, n part of the command)

.vloop

 LDA (ZP),Y             \ Print the Y-th byte from the ECHAR table (we set ZP to
 JSR OSWRCH             \ point to ECHAR above)

 INY                    \ Increment the index to point to the next byte in the
                        \ table

 DEX                    \ Decrement the byte counter

 BPL vloop              \ Loop back until we have printed 8 characters

 CPY #224               \ Loop back to do the next VDU 23 command until we have
 BNE eloop              \ printed out the whole table

.bbc

                        \ We now print the Acornsoft loading screen background
                        \ using mode 7 graphics (for the BBC Micro) or the
                        \ "fake" characters we just defined (for the Electron
                        \ version)

 LDA ZP                 \ Set ZP(1 0) = ZP(1 0) + LOGO - ECHAR
 CLC                    \             = ECHAR + LOGO - ECHAR
 ADC #(LOGO - ECHAR)    \             = LOGO
 STA ZP
 BCC P%+4
 INC ZP+1

 LDA #22                \ Switch to mode 7 using a VDU 22, 7 command
 JSR OSWRCH
 LDA #7
 JSR OSWRCH

.jsr1

 JSR prstr - PROT1      \ Call prstr to print the following characters,
                        \ restarting from the NOP instruction (this destination
                        \ address is modified by the code above that adds PROT1
                        \ to the address)

 EQUB 23, 0, 10, 32     \ Set 6845 register R10 = 32
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "cursor start" register, which sets the
                        \ cursor start line at 0, so it turns the cursor off

 NOP                    \ Marks the end of the VDU block

 LDA #145               \ Set T to teletext control code 145 (Red graphics) to
 STA T                  \ specify that the first Acornsoft is red

.jsr2

 JSR jsr5 - PROT1       \ Call jsr5, which calls jsr6, which calls LOGOS (this
                        \ destination address is modified by the code above that
                        \ adds PROT1 to the address)

 BIT S                  \ If bit 7 of S is set (this is an Electron), jump to
 BMI jsr4               \ jsr4

.jsr3

                        \ If we get here then this is a BBC Micro, so we can
                        \ show the game's name in the mode 7 screen

 JSR prstr - PROT1      \ Call prstr to print the following characters,
                        \ restarting from the NOP instruction (this destination
                        \ address is modified by the code above that adds PROT1
                        \ to the address)

 EQUB 28                \ Define a text window as follows:
 EQUB 13, 13, 25, 10    \
                        \   * Left = 13
                        \   * Right = 25
                        \   * Top = 10
                        \   * Bottom = 13
                        \
                        \ i.e. 3 rows high, 12 columns wide at (13, 10)

 EQUB 12                \ Clear the text area

 EQUB 10                \ Move the cursor down one row

 EQUB 135               \ Teletext control code 135 (Select white text)

 EQUB 141               \ Teletext control code 141 (Double height)

 EQUS "E L I T E"       \ The top half of the game's name

 EQUB 140               \ Teletext control code 140 (Turn off double height)

 EQUB 146               \ Teletext control code 146 (Select green graphics)

 EQUB 135               \ Teletext control code 135 (Select white text)

 EQUB 141               \ Teletext control code 141 (Double height)

 EQUS "E L I T E"       \ The top half of the game's name

 NOP                    \ Marks the end of the VDU block

 RTS                    \ Return from the PROT1 subroutine

 EQUS "      "          \ These bytes appear to be unused
 EQUB 140, 146
 EQUB 135, 141
 EQUS "      "
 EQUS "      "
 EQUS "      "
 EQUS "      "
 EQUS "      "
 NOP
 RTS

.jsr4

                        \ If we get here then this is an Electron

 JSR prstr - PROT1      \ Call prstr to print the following characters,
                        \ restarting from the NOP instruction (this destination
                        \ address is modified by the code above that adds PROT1
                        \ to the address)

 EQUB 28                \ Define a text window as follows:
 EQUB 13, 12, 25, 10    \
                        \   * Left = 13
                        \   * Right = 25
                        \   * Top = 10
                        \   * Bottom = 12
                        \
                        \ i.e. 2 rows high, 12 columns wide at (13, 10)

 EQUB 12                \ Clear the text area

 EQUB 26                \ Restore default windows

 EQUB 31, 15, 11        \ Move text cursor to 15, 11

 EQUS "E L I T E"       \ The name of the game

 NOP                    \ Marks the end of the VDU block

 RTS                    \ Return from the PROT1 subroutine

 EQUS "         "       \ These bytes appear to be unused
 EQUS "          "
 NOP
 RTS

.jsr5

 JSR jsr6 - PROT1       \ Call jsr6 (this destination address is modified by the
                        \ code above that adds PROT1 to the address). This calls
                        \ the LOGOS routine twice to print two Acornsoft logos,
                        \ with a newline between then

 JSR OSNEWL             \ Print two newlines
 JSR OSNEWL

.jsr6

 JSR LOGOS - PROT1      \ Call LOGOS (this destination address is modified by
                        \ the code above that adds PROT1 to the address). This
                        \ prints a third Acornsoft logo

 JSR OSNEWL             \ Print a newline

                        \ Fall through into LOGOS to print a fourth Acornsoft
                        \ logo and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: LOGOS
\       Type: Subroutine
\   Category: Loader
\    Summary: Print a large Acornsoft logo as part of the loading screen
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   T                   The logo colour as a teletext control code for graphics
\                       colour
\
\   ZP(1 0)             The address of the Acornsoft logo character table at
\                       LOGO
\
\ ******************************************************************************

.LOGOS

 LDY #28                \ Set Y = 28 as an index to the first row of logo
                        \ characters in the table at LOGO, after the 28 bytes of
                        \ lookup data in the first part of the table

.aloop

 LDX #38                \ Each row of the Acornsoft logo consists of 38 teletext
                        \ graphics characters, so set a counter in X to count
                        \ through the characters

 BIT S                  \ If bit 7 of S is set (this is an Electron), jump to
 BMI eskip1             \ eskip1 to skip the teletext colour codes (as the
                        \ Electron loading screen is monochrome)

 LDA T                  \ Print the character in T, which starts with teletext
 JSR OSWRCH             \ control code 145 (Red graphics) and increments through
                        \ the colours, so this sets the correct colour for the
                        \ current Acornsoft logo

 LDA #154               \ Print teletext control code 154 (Separated graphics)
 JSR OSWRCH

 CLC                    \ Skip the next two instructions
 BCC P%+7

.eskip1

 LDA #' '               \ Print a space (on the Electron only)
 JSR OSWRCH

.cloop

 LDA (ZP),Y             \ Fetch the Y-th character from ZP into A, so A contains
                        \ the next byte from LOGO, which is the user-defined
                        \ character we want to print (in the case of the
                        \ Electron), or the index into the first section of the
                        \ LOGO table for the teletext graphics character we want
                        \ to print (in the case of the BBC Micro)

 BIT S                  \ If bit 7 of S is set (this is an Electron), jump to
 BMI eskip2             \ eskip2

 STY P                  \ Store Y so we can retrieve it below

 TAY                    \ This is a BBC Micro, so the number in A is the index
 LDA (ZP),Y             \ into the first section of the LOGO table for the
                        \ teletext graphics character we want to print, so we
                        \ now fetch that character

 LDY P                  \ Retrieve the value of Y we stored above

 BNE P%+4               \ Skip the next instruction (this BNE is effectively a
                        \ JMP as Y is never zero)

.eskip2

 ORA #&E0               \ Add &E0 to the character number (on the Electron only)

 JSR OSWRCH             \ Print the character in A

 INY                    \ Increment Y to point to the next byte in the table

 CPY #255               \ If Y = 255 then we are done printing all 5 rows of the
 BEQ adone              \ logo, so jump to adone to finish off

 DEX                    \ Otherwise decrement the character counter in X

 BNE cloop              \ Loop back to print the next character until we have
                        \ done all 38 in this row

 BIT S                  \ If bit 7 of S is clear (this is a BBC Micro), skip the
 BPL P%+7               \ next two instructions

 LDA #' '               \ Print a space (on the Electron only)
 JSR OSWRCH

 CLC                    \ Jump back to aloop to print the next row in the logo
 BCC aloop

.adone

 INC T                  \ Increment the colour in T, which started with teletext
                        \ control code 145 (Red graphics) and increments through
                        \ 146 (green), 147 (yellow) and 148 (blue) with each new
                        \ call to the LOGOS routine

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: prstr
\       Type: Subroutine
\   Category: Loader
\    Summary: Print the NOP-terminated string immediately following the JSR
\             instruction that called the routine
\
\ ******************************************************************************

.prstr

 PLA                    \ We call prstr with a JSR, so pull the return address
 STA Q                  \ off the stack into Q(1 0), which actually points to
 PLA                    \ the last byte of the JSR prstr instruction
 STA Q+1

.p1

 INC Q                  \ Increment Q(1 0) to point to the next byte (so the
 BNE P%+4               \ first time we call prstr, Q points to the first byte
 INC Q+1                \ of the string we want to print)

 LDY #0                 \ Fetch the byte at Q(1 0) into A
 LDA (Q),Y

 CMP #&EA               \ If we just fetched a NOP instruction (opcode &EA),
 BEQ p2                 \ then we have reached the end of the string, so jump to
                        \ p2 to return from the subroutine

 JSR OSWRCH             \ Print the byte we just fetched

 CLC                    \ Loop back to p1 to fetch the next byte to print
 BCC p1

.p2

 JMP (Q)                \ Jump to the address in Q(1 0) - i.e. to the NOP that
                        \ we just fetched, so execution continues from the end
                        \ of the string we just printed

\ ******************************************************************************
\
\       Name: Unused copy protection routine
\       Type: Subroutine
\   Category: Copy protection
\    Summary: This code doesn't appear to be run in this version
\
\ ******************************************************************************

 SKIP 76                \ These bytes appear to be unused
 EQUB &FF
 SKIP 255

 BNE LABEL1

 LDA &50
 CMP &4E

.LABEL1

 BNE LABEL2

 LDA #&00
 STA &4E
 LDA #&00
 STA &4F
 JMP &4953

.LABEL2

 BIT &495C
 BPL LABEL3

 RTS

.LABEL3

 LDA &4F
 BNE LABEL4

 JSR &4BBA

.LABEL4

 LDA &4D
 BNE LABEL5

 JSR &4BC3

 LDA #&00
 STA &4E
 LDA #&00
 STA &4F
 JMP &4953

.LABEL5

 LDA &4D
 CMP &4F
 BCC LABEL6

 BNE LABEL6

 LDA &4C
 CMP &4E

.LABEL6

 BCC LABEL7

 LDA &4C
 STA &12
 LDA &4D
 STA &13
 JSR &4BC3

 LDA &12
 STA &4E
 LDA &13
 STA &4F

.LABEL7

 BIT &495C
 BMI LABEL8

 JSR &373D

.LABEL8

 RTS

 SKIP 1

.LABEL9

 LDA &4F
 BEQ LABEL11

 LDA &4F
 CMP &51
 BCC LABEL10

 BNE LABEL10

 LDA &4E
 CMP &50

.LABEL10

 BCS LABEL11

 JMP &49D6

.LABEL11

 LDA &4D
 BEQ LABEL13

 LDA &4D
 CMP &51
 BCC LABEL12

 BNE LABEL12

 LDA &4C
 CMP &50

.LABEL12

 BCS LABEL13

 JMP &499C

.LABEL13

 RTS

 LDA &4D
 BEQ LABEL18

 LDA &4D
 CMP &51
 BCC LABEL14

 BNE LABEL14

 LDA &4C
 CMP &50

.LABEL14

 BEQ LABEL18

 BCC LABEL18

 BIT &0AC1
 BEQ LABEL17

 LDA &4F
 CMP &51
 BCC LABEL15

 BNE LABEL15

 LDA &4E
 CMP &50

.LABEL15

 BEQ LABEL16

 LDA &50
 STA &4C
 LDA &51
 STA &4D
 JSR &373D

.LABEL16

 RTS

.LABEL17

 JSR &4BCC

 JSR &373D

 RTS

.LABEL18

 LDA &4F
 BEQ LABEL23

 LDA &4F
 CMP &51
 BCC LABEL19

 BNE LABEL19

 LDA &4E
 CMP &50

.LABEL19

 BEQ LABEL23

 BCC LABEL23

 BIT &0AC1
 BEQ LABEL22

 LDA &4D
 CMP &51
 BCC LABEL20

 BNE LABEL20

 LDA &4C
 CMP &50

.LABEL20

 BEQ LABEL21

 JSR &4BBA

 JSR &373D

.LABEL21

 RTS

.LABEL22

 LDA &4E
 STA &50
 LDA &4F
 STA &51
 JSR &373D

.LABEL23

 RTS

 LDA &44
 STA &4C

\ ******************************************************************************
\
\ Save ELITE2.bin
\
\ ******************************************************************************

PRINT "S.ELITE3 ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD%
SAVE "3-assembled-output/ELITE3.bin", CODE%, P%, LOAD%

