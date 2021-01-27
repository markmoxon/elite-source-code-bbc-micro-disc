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
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary file:
\
\   * output/ELITE3.bin
\
\ ******************************************************************************

INCLUDE "sources/elite-header.h.asm"

TRTB% = &04             \ TRTB%(1 0) points to the keyboard translation table

L0005   = $0005
L0012   = $0012
L0013   = $0013
L0038   = $0038
L0044   = $0044
L004C   = $004C
L004D   = $004D
L004E   = $004E
L004F   = $004F
L0050   = $0050
L0051   = $0051
L0070   = $0070
L0071   = $0071
L0072   = $0072
L0073   = $0073
L0074   = $0074
L0075   = $0075
L0076   = $0076
L0081   = $0081
L0082   = $0082

L0AC1   = $0AC1
L373D   = $373D
L4953   = $4953
L495C   = $495C
L499C   = $499C
L49D6   = $49D6
L4BBA   = $4BBA
L4BC3   = $4BC3
L4BCC   = $4BCC

VIA = $FE00
OSWRCH  = $FFEE
OSWORD  = $FFF1
OSBYTE  = $FFF4
OSCLI   = $FFF7

CODE% = &5700
LOAD% = &5700

ORG CODE%

 LDA #0                 \ We start by deleting the first loader from memory, so
                        \ it doesn't leave any clues for the crackers, so set A
                        \ to 0 so we can zero the memory

 TAY                    \ Set Y to 0 to act as an index in the following loop

.L5703

 STA &2F00,Y            \ Zero the Y-th byte of &2F00, which is where the first
                        \ loader was running before it loaded this one

 INY                    \ Increment the loop counter

 BNE L5703              \ Loop back until we have zeroed all 256 bytes from
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

.L5726

 BEQ L5726              \ If A = 0 then enter an infinite loop with L5726,
                        \ which hangs the computer

 JSR L5DE0

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
 BNE L574D              \ Tube, then jump to L574D

 LDA &5A00              \ &5A00 contains 0, so set A = 0

.L5748

 BEQ L5748              \ If A = 0 then enter an infinite loop with L5748,
                        \ which hangs the computer

 JMP &5A00              \ Otherwise jump to &5A00, which will execute a BRK to
                        \ terminate the program

.L574D

 LDA MPL                \ Set A = &A0, as MPL contains an LDY #0 instruction

 NOP
 NOP
 NOP

 JMP MPL                \ Jump to MPL to copy 512 bytes to &0400

 EQUB &00, &00, &00, &00, &00, &00, &00, &00

 NOP
 NOP

.L5760

 JMP L57A0

 NOP
 NOP
 NOP
 NOP

.command

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

 JMP &197B              \ Jump to the start of the ELITE3 loader code at &197B

 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00

.MESS1

 EQUS "LOAD Elite4"
 EQUB 13

 EQUB &00, &00, &00, &00

.L57A0

 LDA #129               \ Call OSBYTE with A = 129, X = &FF and Y = 2 to scan
 LDY #2                 \ the keyboard for &2FF centiseconds (7.67 seconds)
 LDX #&FF
 JSR OSBYTE

 LDA #15                \ Call OSBYTE with A = 129 and Y = 0 to flush the input
 LDY #0                 \ buffer
 JSR OSBYTE

 JMP command            \ Jump to command to load and run the next part of the
                        \ loader

 EQUB &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &32, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00

\ ******************************************************************************
\
\       Name: MPL
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Move 512 bytes from &5819 to &0400
\
\ ******************************************************************************

.MPL

 LDY #0                 \ Move &5819 onwards to &0400

 LDX #2                 \ 2 * 256 bytes

.MVBL

 LDA L5819,Y
 STA LOADER,Y

 INY

 BNE MVBL

 INC MVBL+2             \ High byte of LDA
 INC MVBL+5             \ High byte of STA

 DEX

 BNE MVBL

 JMP L5760

\ Gets copied from &5819 to &0400 (512 bytes)

.L5819

ORG &0400

.LOADER                \ Moved to &0400-&05FF from &5819-&5A18

 JSR L04B8

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

 JSR L0462

 DEC L0558
 BNE LOAD1

.LOAD2

 LDA L0559
 BEQ LOAD3

 ORA #&20
 STA L0511
 JSR L0462

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

 STX L0076
 LDA #&15
 LDX #&00
 JSR OSBYTE

 LDA #&C9
 LDX #&01
 LDY #&01
 JMP OSBYTE

.L0462

 JSR L04C7

 LDA #&28
 SEC
 SBC L0557
 STA L0545
 STA L050F
 LDA #&01
 JSR L04D5

 LDA L050A
 CMP #&0E
 BNE LOAD7

 LDA L050F
 STA L051A
 STA L0525
 STA L0530
 LDA #&04
 JSR L04D5

 LDA #&05
 JSR L04D5

 LDA #&06
 JSR L04D5

 JMP L04A0

.LOAD7

 LDA #&03
 JSR L04D5

.L04A0

 LDA L053B
 STA L0545
 LDA #&01
 JSR L04D5

 LDA L050A
 CLC
 ADC #&0A
 STA L050A
 INC L0557
 RTS

.L04B8

 JSR L04C7

 LDA L053B
 STA L054E
 LDA #&02
 JSR L04D5

 RTS

.L04C7

 LDA L0557
 LDX L055B
 BEQ LOAD8

 ASL A

.LOAD8

 STA L053B
 LDA #&00

.L04D5

 STA L0075

.LOAD9

 LDA L0075
 ASL A
 TAX
 LDA L04FA,X
 LDY L04FA+1,X
 TAX
 STX L0073
 STY L0074
 LDA #127
 JSR OSWORD

 LDA L0075
 CMP #&03
 BCC LOAD10

 LDY #&0A
 LDA (L0073),Y
 AND #&DF
 BNE LOAD9

.LOAD10

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

 EQUB &80 \ location &5973

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

 EQUB &00 \ location &5A00

 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00 \ 5A18

COPYBLOCK LOADER, P%, L5819

ORG L5819 + P% - LOADER

.L5A19

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
 EQUB &00, &00, &00, &00, &00, &00, &00, &E0
 EQUB &E0, &00, &00, &00, &00, &00, &00, &0E
 EQUB &0E, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &0E, &0E, &E0
 EQUB &E0, &00, &E0, &E0, &00, &00, &00, &EE
 EQUB &EE, &00, &E0, &E0, &00, &00, &00, &EE
 EQUB &EE, &00, &0E, &0E, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &E0, &E0, &E0
 EQUB &E0, &00, &00, &00, &00, &E0, &E0, &00
 EQUB &00, &00, &E0, &E0, &00, &E0, &E0, &E0
 EQUB &E0, &00, &E0, &E0, &00, &E0, &E0, &EE
 EQUB &EE, &00, &E0, &E0, &00, &E0, &E0, &EE
 EQUB &EE, &00, &EE, &EE, &00, &E0, &E0, &EE
 EQUB &EE, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &0E, &0E, &00, &0E, &0E, &0E
 EQUB &0E, &00, &0E, &0E, &00, &0E, &0E, &EE
 EQUB &EE, &00, &0E, &0E, &00, &0E, &0E, &EE
 EQUB &EE, &00, &EE, &EE, &00, &0E, &0E, &00
 EQUB &00, &00, &00, &00, &00, &EE, &EE, &EE
 EQUB &EE

 EQUB &00

 EQUB &00, &00, &00, &EE, &EE, &00, &00, &00
 EQUB &E0, &E0, &00, &EE, &EE, &E0, &E0, &00
 EQUB &E0, &E0, &00, &EE, &EE, &00, &00, &00
 EQUB &0E, &0E, &00, &EE, &EE, &0E, &0E, &00
 EQUB &0E, &0E, &00, &EE, &EE, &00, &00, &00
 EQUB &EE, &EE, &00, &EE, &EE, &E0, &E0, &00
 EQUB &EE, &EE, &00, &EE, &EE, &0E, &0E, &00
 EQUB &EE, &EE, &00, &EE, &EE, &EE, &EE, &00
 EQUB &EE, &EE, &00, &EE, &EE, &A0, &A1, &A2
 EQUB &E0, &A5, &A7, &AB, &B0, &B1, &B4, &B5
 EQUB &B7, &BF, &A3, &E8, &EA, &EB, &EF, &F0
 EQUB &F3, &F4, &F5, &F8, &FA, &FC, &FD, &FE
 EQUB &FF, &00, &00, &00, &18, &09, &03, &18
 EQUB &18, &07, &00, &16, &18, &14, &00, &18
 EQUB &18, &18, &07, &0E, &14, &00, &0E, &09
 EQUB &16, &18, &18, &07, &00, &1A, &1B, &09
 EQUB &00, &18, &18, &18, &18, &18, &18, &00
 EQUB &00, &17, &1B, &0A, &1B, &05, &06, &1B
 EQUB &0F, &0C, &0D, &11, &0A, &1B, &0D, &10
 EQUB &0A, &0F, &1B, &09, &0F, &0A, &1B, &08
 EQUB &06, &04, &0F, &1B, &1B, &1B, &00, &1B
 EQUB &0D, &0D, &0D, &1B, &0D, &00, &0E, &0C
 EQUB &10, &0A, &1B, &00, &00, &00, &0F, &0A
 EQUB &00, &0F, &0A, &1B, &18, &1A, &04, &0F
 EQUB &0C, &1B, &17, &0A, &06, &1B, &19, &07
 EQUB &1B, &1B, &1B, &1B, &0A, &1B, &1B, &1B
 EQUB &00, &1B, &00, &03, &1B, &19, &1A, &0A
 EQUB &1B, &07, &03, &18, &0F, &15, &00, &17
 EQUB &0A, &1B, &06, &19, &00, &0F, &0A, &10
 EQUB &1B, &0A, &12, &00, &10, &1B, &13, &13
 EQUB &13, &13, &08, &1B, &00, &00, &00, &1B
 EQUB &00, &1A, &0B, &00, &0F, &0A, &06, &1B
 EQUB &1B, &05, &02, &11, &1B, &0C, &01, &1B
 EQUB &00, &10, &15, &0F, &0A, &00, &11, &0A
 EQUB &11, &1B, &1B, &04, &11, &1B, &1B, &1B
 EQUB &04, &1B, &00, &00, &00, &1B, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &02, &0D, &00, &00, &00
 EQUB &00, &00, &00, &00, &00

.L5DE0

 LDA #&68               \ Poke the following routine into &0100 to &0108:
 STA &0100              \
 STA &0103              \   0100 : &68            PLA
 LDA #&85               \   0101 : &85 &71        STA &71
 STA &0101              \   0103 : &68            PLA
 STA &0104              \   0104 : &85 &72        STA &72
 LDX #&71               \   0106 : &6C &71 &00    JMP (&7100)
 STX &0107              \
 STX &0102              \ This routine pulls an address off the stack into a
 INX                    \ location in zero page, and then jumps to that address
 STX &0105
 LDA #&6C
 STA &0106
 LDA #&00
 STA &0108

 JSR &0100              \ Call the subroutine at &0100, so this first puts the
                        \ return address (the next location) on the stack, then
                        \ jumps to &0100, which jumps to the return address

 BRK
 
 LDA &71
 SEC
 SBC #&28
 STA L0071

 LDA L0072
 SBC #&00
 STA L0072
 LDY #&63

.L5E19

 LDA (L0071),Y
 CLC
 ADC L0071
 STA L0081
 INY
 LDA (L0071),Y
 ADC L0072
 STA L0082
 LDX #&00
 LDA (L0081,X)
 CLC
 ADC L0071
 STA (L0081,X)
 INC L0081
 BNE L5E36

 INC L0082

.L5E36

 LDA (L0081,X)
 ADC L0072
 STA (L0081,X)
 INY
 CPY #&7D
 BNE L5E19

 BEQ L5E5D

 EQUB &D0, &00, &E2, &00, &E9, &00, &37, &01
 EQUB &64, &01

 EQUB &6D, &01, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00

.L5E5D

 LDA L0071
 SEC
 SBC #&E0
 STA L0071
 LDA L0072
 SBC #&01
 STA L0072
 LDX #&00
 STX L0070
 LDY #&FF
 LDA #&81
 JSR OSBYTE

 CPX #&01
 BNE L5E9A

 DEC L0070
 LDY #&00

.L5E7D

 LDX #&07
 LDA #&17
 JSR OSWRCH

 TYA
 LSR A
 LSR A
 LSR A
 ORA #&E0
 JSR OSWRCH

.L5E8D

 LDA (L0071),Y
 JSR OSWRCH

 INY
 DEX
 BPL L5E8D

 CPY #&E0
 BNE L5E7D

.L5E9A

 LDA L0071
 CLC
 ADC #&E0
 STA L0071
 BCC L5EA5

 INC L0072

.L5EA5

 LDA #&16
 JSR OSWRCH

 LDA #&07
 JSR OSWRCH

 JSR &01B7

 EQUB &17, &00, &0A, &20, &00, &00, &00, &00
 EQUB &00, &00

 EQUB &EA, &A9, &91, &85, &76, &20, &63, &01
 EQUB &24, &70, &30, &4E, &20, &B7, &01, &1C
 EQUB &0D, &0D, &19, &0A, &0C, &0A, &87, &8D
 EQUB &45, &20, &4C, &20, &49, &20, &54, &20
 EQUB &45, &8C, &92, &87, &8D, &45, &20, &4C
 EQUB &20, &49, &20, &54, &20, &45, &EA, &60
 EQUB &20, &20, &20, &20, &20, &20, &8C, &92
 EQUB &87, &8D, &20, &20, &20, &20, &20, &20
 EQUB &20, &20, &20, &20, &20, &20, &20, &20
 EQUB &20, &20, &20, &20, &20, &20, &20, &20
 EQUB &20, &20, &20, &20, &20, &20, &20, &20
 EQUB &EA, &60, &20, &B7, &01, &1C, &0D, &0C
 EQUB &19, &0A, &0C, &1A, &1F, &0F, &0B, &45
 EQUB &20, &4C, &20, &49, &20, &54, &20, &45
 EQUB &EA, &60, &20, &20, &20, &20, &20, &20
 EQUB &20, &20, &20, &20, &20, &20, &20, &20
 EQUB &20, &20, &20, &20, &20, &EA, &60, &20
 EQUB &6C, &01, &20, &E7, &FF, &20, &E7, &FF
 EQUB &20, &72, &01, &20, &E7, &FF, &A0, &1C
 EQUB &A2, &26, &24, &70, &30, &0D, &A5, &76
 EQUB &20, &EE, &FF, &A9, &9A, &20, &EE, &FF
 EQUB &18, &90, &05, &A9, &20, &20, &EE, &FF
 EQUB &B1, &71, &24, &70, &30, &09, &84, &73
 EQUB &A8, &B1, &71, &A4, &73, &D0, &02, &09
 EQUB &E0, &20, &EE, &FF, &C8, &C0, &FF, &F0
 EQUB &0F, &CA, &D0, &E4, &24, &70, &10, &05
 EQUB &A9, &20, &20, &EE, &FF, &18, &90, &C0
 EQUB &E6, &76, &60, &68, &85, &74, &68, &85
 EQUB &75, &E6, &74, &D0, &02, &E6, &75, &A0
 EQUB &00, &B1, &74, &C9, &EA, &F0, &06, &20
 EQUB &EE, &FF, &18, &90, &EC, &6C

 EQUB &74

 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &FF, &00, &00
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
 EQUB &00, &00, &00, &00, &00, &00, &00

 EQUB &00

 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00

.L6100

 BNE L6106

 LDA L0050
 CMP L004E

.L6106

 BNE L6113

 LDA #&00
 STA L004E
 LDA #&00
 STA L004F
 JMP L4953

.L6113

 BIT L495C
 BPL L6119

 RTS

.L6119

 LDA L004F
 BNE L6120

 JSR L4BBA

.L6120

 LDA L004D
 BNE L6132

 JSR L4BC3

 LDA #&00
 STA L004E
 LDA #&00
 STA L004F
 JMP L4953

.L6132

 LDA L004D
 CMP L004F
 BCC L613E

 BNE L613E

 LDA L004C
 CMP L004E

.L613E

 BCC L6153

 LDA L004C
 STA L0012
 LDA L004D
 STA L0013
 JSR L4BC3

 LDA L0012
 STA L004E
 LDA L0013
 STA L004F

.L6153

 BIT L495C
 BMI L615B

 JSR L373D

.L615B

 RTS

 EQUB &00

.L615D

 LDA L004F
 BEQ L6172

 LDA L004F
 CMP L0051
 BCC L616D

 BNE L616D

 LDA L004E
 CMP L0050

.L616D

 BCS L6172

 JMP L49D6

.L6172

 LDA L004D
 BEQ L6187

 LDA L004D
 CMP L0051
 BCC L6182

 BNE L6182

 LDA L004C
 CMP L0050

.L6182

 BCS L6187

 JMP L499C

.L6187

 RTS

 LDA L004D
 BEQ L61C2

 LDA L004D
 CMP L0051
 BCC L6198

 BNE L6198

 LDA L004C
 CMP L0050

.L6198

 BEQ L61C2

 BCC L61C2

 BIT L0AC1
 BEQ L61BB

 LDA L004F
 CMP L0051
 BCC L61AD

 BNE L61AD

 LDA L004E
 CMP L0050

.L61AD

 BEQ L61BA

 LDA L0050
 STA L004C
 LDA L0051
 STA L004D
 JSR L373D

.L61BA

 RTS

.L61BB

 JSR L4BCC

 JSR L373D

 RTS

.L61C2

 LDA L004F
 BEQ L61FB

 LDA L004F
 CMP L0051
 BCC L61D2

 BNE L61D2

 LDA L004E
 CMP L0050

.L61D2

 BEQ L61FB

 BCC L61FB

 BIT L0AC1
 BEQ L61F0

 LDA L004D
 CMP L0051
 BCC L61E7

 BNE L61E7

 LDA L004C
 CMP L0050

.L61E7

 BEQ L61EF

 JSR L4BBA

 JSR L373D

.L61EF

 RTS

.L61F0

 LDA L004E
 STA L0050
 LDA L004F
 STA L0051
 JSR L373D

.L61FB  

 RTS

 LDA L0044
 STA L004C

\ ******************************************************************************
\
\ Save output/ELITE2.bin
\
\ ******************************************************************************

PRINT "S.ELITE3 ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD%
SAVE "output/ELITE3.bin", CODE%, P%, LOAD%

