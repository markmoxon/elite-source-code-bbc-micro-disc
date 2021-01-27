\ ******************************************************************************
\
\ DISC ELITE LOADER (PART 1) SOURCE
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
\   * output/ELITE2.bin
\
\ ******************************************************************************

INCLUDE "sources/elite-header.h.asm"

ZP = &01                \ Temporary storage, used all over the place

OSWRCH = &FFEE          \ The address for the OSWRCH routine
OSBYTE = &FFF4          \ The address for the OSBYTE routine
OSWORD = &FFF1          \ The address for the OSWORD routine
OSCLI = &FFF7           \ The address for the OSCLI routine

CODE% = &2F00
LOAD% = &2F00

\ ******************************************************************************
\
\       Name: run
\       Type: Subroutine
\   Category: Loader
\    Summary: Copy protection (disabled)
\
\ ******************************************************************************

ORG CODE%

.run

 JMP ENTRY              \ Jump over the copy protection to disable it

.L2F03

 LDA run

.L2F06

 EOR run,X
 STA run,X
 INX
 BNE L2F06

.L2F0F

 INC L2F03+1
 BEQ L2F1E

 LDA L2F03+1
 CMP #&1E
 BEQ L2F0F

 JMP run

.L2F1E

 BIT &020B
 BPL run

\ ******************************************************************************
\
\       Name: Elite loader
\       Type: Subroutine
\   Category: Loader
\    Summary: Reset vectors, change to mode 7, and load and run the ELITE3
\             loader code
\
\ ******************************************************************************

.ENTRY

 LDA #0                 \ Call OSBYTE with A = 0 and X = 1 to fetch bit 0 of the
 LDX #1                 \ operating system version into X
 JSR OSBYTE

 LDY #0                 \ Set Y to 0 so we can use it as an index for setting
                        \ all the vectors to their default states

 SEI                    \ Disable all interrupts

 CPX #1                 \ If X = 1 then this is OS 1.20, so jump to OS120
 BEQ OS120

.OS100

 LDA &D941,Y            \ Copy the Y-th byte from the default vector table at
 STA &200               \ &D941 into location &0200 (this is surely supposed to
                        \ be the Y-th byte in &0200, i.e. STA &200,Y, but it
                        \ isn't, which feels like a bug)

 INY                    \ Increment the loop counter

 CPY #54                \ Loop back to copy the next byte until we have copied
 BNE OS100              \ 54 bytes (27 vectors)

 BEQ VDONE              \ Jump down to VDONE to skip the OS 1.20 routine

.OS120

 LDA &FFB7              \ Set ZP(1 0) to the location stored in &FFB7-&FFB8,
 STA ZP                 \ which contains the address of the default vector table
 LDA &FFB8
 STA ZP+1

.ABCDEFG

 LDA (ZP),Y             \ Copy the Y-th byte from the default vector table into
 STA &200,Y             \ the vector table in &0200

 INY                    \ Increment the loop counter

 CPY &FFB6              \ Compare the loop counter with the contents of &FFB6,
                        \ which contains the length of the default vector table

 BNE ABCDEFG            \ Loop back for the next vector until we have done them
                        \ all

.VDONE

 CLI                    \ Re-enable interrupts

 LDX #LO(MESS1)         \ Set (Y X) to point to MESS1 ("DISK")
 LDY #HI(MESS1)

 JSR OSCLI              \ Call OSCLI to run the OS command in MESS1, which
                        \ switches to the disc filing system (DFS)

 LDA #201               \ Call OSBYTE with A = 201, X = 1 and Y = 0 to disable
 LDX #1                 \ the keyboard
 LDY #0
 JSR OSBYTE

 LDA #200               \ Call OSBYTE with A = 200, X = 0 and Y = 0 to enable
 LDX #0                 \ the ESCAPE key and disable memory clearing if the
 LDY #0                 \ BREAK key is pressed
 JSR OSBYTE

 LDA #119               \ Call OSBYTE with A = 119 to close any *SPOOL or *EXEC
 JSR OSBYTE             \ files

 LDY #0                 \ Set Y to 0 so we can use it as an index for the
                        \ following, which has been disabled (so perhaps this
                        \ was part of the copy protection)

.L2F74

 LDA L2FF5,Y            \ Fetch the Y-th byte from L2FF5

 NOP                    \ This instruction has been disabled, so this lopp does
                        \ nothing

 INY                    \ Increment the loop counter

 CPY #9                 \ Loop back to do the next byte until we have done 9 of
 BNE L2F74              \ them

 LDY #0                 \ We are now going to send the 12 VDU bytes in the table
                        \ at B% to OSWRCH to switch to mode 7

.LOOP

 LDA B%,Y               \ Pass the Y-th byte of the B% table to OSWRCH
 JSR OSWRCH

 INY                    \ Increment the loop counter

 CPY #12                \ Loop back for the next byte until we have done all 10
 BNE LOOP               \ of them

.command

 LDX #LO(MESS2)         \ Set (Y X) to point to MESS2 ("LOAD Elite3")
 LDY #HI(MESS2)

 JSR OSCLI              \ Call OSCLI to run the OS command in MESS2, which loads
                        \ the ELITE3 binary to its load address of &5700

 JMP &5700              \ Jump to the start of the ELITE3 loader code at &5700

 NOP
 NOP
 NOP
 NOP

\ ******************************************************************************
\
\       Name: MESS2
\       Type: Variable
\   Category: Loader
\    Summary: The OS command string for loading the the ELITE3 binary
\
\ ******************************************************************************

.MESS2

 EQUS "LOAD Elite3"
 EQUB 13

\ ******************************************************************************
\
\       Name: 
\       Type: Subroutine
\   Category: Copy protection
\    Summary: Load hidden file from disc
\
\ ******************************************************************************

.L2FA4

 JSR L2FB8

 JMP command            \ Jump to command to load and run the next part of the
                        \ loader

 LDA #2                 \ Set PARAMS1+8 = 2, so the next OSWORD command seeks
 STA PARAMS1+8          \ track 2 on the disc

 LDA #127               \ Call OSWORD with A = 127 and (Y X) = PARAMS1
 LDX #LO(PARAMS1)
 LDY #HI(PARAMS1)
 JMP OSWORD

.L2FB8

 STA PARAMS2+7          \ Set PARAMS2+7 = A, so the next OSWORD command seeks
                        \ track A on the disc

 LDA #127               \ Call OSWORD with A = 127 and (Y X) = PARAMS2
 LDX #LO(PARAMS2)
 LDY #HI(PARAMS2)
 JMP OSWORD

\ ******************************************************************************
\
\       Name: B%
\       Type: Variable
\   Category: Screen mode
\    Summary: VDU commands for switching to a mode 7 screen
\
\ ******************************************************************************

.B%

 EQUB 22, 7             \ Switch to screen mode 7

 EQUB 23, 0, 10, 32     \ Set 6845 register R10 = 32
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "cursor start" register, which sets the
                        \ cursor start line at 0 with a fast blink rate

\ ******************************************************************************
\
\       Name: 
\       Type: Variable
\   Category: Copy protection
\    Summary: 
\
\ ******************************************************************************

.L2FD0

 EQUB &00, &00, &FF, &00, &57
 EQUB &FF, &FF, &03, &53, &26, &F6, &29, &00

\ ******************************************************************************
\
\       Name: PARAMS2
\       Type: Variable
\   Category: Copy protection
\    Summary: OSWORD parameter block for accessing a specific track on the disc
\
\ ******************************************************************************

.PARAMS2

 EQUB &FF               \ 0 = Drive = &FF (previously used drive and density)
 EQUD &FFFFFFFF         \ 1 = Data address (not required)
 EQUB 1                 \ 5 = Number of parameters = 1
 EQUB &69               \ 6 = Command = &69 (seek track)
 EQUB 2                 \ 7 = Parameter = 2 (track number)
 EQUB &00               \ 8 = The result of the OSWORD call is returned here

\ ******************************************************************************
\
\       Name: PARAMS1
\       Type: Variable
\   Category: Copy protection
\    Summary: OSWORD parameter block for accessing a specific track on the disc
\
\ ******************************************************************************

.PARAMS1

 EQUB &FF               \ 0 = Drive = &FF (previously used drive and density)
 EQUD &FFFFFFFF         \ 1 = Data address (not required)
 EQUB 2                 \ 5 = Number of parameters = 2
 EQUB &7A               \ 6 = Command = &7A (write special register)
 EQUB &12               \ 7 = Parameter = &12 (register = track number)
 EQUB 38                \ 8 = Parameter = &26 (track number)
 EQUB &00               \ 9 = The result of the OSWORD call is returned here

\ ******************************************************************************
\
\       Name: MESS1
\       Type: Variable
\   Category: Loader
\    Summary: The OS command string for switching to the disc filing system
\
\ ******************************************************************************

.MESS1

 EQUS "DISK"
 EQUB 13

\ ******************************************************************************
\
\       Name: 
\       Type: Variable
\   Category: Copy protection
\    Summary: 
\
\ ******************************************************************************

.L2FF5

 EQUB &19, &7A, &02, &01, &EC, &19, &00, &56
 EQUB &FF, &00, &00

\ ******************************************************************************
\
\ Save output/ELITE2.bin
\
\ ******************************************************************************

PRINT "S.ELITE2 ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD%
SAVE "output/ELITE2.bin", CODE%, P%, LOAD%