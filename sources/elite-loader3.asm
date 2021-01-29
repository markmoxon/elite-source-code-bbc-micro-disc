\ ******************************************************************************
\
\ DISC ELITE LOADER (PART 3) SOURCE
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
\   * output/ELITE4.bin
\
\ ******************************************************************************

INCLUDE "sources/elite-header.h.asm"

NETV = &224             \ The NETV vector that we intercept as part of the copy
                        \ protection

IRQ1V = &204            \ The IRQ1V vector that we intercept to implement the
                        \ split-sceen mode

INDV2 = &0232

OSWRCH = &FFEE          \ The address for the OSWRCH routine
OSBYTE = &FFF4          \ The address for the OSBYTE routine
OSWORD = &FFF1          \ The address for the OSWORD routine
OSCLI = &FFF7           \ The address for the OSCLI vector

VIA = &FE00             \ Memory-mapped space for accessing internal hardware,
                        \ such as the video ULA, 6845 CRTC and 6522 VIAs (also
                        \ known as SHEILA)

N% = 67                 \ N% is set to the number of bytes in the VDU table, so
                        \ we can loop through them below

VEC = &7FFE             \ VEC is where we store the original value of the IRQ1
                        \ vector, and it matches the value in elite-source.asm

ZP = &70                \ Temporary storage, used all over the place

P = &72                 \ Temporary storage, used all over the place

Q = &73                 \ Temporary storage, used all over the place

YY = &74                \ Temporary storage, used when drawing Saturn

T = &75                 \ Temporary storage, used all over the place

SC = &76                \ Used to store the screen address while plotting pixels

BLPTR = &78             \ Gets set as part of the obfuscation code

CODE% = &1900           \ The address where this file (the third loader) loads
LOAD% = &1900

ORG CODE%

\ ******************************************************************************
\
\       Name: B%
\       Type: Variable
\   Category: Screen mode
\    Summary: VDU commands for setting the square mode 4 screen
\
\ ------------------------------------------------------------------------------
\
\ This block contains the bytes that get written by OSWRCH in part 2 to set up
\ the screen mode (this is equivalent to using the VDU statement in BASIC).
\
\ It defines the whole screen using a square, monochrome mode 4 configuration;
\ the mode 5 part for the dashboard is implemented in the IRQ1 routine.
\
\ The top part of Elite's screen mode is based on mode 4 but with the following
\ differences:
\
\   * 32 columns, 31 rows (256 x 248 pixels) rather than 40, 32
\
\   * The horizontal sync position is at character 45 rather than 49, which
\     pushes the screen to the right (which centres it as it's not as wide as
\     the normal screen modes)
\
\   * Screen memory goes from &6000 to &7EFF, which leaves another whole page
\     for code (i.e. 256 bytes) after the end of the screen. This is where the
\     Python ship blueprint slots in
\
\   * The text window is 1 row high and 13 columns wide, and is at (2, 16)
\
\   * There's a large, fast-blinking cursor
\
\ This almost-square mode 4 variant makes life a lot easier when drawing to the
\ screen, as there are 256 pixels on each row (or, to put it in screen memory
\ terms, there's one page of memory per row of pixels). For more details of the
\ screen mode, see the deep dive on "Drawing monochrome pixels in mode 4".
\
\ There is also an interrupt-driven routine that switches the bytes-per-pixel
\ setting from that of mode 4 to that of mode 5, when the raster reaches the
\ split between the space view and the dashboard. See the deep dive on "The
\ split-screen mode" for details.
\
\ ******************************************************************************

.B%

 EQUB 22, 4             \ Switch to screen mode 4

 EQUB 28                \ Define a text window as follows:
 EQUB 2, 17, 15, 16     \
                        \   * Left = 2
                        \   * Right = 15
                        \   * Top = 16
                        \   * Bottom = 17
                        \
                        \ i.e. 1 row high, 13 columns wide at (2, 16)

 EQUB 23, 0, 6, 31      \ Set 6845 register R6 = 31
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "vertical displayed" register, and sets
                        \ the number of displayed character rows to 31. For
                        \ comparison, this value is 32 for standard modes 4 and
                        \ 5, but we claw back the last row for storing code just
                        \ above the end of screen memory

 EQUB 23, 0, 12, &0C    \ Set 6845 register R12 = &0C and R13 = &00
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This sets 6845 registers (R12 R13) = &0C00 to point
 EQUB 23, 0, 13, &00    \ to the start of screen memory in terms of character
 EQUB 0, 0, 0           \ rows. There are 8 pixel lines in each character row,
 EQUB 0, 0, 0           \ so to get the actual address of the start of screen
                        \ memory, we multiply by 8:
                        \
                        \   &0C00 * 8 = &6000
                        \
                        \ So this sets the start of screen memory to &6000

 EQUB 23, 0, 1, 32      \ Set 6845 register R1 = 32
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "horizontal displayed" register, which
                        \ defines the number of character blocks per horizontal
                        \ character row. For comparison, this value is 40 for
                        \ modes 4 and 5, but our custom screen is not as wide at
                        \ only 32 character blocks across

 EQUB 23, 0, 2, 45      \ Set 6845 register R2 = 45
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "horizontal sync position" register, which
                        \ defines the position of the horizontal sync pulse on
                        \ the horizontal line in terms of character widths from
                        \ the left-hand side of the screen. For comparison this
                        \ is 49 for modes 4 and 5, but needs to be adjusted for
                        \ our custom screen's width

 EQUB 23, 0, 10, 32     \ Set 6845 register R10 = 32
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "cursor start" register, which sets the
                        \ cursor start line at 0 with a fast blink rate

 EQUB &01, &01, &00, &6F, &F8
 EQUB &04, &01, &08, &08, &FE, &00, &FF, &7E
 EQUB &2C, &02, &01, &0E, &EE, &FF, &2C, &20
 EQUB &32, &06, &01, &00, &FE, &78, &7E, &03
 EQUB &01, &01, &FF, &FD, &11, &20, &80, &01
 EQUB &00, &00, &FF, &01, &01, &04, &01, &04
 EQUB &F8, &2C, &04, &06, &08, &16, &00, &00
 EQUB &81, &7E, &00

.L197B

 JSR L1B72

 LDA #144
 LDX #255
 JSR OSB

 LDA #LO(B%)            \ Set the low byte of ZP(1 0) to point to the VDU code
 STA ZP                 \ table at B%

 LDA #HI(B%)            \ Set the high byte of ZP(1 0) to point to the VDU code
 STA ZP+1               \ table at B%

 LDY #0                 \ We are now going to send the 67 VDU bytes in the table
                        \ at B% to OSWRCH to set up the special mode 4 screen
                        \ that forms the basis for the split-screen mode

.LOOP

 LDA (ZP),Y             \ Pass the Y-th byte of the B% table to OSWRCH
 JSR OSWRCH

 INY                    \ Increment the loop counter

 CPY #N%                \ Loop back for the next byte until we have done them
 BNE LOOP               \ all (the number of bytes was set in N% above)

 JSR PLL1               \ Call PLL1 to draw Saturn

 LDA #16
 LDX #3
 JSR OSBYTE

 LDA #&60
 STA INDV2
 LDA #&02
 STA NETV+1
 LDA #&32
 STA NETV

 LDA #190
 LDX #8
 JSR OSB

 LDA #200
 LDX #0
 JSR OSB

 LDA #13
 LDX #0
 JSR OSB

 LDA #225
 LDX #128
 JSR OSB

 LDA #12
 LDX #0

.L19D2

 JSR OSB

 LDA #13
 LDX #2
 JSR OSB

 LDA #4
 LDX #1
 JSR OSB

 LDA #9
 LDX #0
 JSR OSB

 JSR L1CE2

 LDA #&00
 STA ZP
 LDA #&11
 STA ZP+1
 LDA #&62
 STA P
 LDA #&29
 STA P+1
 JSR MVPG

 LDA #&00
 STA ZP
 LDA #&78
 STA ZP+1
 LDA #&4B
 STA P
 LDA #&1D
 STA P+1
 LDX #&08
 JSR MVBL

 SEI
 LDA VIA+$44
 STA &0001
 LDA #&39
 STA VIA+$4E
 LDA #&7F
 STA VIA+&6E
 LDA IRQ1V
 STA VEC
 LDA IRQ1V+1
 STA VEC+1
 LDA #&4B
 STA IRQ1V
 LDA #&11
 STA IRQ1V+1
 LDA #&39
 STA VIA+&45
 CLI
 LDA #&00
 STA ZP
 LDA #&61
 STA ZP+1
 LDA #&62
 STA P
 LDA #&2B
 STA P+1
 JSR MVPG

 LDA #&63
 STA ZP+1
 LDA #&62
 STA P
 LDA #&2A
 STA P+1
 JSR MVPG

 LDA #&76
 STA ZP+1
 LDA #&62
 STA P
 LDA #&2C
 STA P+1
 JSR MVPG

 LDA #&00
 STA ZP
 LDA #&04
 STA ZP+1
 LDA #&4B
 STA P
 LDA #&25
 STA P+1
 LDX #&04
 JSR MVBL

 LDX #35

.L1A89

 LDA CATDISC,X
 STA CATD,X
 DEX
 BPL L1A89

 LDA SC
 STA CATBLOCK

 LDX #&43
 LDY #&19
 LDA #8
 JSR OSWORD

 LDX #&51
 LDY #&19
 LDA #8
 JSR OSWORD

 LDX #&5F
 LDY #&19
 LDA #8
 JSR OSWORD

 LDX #&6D
 LDY #&19
 LDA #8
 JSR OSWORD

 LDX #&44
 LDY #&1D
 JSR OSCLI

 LDA #&00
 STA ZP
 LDA #&0B
 STA ZP+1
 LDA #&ED
 STA P
 LDA #&1A
 STA P+1

 LDY #&00

.L1AD4

 LDA (P),Y
 EOR #&18
 STA (ZP),Y
 DEY
 BNE L1AD4

 JMP &0B00

.L1AE0

 CLC
 LDY #&00

.L1AE3

 ADC PLL1,Y
 EOR L197B,Y
 DEY
 BNE L1AE3

 RTS

 EQUB &BA, &2F, &B8, &13, &38, &EF, &E7, &B1
 EQUB &F6, &95

 EQUB &1A, &1A, &B1, &09, &95, &1B, &1A, &B1
 EQUB &F1, &95, &16, &1A, &B1, &09, &95, &17
 EQUB &1A, &20, &B8, &18, &9C, &68, &BA, &09
 EQUB &92, &9E, &69, &69, &68, &90, &C8, &E1
 EQUB &F0, &F8, &4C, &88, &EC, &D5, &E7, &4D
 EQUB &C8, &E6, &54, &FE, &09, &54, &36, &4C
 EQUB &36, &5B, &57, &5C, &5D, &15, &5C, &77
 EQUB &7D, &6B, &38, &61, &77, &6D, &6A, &38
 EQUB &75, &77, &6C, &70, &7D, &6A, &38, &73
 EQUB &76, &77, &6F, &38, &61, &77, &6D, &38
 EQUB &7C, &77, &38, &6C, &70, &71, &6B, &27

\ Gets copied from &1B4F to &0D7A by loop at L1A89 (35 bytes),
\ is called by D and T to load from disc

.CATDISC

ORG &0D7A

.CATD

 DEC CATBLOCK+8            \ Decrement sector number from 1 to 0
 DEC CATBLOCK+2            \ Decrement load address from &0F00 to &0E00

 JSR CATL

 INC CATBLOCK+8            \ Increment sector number back to 1
 INC CATBLOCK+2            \ Increment load address back to &0F00

.CATL

 LDA #127
 LDX #LO(CATBLOCK)
 LDY #HI(CATBLOCK)
 JMP OSWORD

.CATBLOCK

 EQUB 0                 \ 0 = Drive = 0
 EQUD &00000F00         \ 1 = Data address = &0F00
 EQUB 3                 \ 5 = Number of parameters = 3
 EQUB &53               \ 6 = Command = &53 (read data)
 EQUB 0                 \ 7 = Track = 0
 EQUB 1                 \ 8 = Sector = 1
 EQUB %00100001         \ 9 = Load 1 sector of 256 bytes
 EQUB 0

COPYBLOCK CATD, P%, CATDISC

ORG CATDISC + P% - CATD

.L1B72

 LDA #&55
 LDX #&40

.L1B76

 JSR L1AE0

 DEX
 BPL L1B76

 STA RAND+2
 ORA #&00
 BPL L1B85

 LSR BLPTR

.L1B85

 JMP L1CCF

 EQUB &AC

\ ******************************************************************************
\
\       Name: PLL1
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Draw Saturn on the loading screen
\
\ ------------------------------------------------------------------------------
\
\ Part 1 (PLL1) x 1280 - planet
\
\   * Draw pixels at (x, y) where:
\
\     r1 = random number from 0 to 255
\     r2 = random number from 0 to 255
\     (r1^2 + r1^2) < 128^2
\
\     y = r2, squished into 64 to 191 by negation
\
\     x = SQRT(128^2 - (r1^2 + r1^2)) / 2
\
\ Part 2 (PLL2) x 477 - stars
\
\   * Draw pixels at (x, y) where:
\
\     y = random number from 0 to 255
\     y = random number from 0 to 255
\     (x^2 + y^2) div 256 > 17
\
\ Part 3 (PLL3) x 1280 - rings
\
\   * Draw pixels at (x, y) where:
\
\     r5 = random number from 0 to 255
\     r6 = random number from 0 to 255
\     r7 = r5, squashed into -32 to 31
\
\     32 <= (r5^2 + r6^2 + r7^2) / 256 <= 79
\     Draw 50% fewer pixels when (r6^2 + r7^2) / 256 <= 16
\
\     x = r5 + r7
\     y = r5
\
\ Draws pixels within the diagonal band of horizontal width 64, from top-left to
\ bottom-right of the screen.
\
\ ******************************************************************************

.PLL1

                        \ The following loop iterates CNT(1 0) times, i.e. &300
                        \ or 768 times, and draws the planet part of the
                        \ loading screen's Saturn

 LDA VIA+&44            \ Read the 6522 System VIA T1C-L timer 1 low-order
 STA RAND+1             \ counter (SHEILA &44), which increments 1000 times a
                        \ second so this will be pretty random, and store it in
                        \ RAND+1 among the hard-coded random seeds in RAND

 JSR DORND              \ Set A and X to random numbers, say A = r1

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r1^2

 STA ZP+1               \ Set ZP(1 0) = (A P)
 LDA P                  \             = r1^2
 STA ZP

 LDA #&4B               \ ???? Copy protection
 STA L19D2+1

 JSR DORND              \ Set A and X to random numbers, say A = r2

 STA YY                 \ Set YY = A
                        \        = r2

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r2^2

 TAX                    \ Set (X P) = (A P)
                        \           = r2^2

 LDA P                  \ Set (A ZP) = (X P) + ZP(1 0)
 ADC ZP                 \
 STA ZP                 \ first adding the low bytes

 TXA                    \ And then adding the high bytes
 ADC ZP+1

 BCS PLC1               \ If the addition overflowed, jump down to PLC1 to skip
                        \ to the next pixel

 STA ZP+1               \ Set ZP(1 0) = (A ZP)
                        \             = r1^2 + r2^2

 LDA #1                 \ Set ZP(1 0) = &4001 - ZP(1 0) - (1 - C)
 SBC ZP                 \             = 128^2 - ZP(1 0)
 STA ZP                 \
                        \ (as the C flag is clear), first subtracting the low
                        \ bytes

 LDA #&40               \ And then subtracting the high bytes
 SBC ZP+1
 STA ZP+1

 BCC PLC1               \ If the subtraction underflowed, jump down to PLC1 to
                        \ skip to the next pixel

                        \ If we get here, then both calculations fitted into
                        \ 16 bits, and we have:
                        \
                        \   ZP(1 0) = 128^2 - (r1^2 + r2^2)
                        \
                        \ where ZP(1 0) >= 0

 JSR ROOT               \ Set ZP = SQRT(ZP(1 0))

 LDA ZP                 \ Set X = ZP >> 1
 LSR A                  \       = SQRT(128^2 - (a^2 + b^2)) / 2
 TAX

 LDA YY                 \ Set A = YY
                        \       = r2

 CMP #128               \ If YY >= 128, set the C flag (so the C flag is now set
                        \ to bit 7 of A)

 ROR A                  \ Rotate A and set the sign bit to the C flag, so bits
                        \ 6 and 7 are now the same, i.e. A is a random number in
                        \ one of these ranges:
                        \
                        \   %00000000 - %00111111  = 0 to 63    (r2 = 0 - 127)
                        \   %11000000 - %11111111  = 192 to 255 (r2 = 128 - 255)
                        \
                        \ The PIX routine flips bit 7 of A before drawing, and
                        \ that makes -A in these ranges:
                        \
                        \   %10000000 - %10111111  = 128-191
                        \   %01000000 - %01111111  = 64-127
                        \
                        \ so that's in the range 64 to 191

 JSR PIX                \ Draw a pixel at screen coordinate (X, -A), i.e. at
                        \
                        \   (ZP / 2, -A)
                        \
                        \ where ZP = SQRT(128^2 - (r1^2 + r2^2))
                        \
                        \ So this is the same as plotting at (x, y) where:
                        \
                        \   r1 = random number from 0 to 255
                        \   r1 = random number from 0 to 255
                        \   (r1^2 + r1^2) < 128^2
                        \
                        \   y = r2, squished into 64 to 191 by negation
                        \
                        \   x = SQRT(128^2 - (r1^2 + r1^2)) / 2
                        \
                        \ which is what we want

.PLC1

 DEC CNT                \ Decrement the counter in CNT (the low byte)

 BNE PLL1               \ Loop back to PLL1 until CNT = 0

 DEC CNT+1              \ Decrement the counter in CNT+1 (the high byte)

 BNE PLL1               \ Loop back to PLL1 until CNT+1 = 0

                        \ The following loop iterates CNT2(1 0) times, i.e. &1DD
                        \ or 477 times, and draws the background stars on the
                        \ loading screen

.PLL2

 JSR DORND              \ Set A and X to random numbers, say A = r3

 TAX                    \ Set X = A
                        \       = r3

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r3^2

 STA ZP+1               \ Set ZP+1 = A
                        \          = r3^2 / 256

 JSR DORND              \ Set A and X to random numbers, say A = r4

 STA YY                 \ Set YY = r4

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r4^2

 ADC ZP+1               \ Set A = A + r3^2 / 256
                        \       = r4^2 / 256 + r3^2 / 256
                        \       = (r3^2 + r4^2) / 256

 CMP #&11               \ If A < 17, jump down to PLC2 to skip to the next pixel
 BCC PLC2

 LDA YY                 \ Set A = r4

 JSR PIX                \ Draw a pixel at screen coordinate (X, -A), i.e. at
                        \ (r3, -r4), where (r3^2 + r4^2) / 256 >= 17
                        \
                        \ Negating a random number from 0 to 255 still gives a
                        \ random number from 0 to 255, so this is the same as
                        \ plotting at (x, y) where:
                        \
                        \   x = random number from 0 to 255
                        \   y = random number from 0 to 255
                        \   (x^2 + y^2) div 256 >= 17
                        \
                        \ which is what we want

.PLC2

 DEC CNT2               \ Decrement the counter in CNT2 (the low byte)

 BNE PLL2               \ Loop back to PLL2 until CNT2 = 0

 DEC CNT2+1             \ Decrement the counter in CNT2+1 (the high byte)

 BNE PLL2               \ Loop back to PLL2 until CNT2+1 = 0

                        \ The following loop iterates CNT3(1 0) times, i.e. &333
                        \ or 819 times, and draws the rings around the loading
                        \ screen's Saturn

.PLL3

 JSR DORND              \ Set A and X to random numbers, say A = r5

 STA ZP                 \ Set ZP = r5

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r5^2

 STA ZP+1               \ Set ZP+1 = A
                        \          = r5^2 / 256

 LDA #&29               \ ???? Copy protection
 STA L19D2+2

 JSR DORND              \ Set A and X to random numbers, say A = r6

 STA YY                 \ Set YY = r6

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r6^2

 STA T                  \ Set T = A
                        \       = r6^2 / 256

 ADC ZP+1               \ Set ZP+1 = A + r5^2 / 256
 STA ZP+1               \          = r6^2 / 256 + r5^2 / 256
                        \          = (r5^2 + r6^2) / 256

 LDA ZP                 \ Set A = ZP
                        \       = r5

 CMP #128               \ If A >= 128, set the C flag (so the C flag is now set
                        \ to bit 7 of ZP, i.e. bit 7 of A)

 ROR A                  \ Rotate A and set the sign bit to the C flag, so bits
                        \ 6 and 7 are now the same

 CMP #128               \ If A >= 128, set the C flag (so again, the C flag is
                        \ set to bit 7 of A)

 ROR A                  \ Rotate A and set the sign bit to the C flag, so bits
                        \ 5-7 are now the same, i.e. A is a random number in one
                        \ of these ranges:
                        \
                        \   %00000000 - %00011111  = 0-31
                        \   %11100000 - %11111111  = 224-255
                        \
                        \ In terms of signed 8-bit integers, this is a random
                        \ number from -32 to 31. Let's call it r7

 ADC YY                 \ Set X = A + YY
 TAX                    \       = r7 + r6

 JSR SQUA2              \ Set (A P) = r7 * r7

 TAY                    \ Set Y = A
                        \       = r7 * r7 / 256

 ADC ZP+1               \ Set A = A + ZP+1
                        \       = r7^2 / 256 + (r5^2 + r6^2) / 256
                        \       = (r5^2 + r6^2 + r7^2) / 256

 BCS PLC3               \ If the addition overflowed, jump down to PLC3 to skip
                        \ to the next pixel

 CMP #80                \ If A >= 80, jump down to PLC3 to skip to the next
 BCS PLC3               \ pixel

 CMP #32                \ If A < 32, jump down to PLC3 to skip to the next pixel
 BCC PLC3

 TYA                    \ Set A = Y + T
 ADC T                  \       = r7^2 / 256 + r6^2 / 256
                        \       = (r6^2 + r7^2) / 256

 CMP #16                \ If A > 16, skip to PL1 to plot the pixel
 BCS PL1

 LDA ZP                 \ If ZP is positive (50% chance), jump down to PLC3 to
 BPL PLC3               \ skip to the next pixel

.PL1

 LDA YY                 \ Set A = YY
                        \       = r6

 JSR PIX                \ Draw a pixel at screen coordinate (X, -A), where:
                        \
                        \   X = (random -32 to 31) + r6
                        \   A = r6
                        \
                        \ Negating a random number from 0 to 255 still gives a
                        \ random number from 0 to 255, so this is the same as
                        \ plotting at (x, y) where:
                        \
                        \   r5 = random number from 0 to 255
                        \   r6 = random number from 0 to 255
                        \   r7 = r5, squashed into -32 to 31
                        \
                        \   x = r5 + r7
                        \   y = r5
                        \
                        \   32 <= (r5^2 + r6^2 + r7^2) / 256 <= 79
                        \   Draw 50% fewer pixels when (r6^2 + r7^2) / 256 <= 16
                        \
                        \ which is what we want

.PLC3

 DEC CNT3               \ Decrement the counter in CNT3 (the low byte)

 BNE PLL3               \ Loop back to PLL3 until CNT3 = 0

 DEC CNT3+1             \ Decrement the counter in CNT3+1 (the high byte)

 BNE PLL3               \ Loop back to PLL3 until CNT3+1 = 0

 LDA #&00               \ Set ZP(1 0) = &6300
 STA ZP
 LDA #&63
 STA ZP+1

 LDA #&62               \ Set P(1 0) = &2A62
 STA P
 LDA #&2A
 STA P+1

 LDX #8                 \ Call MVPG with X = 8 to copy 8 pages of memory from
 JSR MVPG               \ the address in P(1 0) to the address in ZP(1 0)

\ ******************************************************************************
\
\       Name: DORND
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Generate random numbers
\  Deep dive: Generating random numbers
\
\ ------------------------------------------------------------------------------
\
\ Set A and X to random numbers. The C and V flags are also set randomly.
\
\ This is a simplified version of the DORND routine in the main game code. It
\ swaps the two calculations around and omits the ROL A instruction, but is
\ otherwise very similar. See the DORND routine in the main game code for more
\ details.
\
\ ******************************************************************************

.DORND

 LDA RAND+1             \ r1´ = r1 + r3 + C
 TAX                    \ r3´ = r1
 ADC RAND+3
 STA RAND+1
 STX RAND+3

 LDA RAND               \ X = r2´ = r0
 TAX                    \ A = r0´ = r0 + r2
 ADC RAND+2
 STA RAND
 STX RAND+2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: RAND
\       Type: Variable
\   Category: Drawing planets
\    Summary: The random number seed used for drawing Saturn
\
\ ******************************************************************************

.RAND

 EQUD &34785349

\ ******************************************************************************
\
\       Name: SQUA2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = A * A
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of unsigned 8-bit numbers:
\
\   (A P) = A * A
\
\ This uses the same approach as routine SQUA2 in the main game code, which
\ itself uses the MU11 routine to do the multiplication. See those routines for
\ more details.
\
\ ******************************************************************************

.SQUA2

 BPL SQUA               \ If A > 0, jump to SQUA

 EOR #&FF               \ Otherwise we need to negate A for the SQUA algorithm
 CLC                    \ to work, so we do this using two's complement, by
 ADC #1                 \ setting A = ~A + 1

.SQUA

 STA Q                  \ Set Q = A and P = A

 STA P                  \ Set P = A

 LDA #0                 \ Set A = 0 so we can start building the answer in A

 LDY #8                 \ Set up a counter in Y to count the 8 bits in P

 LSR P                  \ Set P = P >> 1
                        \ and C flag = bit 0 of P

.SQL1

 BCC SQ1                \ If C (i.e. the next bit from P) is set, do the
 CLC                    \ addition for this bit of P:
 ADC Q                  \
                        \   A = A + Q

.SQ1

 ROR A                  \ Shift A right to catch the next digit of our result,
                        \ which the next ROR sticks into the left end of P while
                        \ also extracting the next bit of P

 ROR P                  \ Add the overspill from shifting A to the right onto
                        \ the start of P, and shift P right to fetch the next
                        \ bit for the calculation into the C flag

 DEY                    \ Decrement the loop counter

 BNE SQL1               \ Loop back for the next bit until P has been rotated
                        \ all the way

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PIX
\       Type: Subroutine
\   Category: Drawing pixels
\    Summary: Draw a single pixel at a specific coordinate
\
\ ------------------------------------------------------------------------------
\
\ Draw a pixel at screen coordinate (X, -A). The sign bit of A gets flipped
\ before drawing, and then the routine uses the same approach as the PIXEL
\ routine in the main game code, except it plots a single pixel from TWOS
\ instead of a two pixel dash from TWOS2. This applies to the top part of the
\ screen (the monochrome mode 4 space view).
\
\ See the PIXEL routine in the main game code for more details.
\
\ Arguments:
\
\   X                   The screen x-coordinate of the pixel to draw
\
\   A                   The screen y-coordinate of the pixel to draw, negated
\
\ Other entry points:
\
\   out                 Contains an RTS
\
\ ******************************************************************************

.PIX

 TAY                    \ Copy A into Y, for use later

 EOR #%10000000         \ Flip the sign of A

 LSR A                  \ Set A = A >> 3
 LSR A
 LSR A

 LSR BLPTR+1            \ Halve the high byte of BLPTR(1 0), as part of the copy
                        \ protection

 ORA #&60               \ Set ZP+1 = &60 + A >> 3
 STA ZP+1

 TXA                    \ Set ZP = (X >> 3) * 8
 EOR #%10000000
 AND #%11111000
 STA ZP

 TYA                    \ Set Y = Y AND %111
 AND #%00000111
 TAY

 TXA                    \ Set X = X AND %111
 AND #%00000111
 TAX

 LDA TWOS,X             \ Otherwise fetch a pixel from TWOS and poke it into
 STA (ZP),Y             \ ZP+Y

.out

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TWOS
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Ready-made single-pixel character row bytes for mode 4
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting one-pixel points in mode 4 (the top part of the
\ split screen). See the PIX routine for details.
\
\ ******************************************************************************

.TWOS

 EQUB %10000000
 EQUB %01000000
 EQUB %00100000
 EQUB %00010000
 EQUB %00001000
 EQUB %00000100
 EQUB %00000010
 EQUB %00000001

.L1CCF

 LDA RAND+2
 EOR BLPTR
 ASL A
 CMP #&93
 ROR A
 STA BLPTR
 BCC out

\ ******************************************************************************
\
\       Name: CNT
\       Type: Variable
\   Category: Drawing planets
\    Summary: A counter for use in drawing Saturn's planetary body
\
\ ------------------------------------------------------------------------------
\
\ Defines the number of iterations of the PLL1 loop, which draws the planet part
\ of the loading screen's Saturn.
\
\ ******************************************************************************

.CNT

 EQUW &0300             \ The number of iterations of the PLL1 loop (768)

\ ******************************************************************************
\
\       Name: CNT2
\       Type: Variable
\   Category: Drawing planets
\    Summary: A counter for use in drawing Saturn's background stars
\
\ ------------------------------------------------------------------------------
\
\ Defines the number of iterations of the PLL2 loop, which draws the background
\ stars on the loading screen.
\
\ ******************************************************************************

.CNT2

 EQUW &01DD             \ The number of iterations of the PLL2 loop (477)

\ ******************************************************************************
\
\       Name: CNT3
\       Type: Variable
\   Category: Drawing planets
\    Summary: A counter for use in drawing Saturn's rings
\
\ ------------------------------------------------------------------------------
\
\ Defines the number of iterations of the PLL3 loop, which draws the rings
\ around the loading screen's Saturn.
\
\ ******************************************************************************

.CNT3

 EQUW &0333             \ The number of iterations of the PLL3 loop (819)

.L1CE2

 LDA BLPTR
 AND BLPTR+1
 ORA #&0C
 ASL A
 STA BLPTR
 RTS

.L1CEC

 JMP L1CEC

\ ******************************************************************************
\
\       Name: ROOT
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate ZP = SQRT(ZP(1 0))
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following square root:
\
\   ZP = SQRT(ZP(1 0))
\
\ This routine is identical to LL5 in the main game code - it even has the same
\ label names. The only difference is that LL5 calculates Q = SQRT(R Q), but
\ apart from the variables used, the instructions are identical, so see the LL5
\ routine in the main game code for more details on the algorithm used here.
\
\ ******************************************************************************

.ROOT

 LDY ZP+1               \ Set (Y Q) = ZP(1 0)
 LDA ZP
 STA Q

                        \ So now to calculate ZP = SQRT(Y Q)

 LDX #0                 \ Set X = 0, to hold the remainder

 STX ZP                 \ Set ZP = 0, to hold the result

 LDA #8                 \ Set P = 8, to use as a loop counter
 STA P

.LL6

 CPX ZP                 \ If X < ZP, jump to LL7
 BCC LL7

 BNE LL8                \ If X > ZP, jump to LL8

 CPY #64                \ If Y < 64, jump to LL7 with the C flag clear,
 BCC LL7                \ otherwise fall through into LL8 with the C flag set

.LL8

 TYA                    \ Set Y = Y - 64
 SBC #64                \
 TAY                    \ This subtraction will work as we know C is set from
                        \ the BCC above, and the result will not underflow as we
                        \ already checked that Y >= 64, so the C flag is also
                        \ set for the next subtraction

 TXA                    \ Set X = X - ZP
 SBC ZP
 TAX

.LL7

 ROL ZP                 \ Shift the result in Q to the left, shifting the C flag
                        \ into bit 0 and bit 7 into the C flag

 ASL Q                  \ Shift the dividend in (Y S) to the left, inserting
 TYA                    \ bit 7 from above into bit 0
 ROL A
 TAY

 TXA                    \ Shift the remainder in X to the left
 ROL A
 TAX

 ASL Q                  \ Shift the dividend in (Y S) to the left
 TYA
 ROL A
 TAY

 TXA                    \ Shift the remainder in X to the left
 ROL A
 TAX

 DEC P                  \ Decrement the loop counter

 BNE LL6                \ Loop back to LL6 until we have done 8 loops

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: OSB
\       Type: Subroutine
\   Category: Utility routines
\    Summary: A convenience routine for calling OSBYTE with Y = 0
\
\ ******************************************************************************

.OSB

 LDY #0                 \ Call OSBYTE with Y = 0, returning from the subroutine
 JMP OSBYTE             \ using a tail call (so we can call OSB to call OSBYTE
                        \ for when we know we want Y set to 0)

 EQUB &0E

\ ******************************************************************************
\
\       Name: MVPG
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Move and decrypt a multi-page block of memory from one location to
\             another
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   P(1 0)              The source address of the block to move
\
\   ZP(1 0)             The destination address of the block to move
\
\   X                   Number of pages of memory to move (1 page = 256 bytes)
\
\ ******************************************************************************

.MVPG

                        \ This subroutine is called from below to copy one page
                        \ of memory from the address in P(1 0) to the address
                        \ in ZP(1 0)

 LDY #0                 \ We want to move one page of memory, so set Y as a byte
                        \ counter

.MPL

 LDA (P),Y              \ Fetch the Y-th byte of the P(1 0) memory block

 EOR #&A5               \ Decrypt it by EOR'ing with &A5

 STA (ZP),Y             \ Store the decrypted result in the Y-th byte of the
                        \ ZP(1 0) memory block

 DEY                    \ Decrement the byte counter

 BNE MPL                \ Loop back to copy the next byte until we have done a
                        \ whole page of 256 bytes

 RTS                    \ Return from the subroutine

 EQUB &0E

.MVBL

 JSR MVPG               \ Call MVPG above to copy one page of memory from the
                        \ address in P(1 0) to the address in ZP(1 0)

 INC ZP+1               \ Increment the high byte of the source address to point
                        \ to the next page

 INC P+1                \ Increment the high byte of the destination address to
                        \ point to the next page

 DEX                    \ Decrement the page counter

 BNE MVBL               \ Loop back to copy the next page until we have done X
                        \ pages

 RTS                    \ Return from the subroutine

 EQUB &2A, &44, &49, &52, &20
 EQUB &45, &0D, &55, &25, &22, &21, &22, &21
 EQUB &21, &25, &55, &A5, &A3, &A1, &A3, &A7
 EQUB &A3, &A5, &55, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &5A, &55, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &5A, &55, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &5A, &55, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &5A, &55, &33, &01, &65, &25, &25
 EQUB &25, &25, &55, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &55, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &55, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &55

 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &55
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &55
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &55
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &55
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &55
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &55
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &55
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &55
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &55
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &55
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &55
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &55
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &55
 EQUB &33, &01, &65, &65, &65, &65, &25, &55
 EQUB &A7, &A5, &A3, &A5, &A3, &A5, &A3, &55
 EQUB &33, &F7, &D5, &95, &95, &B5, &B5, &55
 EQUB &A5, &A5, &A5, &A5, &A5, &F0, &5A, &55
 EQUB &A5, &A5, &A5, &A5, &A5, &F0, &5A, &55
 EQUB &A5, &A5, &A5, &A5, &A5, &F0, &5A, &55
 EQUB &A5, &A5, &A5, &A5, &A5, &F0, &5A, &55
 EQUB &A5, &A3, &A1, &A3, &A7, &A3, &A5, &55
 EQUB &B5, &BB, &BF, &BB, &BD, &BD, &B5, &25
 EQUB &22, &20, &20, &22, &20, &25, &25, &A5
 EQUB &A3, &A1, &A3, &A7, &A3, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &5A, &25
 EQUB &25, &25, &25, &25, &25, &25, &25, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A4, &A3, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A3, &A5, &A5
 EQUB &A5, &A5, &A5, &A4, &A9, &A7, &A5, &A5
 EQUB &A5, &A5, &A5, &A3, &2D, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &AE, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A2, &A5, &A7, &A5, &A5
 EQUB &A5, &A5, &A5, &AF, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A8, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A1, &2F, &A7, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A9, &A4, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &AD, &A6, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &25
 EQUB &25, &27, &25, &25, &25, &25, &65, &A5
 EQUB &A5, &AC, &A5, &A5, &A3, &A5, &A3, &B5
 EQUB &B5, &B1, &B5, &B5, &B5, &B5, &B5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &87, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &0F, &5A, &2D
 EQUB &2D, &A5, &A5, &A5, &2D, &0F, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &0F, &5A, &A5
 EQUB &A5, &A3, &A0, &A2, &A3, &A0, &A5, &B5
 EQUB &B5, &B1, &B1, &B1, &B1, &B3, &B5, &25
 EQUB &23, &21, &23, &21, &21, &25, &25, &A5
 EQUB &AF, &AF, &AF, &AF, &A1, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &3C, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &87, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &E1, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &3C, &5A, &25
 EQUB &25, &25, &25, &25, &25, &25, &25, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A4, &A7, &A5
 EQUB &A5, &A5, &A6, &A1, &AD, &A5, &A5, &A4
 EQUB &A3, &AD, &A7, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &AF, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &AF, &A4, &A5, &A7, &A5, &A1
 EQUB &A5, &AD, &AF, &A5, &A5, &A5, &A5, &87
 EQUB &A5, &A5, &AF, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &2F, &A5, &A5, &87, &A5, &A7
 EQUB &A5, &A7, &AD, &A7, &A5, &A7, &A5, &A5
 EQUB &A5, &A5, &AF, &A5, &A5, &87, &A5, &87
 EQUB &A5, &A5, &2F, &A5, &A5, &A5, &A5, &A4
 EQUB &A5, &A5, &AF, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &AD, &A7, &A1, &A5, &A7, &A5, &A5
 EQUB &A5, &A5, &AF, &A5, &A5, &A5, &A5, &AD
 EQUB &A6, &A5, &AF, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &AD, &A3, &A4, &A5, &A5, &A5, &E5
 EQUB &E5, &C5, &85, &95, &BD, &A1, &A7, &A5
 EQUB &A3, &A5, &A3, &A5, &55, &A5, &A5, &95
 EQUB &95, &F7, &F7, &33, &55, &B5, &B5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &87, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &E1, &5A, &2D
 EQUB &2D, &A5, &A5, &A5, &2D, &3C, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &87, &5A, &A5
 EQUB &A3, &A0, &A0, &A0, &A3, &A5, &A5, &B5
 EQUB &B3, &B1, &B1, &B1, &B3, &B5, &B5, &25
 EQUB &23, &21, &21, &21, &23, &25, &25, &A5
 EQUB &AB, &A1, &A1, &A1, &A1, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &2D, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &2D, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &2D, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &2D, &5A, &25
 EQUB &25, &25, &25, &25, &25, &25, &25, &A5
 EQUB &A1, &A1, &AD, &AF, &A5, &AD, &A5, &A5
 EQUB &A5, &A5, &A5, &AF, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &AF, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &AF, &A5, &A7, &A5, &A1
 EQUB &A5, &AD, &A5, &AF, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &AF, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &AF, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &AF, &A5, &A5, &A5, &A7
 EQUB &2D, &A7, &A5, &8D, &D5, &A7, &A5, &A5
 EQUB &2D, &A5, &A5, &AF, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &AF, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &AF, &A5, &A5, &A5, &A4
 EQUB &A5, &A5, &A5, &AF, &A5, &A5, &A5, &A5
 EQUB &A5, &AD, &A5, &AF, &A5, &A7, &A5, &A5
 EQUB &A5, &A5, &A5, &AF, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &AF, &A5, &A5, &A5, &A7
 EQUB &A4, &A4, &A5, &AF, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &AD, &A5, &AD, &A5, &AD, &B5
 EQUB &B5, &B5, &B5, &B5, &B5, &B5, &B5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &5A, &A5
 EQUB &A4, &A6, &A4, &A4, &A6, &A5, &A5, &B5
 EQUB &B5, &B5, &B5, &B5, &BD, &B5, &B5, &25
 EQUB &21, &21, &21, &21, &23, &25, &25, &A5
 EQUB &AB, &A1, &A1, &A1, &A1, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &3C, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &87, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &E1, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &2D, &5A, &25
 EQUB &25, &25, &25, &25, &25, &25, &25, &AD
 EQUB &A1, &A1, &A7, &A7, &A4, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &AD, &AF, &A1, &A5
 EQUB &A5, &A5, &A5, &A4, &A5, &AF, &A5, &A1
 EQUB &A5, &AD, &A5, &A5, &A5, &AF, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &AF, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &AF, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &AF, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &AF, &A5, &A7
 EQUB &A5, &A7, &A5, &A7, &A5, &AF, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &AF, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &AF, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &AF, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &AF, &A5, &A4
 EQUB &A5, &A5, &A5, &A5, &A5, &AF, &A5, &A5
 EQUB &A5, &AD, &A5, &A1, &A5, &AF, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &AF, &A4, &A5
 EQUB &A4, &A4, &A6, &A7, &A1, &AD, &A5, &AD
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &B5
 EQUB &B5, &B5, &B5, &B5, &B5, &B5, &B5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &5A, &A6
 EQUB &A5, &A6, &A7, &A6, &A5, &A5, &A5, &BD
 EQUB &BD, &BD, &B5, &BD, &B5, &B5, &B5, &25
 EQUB &22, &20, &22, &20, &20, &25, &25, &A5
 EQUB &A1, &A1, &A1, &A1, &A3, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &3C, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &B4, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &B4, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &5A, &25
 EQUB &25, &25, &25, &25, &25, &25, &25, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A7
 EQUB &A4, &A5, &A5, &A5, &A5, &A5, &A5, &A1
 EQUB &AD, &A1, &A4, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &AD, &A3, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A9, &A4, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &AF, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A8, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A3, &A7
 EQUB &A5, &A7, &A5, &A7, &A5, &A7, &AE, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A0, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &AF, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A0, &AD, &A5
 EQUB &A5, &A5, &A5, &A5, &A6, &AD, &A5, &A5
 EQUB &A5, &A5, &A5, &A3, &A5, &A5, &A5, &A4
 EQUB &A5, &A6, &A9, &A5, &A5, &A5, &A5, &A7
 EQUB &AD, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &B5
 EQUB &B5, &B5, &B5, &B5, &B5, &B5, &B5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &5A, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &5A, &A6
 EQUB &A5, &A6, &A5, &A6, &A5, &A5, &A7, &BD
 EQUB &BD, &BD, &BD, &BD, &B5, &B5, &B5, &25
 EQUB &25, &75, &22, &20, &25, &25, &55, &A5
 EQUB &A5, &65, &89, &A9, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &25
 EQUB &25, &25, &25, &65, &01, &33, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &96, &87, &96, &87, &96, &A5, &55, &A5
 EQUB &0F, &87, &87, &87, &1E, &A5, &55, &A5
 EQUB &87, &87, &87, &87, &0F, &A5, &55, &A5
 EQUB &4B, &E1, &E1, &E1, &E1, &A5, &55, &A5
 EQUB &4B, &2D, &69, &2D, &4B, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &B5
 EQUB &B5, &B5, &B5, &95, &F7, &33, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &55, &A7
 EQUB &A7, &A7, &A6, &A5, &A5, &A5, &55, &B5
 EQUB &BD, &BD, &BD, &BD, &B5, &B5, &55, &A5
 EQUB &E5, &A3, &DF, &7F, &F4, &A5, &AF, &C3
 EQUB &BD, &A5, &A5, &81, &AB, &A7, &89, &A5
 EQUB &A5, &A7, &A5, &A5, &A5, &E1, &BA, &B5
 EQUB &97, &AD, &AD, &81, &FA, &84, &F1, &AD
 EQUB &AD, &81, &BA, &97, &D1, &AD, &AD, &81
 EQUB &3A, &95, &D3, &AD, &AD, &81, &7A, &B5
 EQUB &C0, &AD, &AD, &89, &9A, &D1, &2D, &AD
 EQUB &AD, &89, &DA, &F1, &2D, &AD, &AD, &89
 EQUB &5A, &C0, &2D, &AD, &AD, &89, &1A, &D3
 EQUB &2D, &A9, &A9, &89, &8D, &D1, &2D, &A9
 EQUB &A9, &89, &CD, &F1, &2D, &A9, &A9, &89
 EQUB &4D, &C0, &2D, &A9, &A9, &89, &0D, &D3
 EQUB &2D, &AD, &AD, &A9, &0D, &D3, &D2, &AD
 EQUB &AD, &A9, &4D, &C0, &C3, &AD, &AD, &A9
 EQUB &8D, &D1, &D2, &AD, &AD, &A9, &CD, &F1
 EQUB &F0, &BA, &84, &A5, &A1, &BA, &97, &A5
 EQUB &AD, &BA, &95, &A5, &A9, &BA, &B5, &A5
 EQUB &B5, &BA, &81, &A1, &AD, &BA, &F4, &A1
 EQUB &B5, &BA, &C5, &A9, &B5, &BA, &D6, &AD
 EQUB &A9, &BA, &D1, &AD, &B1, &BA, &F1, &A1
 EQUB &BD, &BA, &C0, &B5, &B9, &BA, &D3, &A9
 EQUB &85, &BA, &23, &B9, &85, &BA, &22, &B1
 EQUB &85, &BA, &21, &B1, &BD, &BA, &20, &BD
 EQUB &B9, &AD, &20, &BD, &8D, &AD, &22, &B1
 EQUB &81, &AD, &22, &85, &95, &AD, &20, &B9
 EQUB &89, &AD, &D1, &81, &99, &AD, &F1, &8D
 EQUB &E5, &AD, &D3, &95, &91, &AD, &C0, &89
 EQUB &9D, &3A, &E5, &A5, &B5, &FA, &A5, &E5
 EQUB &B5, &BA, &E5, &A5, &B5, &BA, &A5, &E5
 EQUB &B5, &BA, &85, &A5, &A5, &FA, &A5, &85
 EQUB &A5, &3A, &85, &A5, &A5, &BA, &A5, &05
 EQUB &CB, &A5, &A5, &E5, &A1, &A1, &A5, &E9
 EQUB &97, &81, &A5, &A6, &C5, &CE, &0C, &D2
 EQUB &A5, &C1, &C9, &10, &D4, &C8, &CB, &14
 EQUB &D2, &A5, &C2, &17, &C7, &97, &85, &A5
 EQUB &0A, &10, &C8, &D2, &1F, &DF, &8A, &A5
 EQUB &D5, &DF, &D5, &1A, &CB, &A5, &D6, &18
 EQUB &03, &A5, &84, &A6, &0D, &D4, &CD, &C3
 EQUB &D2, &A6, &20, &D5, &A5, &0A, &C2, &0E
 EQUB &D2, &18, &06, &A5, &C7, &C1, &18, &C5
 EQUB &D3, &CA, &D2, &D3, &12, &CA, &A5, &18
 EQUB &C5, &CE, &A6, &A5, &C7, &10, &12, &05
 EQUB &A6, &A5, &D6, &C9, &1F, &A6, &A5, &0D
 EQUB &0A, &CA, &DF, &A6, &A5, &D3, &C8, &CF
 EQUB &D2, &A5, &D0, &CF, &C3, &D1, &A6, &A5
 EQUB &1C, &1D, &11, &D2, &DF, &A5, &1D, &0C
 EQUB &C5, &CE, &DF, &A5, &C0, &C3, &D3, &C2
 EQUB &06, &A5, &CB, &D3, &CA, &11, &AB, &24
 EQUB &A5, &0B, &C5, &D2, &17, &1F, &3F, &A5
 EQUB &7D, &CB, &D3, &C8, &1B, &D2, &A5, &C5
 EQUB &19, &C0, &1E, &16, &C7, &C5, &DF, &A5
 EQUB &C2, &C3, &CB, &C9, &C5, &12, &C5, &DF
 EQUB &A5, &C5, &1F, &D6, &1F, &17, &C3, &A6
 EQUB &4D, &17, &C3, &A5, &D5, &CE, &CF, &D6
 EQUB &A5, &D6, &78, &C2, &D3, &C5, &D2, &A5
 EQUB &A6, &13, &D5, &16, &A5, &CE, &D3, &CB
 EQUB &1D, &A6, &C5, &C9, &CA, &19, &CF, &06
 EQUB &A5, &CE, &DF, &D6, &16, &D5, &D6, &C7
 EQUB &03, &A6, &A5, &D5, &CE, &1F, &D2, &A6
 EQUB &4C, &27, &A5, &0B, &4D, &1D, &03, &A5
 EQUB &D6, &C9, &D6, &D3, &CA, &17, &CF, &19
 EQUB &A5, &C1, &78, &D5, &D5, &A6, &3C, &CF
 EQUB &D0, &CF, &D2, &DF, &A5, &C3, &C5, &19
 EQUB &C9, &CB, &DF, &A5, &A6, &CA, &CF, &C1
 EQUB &CE, &D2, &A6, &DF, &C3, &0C, &D5, &A5
 EQUB &1A, &C5, &CE, &A8, &07, &10, &CA, &A5
 EQUB &C5, &C7, &D5, &CE, &A5, &A6, &00, &89
 EQUB &CF, &19, &A5, &FC, &27, &87, &A5, &D2
 EQUB &0C, &05, &D2, &A6, &CA, &C9, &4D, &A5
 EQUB &EC, &A6, &CC, &C7, &CB, &CB, &1E, &A5
 EQUB &D4, &1D, &05, &A5, &D5, &D2, &A5, &36
 EQUB &A6, &C9, &C0, &A6, &A5, &D5, &C3, &89
 EQUB &A5, &A6, &C5, &0C, &C1, &C9, &80, &A5
 EQUB &C3, &1C, &CF, &D6, &A5, &C0, &C9, &C9
 EQUB &C2, &A5, &1A, &DE, &11, &CA, &0F, &A5
 EQUB &12, &0B, &C9, &C7, &C5, &11, &10, &D5
 EQUB &A5, &D5, &13, &10, &D5, &A5, &CA, &CF
 EQUB &1C, &1F, &A9, &D1, &0A, &0F, &A5, &CA
 EQUB &D3, &DE, &D3, &18, &0F, &A5, &C8, &0C
 EQUB &C5, &C9, &11, &C5, &D5, &A5, &7D, &D6
 EQUB &D3, &D2, &16, &D5, &A5, &0D, &C5, &CE
 EQUB &0A, &16, &DF, &A5, &C7, &CA, &CA, &C9
 EQUB &DF, &D5, &A5, &C0, &CF, &08, &0C, &CB
 EQUB &D5, &A5, &C0, &D3, &D4, &D5, &A5, &CB
 EQUB &0A, &16, &06, &D5, &A5, &C1, &C9, &CA
 EQUB &C2, &A5, &D6, &CA, &17, &0A, &D3, &CB
 EQUB &A5, &05, &CB, &AB, &4D, &19, &0F, &A5
 EQUB &06, &CF, &14, &A6, &F9, &D5, &A5, &8A
 EQUB &B7, &B6, &86, &B3, &86, &A5, &A6, &C5
 EQUB &D4, &A5, &CA, &0C, &05, &A5, &C0, &CF
 EQUB &16, &03, &A5, &D5, &0D, &89, &A5, &C1
 EQUB &08, &14, &A5, &D4, &1E, &A5, &DF, &C3
 EQUB &89, &C9, &D1, &A5, &C4, &CA, &D3, &C3
 EQUB &A5, &C4, &13, &C5, &CD, &A5, &90, &A5
 EQUB &D5, &CA, &CF, &CB, &DF, &A5, &C4, &D3
 EQUB &C1, &AB, &C3, &DF, &1E, &A5, &CE, &1F
 EQUB &C8, &1E, &A5, &C4, &19, &DF, &A5, &C0
 EQUB &17, &A5, &C0, &D3, &D4, &D4, &DF, &A5
 EQUB &78, &C2, &14, &D2, &A5, &C0, &78, &C1
 EQUB &A5, &CA, &CF, &02, &D4, &C2, &A5, &CA
 EQUB &C9, &C4, &4D, &16, &A5, &00, &D4, &C2
 EQUB &A5, &CE, &D3, &CB, &1D, &C9, &CF, &C2
 EQUB &A5, &C0, &C3, &CA, &0A, &C3, &A5, &0A
 EQUB &D5, &C3, &C5, &D2, &A5, &2D, &12, &0B
 EQUB &0E, &A5, &C5, &C9, &CB, &A5, &7D, &CB
 EQUB &1D, &C2, &16, &A5, &A6, &C2, &0F, &D2
 EQUB &78, &DF, &1E, &A5, &D4, &C9, &A5, &28
 EQUB &A6, &A6, &36, &8A, &A6, &3C, &A6, &A6
 EQUB &A6, &28, &A6, &20, &A6, &C0, &1F, &A6
 EQUB &D5, &C7, &07, &8A, &8C, &A5, &C0, &D4
 EQUB &19, &D2, &A5, &08, &0C, &A5, &07, &C0
 EQUB &D2, &A5, &18, &C1, &CE, &D2, &A5, &FF
 EQUB &CA, &C9, &D1, &81, &A5, &E5, &97, &7A
 EQUB &A7, &A5, &C3, &DE, &D2, &12, &A6, &A5
 EQUB &D6, &D3, &CA, &D5, &C3, &3D, &A5, &15
 EQUB &C7, &CB, &3D, &A5, &C0, &D3, &C3, &CA
 EQUB &A5, &CB, &1B, &D5, &CF, &07, &A5, &65
 EQUB &48, &A6, &C4, &C7, &DF, &A5, &C3, &A8
 EQUB &C5, &A8, &CB, &A8, &23, &A5, &E0, &E1
 EQUB &D5, &A5, &E0, &EE, &D5, &A5, &EF, &A6
 EQUB &D5, &C5, &C9, &C9, &D6, &D5, &A5, &0F
 EQUB &C5, &C7, &D6, &C3, &A6, &D6, &C9, &C2
 EQUB &A5, &FF, &C4, &C9, &CB, &C4, &A5, &FF
 EQUB &28, &A5, &C2, &C9, &C5, &CD, &0A, &C1
 EQUB &A6, &51, &A5, &FC, &A6, &3B, &A5, &CB
 EQUB &CF, &CA, &CF, &D2, &0C, &DF, &A6, &3D
 EQUB &A5, &CB, &0A, &0A, &C1, &A6, &3D, &A5
 EQUB &43, &BC, &86, &A5, &0A, &7D, &0A, &C1
 EQUB &A6, &EC, &A5, &14, &16, &C1, &DF, &A6
 EQUB &A5, &C1, &C7, &13, &C5, &11, &C5, &A5
 EQUB &F5, &A6, &C9, &C8, &A5, &C7, &89, &A5
 EQUB &83, &07, &C1, &06, &A6, &4D, &17, &0E
 EQUB &BC, &A5, &7A, &A6, &82, &8A, &8A, &8A
 EQUB &80, &99, &A6, &23, &8F, &84, &8A, &3B
 EQUB &23, &8F, &85, &8A, &C5, &19, &0B, &11
 EQUB &19, &8F, &A5, &CF, &1A, &CB, &A5, &A5
 EQUB &CA, &CA, &A5, &12, &11, &C8, &C1, &BC
 EQUB &A5, &A6, &19, &A6, &A5, &8A, &8E, &49
 EQUB &CB, &14, &D2, &BC, &80, &A5, &C5, &07
 EQUB &1D, &A5, &C9, &C0, &C0, &14, &C2, &16
 EQUB &A5, &C0, &D3, &C1, &CF, &11, &10, &A5
 EQUB &CE, &0C, &CB, &07, &D5, &D5, &A5, &CB
 EQUB &C9, &4D, &CA, &DF, &A6, &90, &A5, &2A
 EQUB &A5, &2D, &A5, &C7, &C4, &C9, &10, &A6
 EQUB &2D, &A5, &7D, &D6, &C3, &D2, &14, &D2
 EQUB &A5, &C2, &1D, &05, &78, &0E, &A5, &C2
 EQUB &C3, &C7, &C2, &CA, &DF, &A5, &AB, &AB
 EQUB &AB, &AB, &A6, &C3, &A6, &CA, &A6, &CF
 EQUB &A6, &D2, &A6, &C3, &A6, &AB, &AB, &AB
 EQUB &AB, &A5, &D6, &08, &D5, &14, &D2, &A5
 EQUB &8E, &C1, &C7, &CB, &C3, &A6, &C9, &10
 EQUB &D4, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &BC, &97, &EF, &C7, &DC, &2B, &07, &10
 EQUB &63, &70, &47, &48, &50, &5E, &5A, &5A
 EQUB &5A, &5E, &50, &48, &47, &70, &63, &10
 EQUB &07, &2B, &DC, &C7, &EF, &97, &BC, &A5
 EQUB &A4, &A6, &A1, &A0, &A3, &AD, &AC, &AF
 EQUB &AE, &A9, &A8, &AA, &B5, &B4, &B7, &B6
 EQUB &B1, &B0, &B3, &B2, &BD, &BC, &BC, &BF
 EQUB &BE, &B9, &B8, &B8, &BB, &BA, &BA, &38
 EQUB &A0, &00, &84, &70, &A9, &0F, &85, &71
 EQUB &71, &70, &C8, &D0, &FB, &C9, &CF, &EA
 EQUB &EA, &A9, &DB, &85

 EQUB &9F

 EQUB &60, &71, &61, &31, &21, &50, &40, &10
 EQUB &00, &D3, &C3, &93, &83, &44, &54, &14
 EQUB &04, &55, &45, &15, &05, &75, &65, &35
 EQUB &25, &D2, &C2, &92, &82, &0C, &BB, &20
 EQUB &2E, &28, &E1, &5B, &0C, &9C, &28, &E0
 EQUB &5B, &08, &ED, &A6, &75, &E7, &0C, &AD
 EQUB &28, &85, &5B, &1C, &B5, &B4, &28, &84
 EQUB &5B, &2D, &B5, &52, &08, &E3, &A6, &55
 EQUB &A6, &6B, &E3, &A6, &CD, &0D, &08, &E4
 EQUB &5B, &00, &59, &E5, &3D, &ED, &05, &AE
 EQUB &0C, &A7, &89, &E8, &5B, &75, &63, &F5
 EQUB &B7, &AF, &28, &85, &5B, &08, &23, &A6
 EQUB &75, &AB, &1C, &A5, &B4, &28, &84, &5B
 EQUB &2D, &B5, &52, &CD, &0D, &C9, &5B, &DA
 EQUB &05, &A2, &1C, &AD, &B4, &28, &84, &5B
 EQUB &2D, &B5, &52, &95, &4B, &9F, &95, &8B
 EQUB &E0, &8B, &EF, &E4, &E8, &E0, &F6, &EA
 EQUB &EB, &A8, &A5, &B1, &08, &EF, &FF, &ED
 EQUB &A7, &F6, &12, &A5, &A5, &A6, &4D, &E3
 EQUB &A5, &A5, &AA, &A5, &A5, &A5, &A5, &A5
 EQUB &B3, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A6, &A5, &B5
 EQUB &AA, &B4, &A5, &A6, &B9, &AB, &A5, &A5
 EQUB &AF, &A5, &B4, &9F, &A2, &AC, &AD, &A5
 EQUB &A5, &A5, &A5, &25, &0F, &A6, &05, &A5
 EQUB &0C, &A8, &85, &4B, &5A, &6D, &14, &58
 EQUB &75, &5D, &55, &5B, &C1, &FA, &C4, &D1
 EQUB &D1, &D7, &CC, &C7, &D0, &D1, &C0, &D6
 EQUB &A5, &61, &81, &CF, &E6, &C2, &C0, &D1
 EQUB &D7, &C1, &CC, &D6, &C6, &A5, &13, &99
 EQUB &63, &A5, &A5, &A5, &A5, &A5, &A5, &A2
 EQUB &9A, &A5, &A5, &A5, &A6, &BA, &5A, &5A
 EQUB &5A, &A5, &AA, &DA, &5A, &5A, &5A, &5A
 EQUB &5A, &A5, &5A, &5A, &5A, &5A, &45, &25
 EQUB &5A, &A5, &5A, &45, &A5, &5A, &A5, &A5
 EQUB &5A, &A5, &5A, &A5, &A5, &5B, &A5, &A5
 EQUB &5B, &A5, &5A, &A5, &A5, &A5, &A5, &A6
 EQUB &AA, &A5, &44, &A2, &AA, &9A, &5A, &5A
 EQUB &5A, &A5, &5A, &5A, &5A, &5A, &5A, &5A
 EQUB &5A, &A5, &5A, &5B, &59, &55, &45, &65
 EQUB &5A, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &5A, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &5A, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &26, &A5, &9A, &A5, &A5, &A5, &A5, &A5
 EQUB &5A, &A5, &5A, &AA, &AA, &AA, &AA, &BA
 EQUB &5A, &A5, &5A, &5A, &5A, &5A, &5A, &5A
 EQUB &5A, &A5, &5A, &59, &59, &59, &59, &5B
 EQUB &5A, &A5, &5A, &A5, &A5, &A5, &A5, &A5
 EQUB &5A, &A5, &22, &A5, &A5, &A5, &A5, &A5
 EQUB &45, &A5, &5A, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &5A, &DA, &DA, &9A, &BA, &AA
 EQUB &A2, &A5, &5A, &5A, &5A, &5A, &5A, &5A
 EQUB &5A, &A5, &5A, &65, &45, &5D, &59, &5B
 EQUB &5A, &A5, &45, &A5, &A5, &A5, &A5, &A5
 EQUB &25, &A5, &5A, &9A, &BA, &A2, &A4, &A5
 EQUB &A5, &A5, &5A, &5A, &5A, &5A, &5A, &DA
 EQUB &BA, &A5, &5A, &45, &5D, &5A, &5A, &5A
 EQUB &5A, &A5, &5A, &A5, &A5, &5A, &65, &55
 EQUB &5A, &A5, &59, &A5, &A5, &5A, &A5, &A5
 EQUB &5A, &A5, &A5, &A5, &A5, &25, &A5, &A5
 EQUB &5A, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &5B, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A2, &A5, &A5, &A5, &A5, &A6, &BA, &5D
 EQUB &66, &A5, &A5, &AA, &D9, &5A, &AA, &D9
 EQUB &55, &A5, &9A, &2A, &D9, &54, &2A, &9A
 EQUB &9A, &A5, &65, &2A, &D9, &55, &65, &BA
 EQUB &55, &A5, &5A, &3A, &A5, &A5, &A6, &2A
 EQUB &A2, &A5, &A4, &BA, &D9, &5D, &44, &62
 EQUB &5B, &A5, &5B, &BA, &D9, &5D, &54, &46
 EQUB &A2, &A5, &BA, &9B, &D9, &5A, &5E, &55
 EQUB &44, &A5, &59, &9B, &D9, &55, &45, &5D
 EQUB &5D, &A5, &9B, &9B, &DA, &DA, &D9, &D9
 EQUB &59, &A5, &D9, &D9, &1B, &5B, &5B, &9B
 EQUB &9A, &A5, &9A, &D9, &9B, &AA, &A5, &BA
 EQUB &A6, &A5, &45, &D9, &A5, &5D, &BA, &AA
 EQUB &5A, &A5, &DA, &5D, &9B, &BA, &2A, &62
 EQUB &A5, &A5, &26, &5D, &9B, &BA, &22, &46
 EQUB &DA, &A5, &5A, &5D, &9B, &AA, &62, &54
 EQUB &45, &A5, &6A, &A5, &A5, &5B, &45, &5D
 EQUB &DB, &A5, &5A, &BA, &A6, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &45, &D9, &BA, &A6
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &25, &55
 EQUB &DB, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A4, &A6
 EQUB &A2, &A5, &A5, &A4, &AB, &9D, &45, &66
 EQUB &22, &A5, &9D, &66, &AB, &9D, &45, &39
 EQUB &44, &A5, &D9, &1D, &A5, &A6, &A2, &9D
 EQUB &65, &A5, &D5, &D5, &45, &65, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A4, &A6, &AA, &B9
 EQUB &9C, &A5, &9A, &42, &7B, &58, &D6, &42
 EQUB &62, &A5, &A5, &A5, &DB, &6B, &24, &9C
 EQUB &44, &A5, &A5, &A5, &9A, &42, &4B, &7B
 EQUB &5D, &A5, &A5, &A5, &9A, &DA, &D5, &55
 EQUB &45, &A5, &A5, &A5, &3A, &38, &98, &98
 EQUB &9C, &A5, &A5, &A5, &62, &4B, &42, &65
 EQUB &6A, &A5, &A5, &A5, &56, &A2, &42, &D6
 EQUB &44, &A5, &A5, &A4, &54, &1C, &19, &19
 EQUB &5D, &A5, &54, &65, &44, &5D, &55, &D5
 EQUB &DD, &A5, &65, &45, &59, &D5, &9D, &99
 EQUB &AA, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &25, &A5, &D5, &D9, &AB, &A2, &A6, &A4
 EQUB &A6, &A5, &D9, &D2, &98, &A2, &25, &45
 EQUB &59, &A5, &DB, &1E, &7B, &56, &9C, &99
 EQUB &D9, &A5, &AB, &22, &46, &56, &7B, &52
 EQUB &BA, &A5, &A5, &25, &45, &5D, &5A, &26
 EQUB &25, &A5, &A5, &A5, &A5, &A5, &A5, &25
 EQUB &45, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &A5, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &55, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &55, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &55, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &55, &25, &25, &25, &25, &65, &01
 EQUB &33, &55, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &55, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &55, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &55, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &55, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &55, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &55, &A5, &96, &87, &96, &87, &96
 EQUB &A5, &55, &A5, &0F, &87, &87, &87, &1E
 EQUB &A5, &55, &A5, &87, &87, &87, &87, &0F
 EQUB &A5, &55, &A5, &4B, &E1, &E1, &E1, &E1
 EQUB &A5, &55, &A5, &4B, &2D, &69, &2D, &4B
 EQUB &A5, &55, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &55, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &55, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &55, &A5, &A5, &A5, &A5, &A5, &A5
 EQUB &A5, &55, &A5, &A5, &A5, &A5, &A5

\ ******************************************************************************
\
\ Save output/ELITE4.bin
\
\ ******************************************************************************

PRINT "S.ELITE4 ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD%
SAVE "output/ELITE4.bin", CODE%, P%, LOAD%

