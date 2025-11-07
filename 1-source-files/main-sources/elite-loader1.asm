\ ******************************************************************************
\
\ BBC MICRO DISC ELITE GAME LOADER SOURCE (PART 1 OF 3)
\
\ BBC Micro disc Elite was written by Ian Bell and David Braben and is copyright
\ Acornsoft 1984
\
\ The code in this file has been reconstructed from a disassembly of the version
\ released on Ian Bell's personal website at http://www.elitehomepage.org/
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ The terminology and notations used in this commentary are explained at
\ https://elite.bbcelite.com/terminology
\
\ The deep dive articles referred to in this commentary can be found at
\ https://elite.bbcelite.com/deep_dives
\
\ ------------------------------------------------------------------------------
\
\ This source file contains the first of three game loaders for BBC Micro disc
\ Elite.
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary file:
\
\   * ELITE2.bin
\
\ ******************************************************************************

 INCLUDE "1-source-files/main-sources/elite-build-options.asm"

 _IB_DISC               = (_VARIANT = 1)
 _STH_DISC              = (_VARIANT = 2)
 _SRAM_DISC             = (_VARIANT = 3)

 GUARD &7C00            \ Guard against assembling over screen memory

\ ******************************************************************************
\
\ Configuration variables
\
\ ******************************************************************************

 CODE% = &2F00          \ The address where the code will be run

 LOAD% = &2F00          \ The address where the code will be loaded

 BYTEV = &020A          \ The BYTEV vector that we check as part of the copy
                        \ protection

 OSWRCH = &FFEE         \ The address for the OSWRCH routine

 OSBYTE = &FFF4         \ The address for the OSBYTE routine

 OSWORD = &FFF1         \ The address for the OSWORD routine

 OSCLI = &FFF7          \ The address for the OSCLI routine

\ ******************************************************************************
\
\       Name: ZP
\       Type: Workspace
\    Address: &0001 to &0002
\   Category: Workspaces
\    Summary: Important variables used by the loader
\
\ ******************************************************************************

 ORG &0001              \ Set the assembly address to &0001

.ZP

 SKIP 2                 \ Stores addresses used for moving content around

\ ******************************************************************************
\
\ ELITE LOADER
\
\ ******************************************************************************

 ORG CODE%              \ Set the assembly address to CODE%

\ ******************************************************************************
\
\       Name: BEGIN
\       Type: Subroutine
\   Category: Copy protection
\    Summary: Decrypt the loader code using a rolling EOR that uses the
\             decryption routine itself to seed the decryption
\
\ ******************************************************************************

.BEGIN

                        \ Note that the following copy protection code is
                        \ skipped in the unprotected version built here, as the
                        \ binaries are not encrypted and therefore do not need
                        \ to be decrypted
                        \
                        \ Instead, the execution address for the ELITE2 binary
                        \ points to ENTRY rather than BEGIN

 LDX p1c+1              \ Set X to the comparison value from the CMP instruction
                        \ below, which has the value p1d - BEGIN, which we use
                        \ as the offset of the first byte to decrypt (so we
                        \ decrypt from p1d onwards)

.p1

 LDA BEGIN              \ Fetch the first byte from BEGIN to act as the initial
                        \ seed for the rolling EOR process (this address gets
                        \ modified by the following to work through the whole
                        \ decryption routine)

.p1a

 EOR BEGIN,X            \ Set A = A EOR the X-th byte of the loader

 STA BEGIN,X            \ Store the decrypted byte in the X-th byte the loader

 INX                    \ Increment the pointer

 BNE p1a                \ Loop back until we have decrypted to the end of the
                        \ page

.p1b

 INC p1+1               \ Increment the low byte of the argument to the LDA
                        \ instruction at p1 above, so this would change it from
                        \ LDA BEGIN to LDA BEGIN+1, for example (so the next
                        \ time we do the EOR, we choose the next byte of the
                        \ decryption routine as the initial seed)

 BEQ p1d                \ If it equals zero (so the LDA BEGIN has worked itself
                        \ to LDA BEGIN+255 and round again to LDA BEGIN), jump
                        \ down to p1d as we have finally finished decrypting
                        \ the code

 LDA p1+1               \ Fetch the newly incremented low byte of the argument
                        \ to the LDA instruction at p1 above

.p1c

 CMP #(p1d - BEGIN)     \ If we have used all the bytes from the decryption
 BEQ p1b                \ routine as seeds, skip one byte and then continue on
                        \ to keep using seeds until we have done the whole page.
                        \ This means we decrypt using the following seeds:
                        \
                        \   * The contents of BEGIN
                        \   * The contents of BEGIN+1
                        \   * The contents of BEGIN+2
                        \   ...
                        \   * The contents of p1d-1
                        \   * The contents of p1d+1
                        \   ...
                        \   * The contents of BEGIN+254
                        \   * The contents of BEGIN+255
                        \
                        \ and then we are done

 JMP BEGIN              \ Otherwise look up to BEGIN to do another decryption
                        \ run, but using the next byte of the decryption routine
                        \ as the seed

.p1d

                        \ From this point on, the code is encrypted by
                        \ elite-checksum.py

 BIT BYTEV+1            \ If the high byte of BYTEV does not have bit 7 set (so
 BPL BEGIN              \ BYTEV is less than &8000, i.e. it's pointing to user
                        \ RAM rather than the ROM routine), then jump up to
                        \ BEGIN to hang machine, as it has presumably been
                        \ changed by someone trying to crack the game

                        \ Otherwise fall through into the now-decrypted loader
                        \ code to get on with loading the game

\ ******************************************************************************
\
\       Name: Elite loader
\       Type: Subroutine
\   Category: Loader
\    Summary: Reset vectors, change to mode 7, and load and run the ELITE3
\             loader
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   load3               Load and run the next part of the loader in the ELITE3
\                       binary
\
\ ******************************************************************************

.ENTRY

 LDA #0                 \ Call OSBYTE with A = 0 and X = 1 to fetch bit 0 of the
 LDX #1                 \ operating system version into X
 JSR OSBYTE

 LDY #0                 \ Set Y to 0 so we can use it as an index for setting
                        \ all the vectors to their default states

 SEI                    \ Disable all interrupts

 CPX #1                 \ If X = 1 then this is OS 1.20, so jump to os120
 BEQ os120

.os100

 LDA &D941,Y            \ Copy the Y-th byte from the default vector table at
 STA &0200              \ &D941 into location &0200 (this is surely supposed to
                        \ be the Y-th byte in &0200, i.e. STA &0200,Y, but it
                        \ isn't, which feels like a bug)

 INY                    \ Increment the loop counter

 CPY #54                \ Loop back to copy the next byte until we have copied
 BNE os100              \ 54 bytes (27 vectors)

 BEQ disk               \ Jump down to disk to skip the OS 1.20 routine

.os120

 LDA &FFB7              \ Set ZP(1 0) to the location stored in &FFB7-&FFB8,
 STA ZP                 \ which contains the address of the default vector table
 LDA &FFB8
 STA ZP+1

.ABCDEFG

 LDA (ZP),Y             \ Copy the Y-th byte from the default vector table into
 STA &0200,Y            \ the vector table in &0200

 INY                    \ Increment the loop counter

 CPY &FFB6              \ Compare the loop counter with the contents of &FFB6,
                        \ which contains the length of the default vector table

 BNE ABCDEFG            \ Loop back for the next vector until we have done them
                        \ all

.disk

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

.loop1

 LDA BLOCK,Y            \ Fetch the Y-th byte from BLOCK

 NOP                    \ This instruction has been disabled, so this loop does
                        \ nothing

 INY                    \ Increment the loop counter

 CPY #9                 \ Loop back to do the next byte until we have done 9 of
 BNE loop1              \ them

 LDY #0                 \ We are now going to send the 12 VDU bytes in the table
                        \ at B% to OSWRCH to switch to mode 7

.loop2

 LDA B%,Y               \ Pass the Y-th byte of the B% table to OSWRCH
 JSR OSWRCH

 INY                    \ Increment the loop counter

 CPY #12                \ Loop back for the next byte until we have done all 10
 BNE loop2              \ of them

.load3

 LDX #LO(MESS2)         \ Set (Y X) to point to MESS2 ("LOAD Elite3")
 LDY #HI(MESS2)

 JSR OSCLI              \ Call OSCLI to run the OS command in MESS2, which loads
                        \ the ELITE3 binary to its load address of &5700

 JMP &5700              \ Jump to the start of the ELITE3 loader code at &5700

 NOP                    \ These bytes appear to be unused
 NOP
 NOP
 NOP

\ ******************************************************************************
\
\       Name: MESS2
\       Type: Variable
\   Category: Loader
\    Summary: The OS command string for loading the ELITE3 binary
\
\ ******************************************************************************

.MESS2

 EQUS "LOAD Elite3"
 EQUB 13

\ ******************************************************************************
\
\       Name: LOAD
\       Type: Subroutine
\   Category: Copy protection
\    Summary: Load a hidden file from disc (not used in this version as disc
\             protection is disabled)
\
\ ******************************************************************************

.LOAD

 JSR p2                 \ Call p2 below

 JMP load3              \ Jump to load3 to load and run the next part of the
                        \ loader

 LDA #2                 \ Set PARAMS1+8 = 2, which is the track number in the
 STA PARAMS1+8          \ OSWORD parameter block

 LDA #127               \ Call OSWORD with A = 127 and (Y X) = PARAMS1 to seek
 LDX #LO(PARAMS1)       \ disc track 2
 LDY #HI(PARAMS1)
 JMP OSWORD

.p2

 STA PARAMS2+7          \ Set PARAMS2+7 = A, which is the track number in the
                        \ OSWORD parameter block

 LDA #127               \ Call OSWORD with A = 127 and (Y X) = PARAMS2 to seek
 LDX #LO(PARAMS2)       \ the disc track given in A
 LDY #HI(PARAMS2)
 JMP OSWORD

\ ******************************************************************************
\
\       Name: B%
\       Type: Variable
\   Category: Drawing the screen
\    Summary: VDU commands for switching to a mode 7 screen
\
\ ******************************************************************************

.B%

 EQUB 22, 7             \ Switch to screen mode 7

 EQUB 23, 0, 10, 32     \ Set 6845 register R10 = %00100000 = 32
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "cursor start" register, and bits 5 and 6
                        \ define the "cursor display mode", as follows:
                        \
                        \   * %00 = steady, non-blinking cursor
                        \
                        \   * %01 = do not display a cursor
                        \
                        \   * %10 = fast blinking cursor (blink at 1/16 of the
                        \           field rate)
                        \
                        \   * %11 = slow blinking cursor (blink at 1/32 of the
                        \           field rate)
                        \
                        \ We can therefore turn off the cursor completely by
                        \ setting cursor display mode %01, with bit 6 of R10
                        \ clear and bit 5 of R10 set

 SKIP 2                 \ These bytes appear to be unused

\ ******************************************************************************
\
\       Name: PARAMS3
\       Type: Variable
\   Category: Copy protection
\    Summary: OSWORD parameter block for loading the ELITE3 loader file (not
\             used in this version as disc protection is disabled)
\
\ ******************************************************************************

.PARAMS3

 EQUB &FF               \ 0 = Drive = &FF (previously used drive and density)
 EQUD &FFFF5700         \ 1 = Data address (&FFFF5700)
 EQUB 3                 \ 5 = Number of parameters = 3
 EQUB &53               \ 6 = Command = &53 (read data)
 EQUB 38                \ 7 = Track = 38
 EQUB 246               \ 8 = Sector = 246
 EQUB %00101001         \ 9 = Load 9 sectors of 256 bytes
 EQUB 0                 \ 10 = The result of the OSWORD call is returned here

\ ******************************************************************************
\
\       Name: PARAMS2
\       Type: Variable
\   Category: Copy protection
\    Summary: OSWORD parameter block for accessing a specific track on the disc
\             (not used in this version as disc protection is disabled)
\
\ ******************************************************************************

.PARAMS2

 EQUB &FF               \ 0 = Drive = &FF (previously used drive and density)
 EQUD &FFFFFFFF         \ 1 = Data address (not required)
 EQUB 1                 \ 5 = Number of parameters = 1
 EQUB &69               \ 6 = Command = &69 (seek track)
 EQUB 2                 \ 7 = Parameter = 2 (track number)
 EQUB 0                 \ 8 = The result of the OSWORD call is returned here

\ ******************************************************************************
\
\       Name: PARAMS1
\       Type: Variable
\   Category: Copy protection
\    Summary: OSWORD parameter block for accessing a specific track on the disc
\             (not used in this version as disc protection is disabled)
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
\       Name: BLOCK
\       Type: Variable
\   Category: Copy protection
\    Summary: These bytes are copied and decrypted by the loader routine (not
\             used in this version as disc protection is disabled)
\
\ ******************************************************************************

.BLOCK

 EQUB &19, &7A, &02, &01, &EC, &19, &00, &56
 EQUB &FF, &00, &00

\ ******************************************************************************
\
\ Save ELITE2.bin
\
\ ******************************************************************************

 PRINT "S.ELITE2 ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD%
 SAVE "3-assembled-output/ELITE2.bin", CODE%, P%, LOAD%