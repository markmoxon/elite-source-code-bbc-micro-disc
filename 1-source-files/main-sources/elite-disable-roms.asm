\ ******************************************************************************
\
\ DISC ELITE ROM DISABLER SOURCE
\
\ Elite was written by Ian Bell and David Braben and is copyright Acornsoft 1984
\
\ The sideways RAM menu and loader were written by Stuart McConnachie in 1988-9
\
\ The code on this site has been reconstructed from a disassembly of the version
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
\ This source file produces the following binary file:
\
\   * DISABLE.bin
\
\ ******************************************************************************

 INCLUDE "1-source-files/main-sources/elite-build-options.asm"

 CPU 1                  \ Switch to 65SC12 assembly, as this code contains a
                        \ 6502 Second Processor DEC A instruction

 _IB_DISC               = (_VARIANT = 1)
 _STH_DISC              = (_VARIANT = 2)
 _SRAM_DISC             = (_VARIANT = 3)

 GUARD &7C00            \ Guard against assembling over screen memory

\ ******************************************************************************
\
\ Configuration variables
\
\ ******************************************************************************

 CODE% = &7400          \ The address where the code will be run

 LOAD% = &7400          \ The address where the code will be loaded

 VIA = &FE00            \ Memory-mapped space for accessing internal hardware,
                        \ such as the video ULA, 6845 CRTC and 6522 VIAs (also
                        \ known as SHEILA)

 OSWRCH = &FFEE         \ The address for the OSWRCH routine

 OSBYTE = &FFF4         \ The address for the OSBYTE routine

 OSCLI = &FFF7          \ The address for the OSCLI vector

\ ******************************************************************************
\
\       Name: ZP
\       Type: Workspace
\    Address: &0070 to &0079
\   Category: Workspaces
\    Summary: Important variables used by the sideways RAM loader
\
\ ******************************************************************************

 ORG &0070

.ZP

 SKIP 2                 \ Stores addresses used for moving content around

\ ******************************************************************************
\
\ ELITE LOADER
\
\ ******************************************************************************

 ORG CODE%

\ ******************************************************************************
\
\       Name: DisableROMs
\       Type: Subroutine
\   Category: Loader
\    Summary: Fetch details on all the ROMs in the BBC Micro (i.e. the host) and
\             disable all except for BASIC and NFS
\
\ ******************************************************************************

.CheckPage

 LDA #LO(pageIs)        \ Print PAGE message
 STA ZP
 LDA #HI(pageIs)
 STA ZP+1
 JSR PrintString

 LDA #131               \ Print PAGE as hexadecimal number
 JSR OSBYTE
 TYA
 JSR PrintHexNumber
 TXA
 JSR PrintHexNumber

 CPY #&13               \ If PAGE > &1200, jump to DisableROMs to disable ROMs
 BCS DisableROMs
 CPY #&12
 BNE chek1
 CPX #0
 BEQ chek1
 BNE DisableROMs

.chek1

 LDA #LO(pageIsOK)      \ Print the "Page is OK" message
 STA ZP
 LDA #HI(pageIsOK)
 STA ZP+1
 JSR PrintString

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DisableROMs
\       Type: Subroutine
\   Category: Loader
\    Summary: Fetch details on all the ROMs in the BBC Micro (i.e. the host) and
\             disable all except for BASIC and NFS
\
\ ******************************************************************************

.DisableROMs

 LDA #LO(romList)       \ Print ROM list header
 STA ZP
 LDA #HI(romList)
 STA ZP+1
 JSR PrintString

 LDA &F4                \ Store the current ROM bank on the stack
 PHA

 LDX #15                \ We loop through each sideways ROM, so set a counter in
                        \ X to keep track of the bank number we are testing

.drom1

 STX &F4                \ Switch ROM bank X into memory
 STX VIA+&30

 LDA &02A1,X            \ If this ROM's entry in the ROM table at &02A1 is
 BNE drom2              \ non-zero then bank X does contain a ROM (as the table
                        \ contains the ROM type), so jump to drom2 to work out
                        \ what the ROM is and whether we need to disable it

 LDA #'.'               \ If we get here then bank X is empty, so print a "."
 JSR OSWRCH             \ to indicate that this ROM bank is empty

 JMP drom16             \ Jump to drom16 to move on to the next ROM bank

.drom2

                        \ We now check if ROM bank X contains the Elite ROM

 LDY #&F6               \ Set X = -10 to use as a counter for checking the ROM
                        \ title

.drom3

 LDA eliteMatch-&F6,Y   \ Fetch the next character of the ROM title message from
                        \ eliteMatch

 CMP &8009-&F6,Y        \ If the character from bank X does not match the same
 BNE drom4              \ character from the ROM title in eliteMatch, then bank
                        \ X is not the Elite ROM, so jump to drom4 to move on to
                        \ the next test

 INY                    \ Increment the character pointer into the ROM title in
                        \ bank X

 BNE drom3              \ Loop back until we have checked all the characters

 LDA #'E'               \ If we get here then bank X contains the correct ROM
 JSR OSWRCH             \ title for the Elite ROM, so print an "E"

 JMP drom16             \ Jump to drom16 to leave the ROM alone

.drom4

                        \ We now check if ROM bank X contains the DNFS ROM

 LDY #&F9               \ Set X = -7 to use as a counter for checking the ROM
                        \ title

.drom5

 LDA dnfsMatch-&F9,Y    \ Fetch the next character of the ROM title message from
                        \ dnfsMatch

 CMP &8009-&F9,Y        \ If the character from bank X does not match the same
 BNE drom6              \ character from the ROM title in dnfsMatch, then bank
                        \ X is not the DNFS ROM, so jump to drom6 to move on to
                        \ the next test

 INY                    \ Increment the character pointer into the ROM title in
                        \ bank X

 BNE drom5              \ Loop back until we have checked all the characters

                        \ If we get here then disable the DFS part of the ROM

 LDA #'n'               \ If we get here then bank X contains the correct ROM
 JSR OSWRCH             \ title for the DNFS ROM, so print an "n"

 TXA                    \ Set &0DFx = &40, where x is the ROM number in X, to
 ORA #&F0               \ disable just the DFS part of the ROM
 STA ZP
 LDA #&0D
 STA ZP+1
 LDA #&40
 LDY #0
 STA (ZP),Y

 JMP drom16             \ Jump to drom16 to leave the rest of the ROM alone

.drom6

                        \ We now check if ROM bank X contains the DFS ROM

 LDY #&FD               \ Set X = -3 to use as a counter for checking the ROM
                        \ title

.drom7

 LDA dfsMatch-&FD,Y     \ Fetch the next character of the ROM title message from
                        \ dfsMatch

 CMP &8009-&FD,Y        \ If the character from bank X does not match the same
 BNE drom8              \ character from the ROM title in dfsMatch, then bank
                        \ X is not the DFS ROM, so jump to drom8 to move on to
                        \ the next test

 INY                    \ Increment the character pointer into the ROM title in
                        \ bank X

 BNE drom7              \ Loop back until we have checked all the characters

 JMP drom15             \ If we get here then bank X contains the correct ROM
                        \ title for the DFS ROM, so jump to drom15 to disable it

.drom8

\                       \ We now check if ROM bank X contains the ANFS ROM

\LDY #&F6               \ Set X = -10 to use as a counter for checking the ROM
\                       \ title
\
\.drom9
\
\LDA anfsMatch-&F6,Y    \ Fetch the next character of the ROM title message from
\                       \ anfsMatch
\
\CMP &8009-&F6,Y        \ If the character from bank X does not match the same
\BNE drom10             \ character from the ROM title in anfsMatch, then bank
\                       \ X is not the ANFS ROM, so jump to drom10 to move on to
\                       \ the next test
\
\INY                    \ Increment the character pointer into the ROM title in
\                       \ bank X
\
\BNE drom9              \ Loop back until we have checked all the characters
\
\LDA #'A'               \ If we get here then bank X contains the correct ROM
\JSR OSWRCH             \ title for the ANFS ROM, so print an "A"
\
\JMP drom16             \ Jump to drom16 to leave the ROM alone
\
\.drom10

                        \ We now check if ROM bank X contains the NFS ROM

 LDY #&FD               \ Set X = -3 to use as a counter for checking the ROM
                        \ title

.drom11

 LDA nfsMatch-&FD,Y     \ Fetch the next character of the ROM title message from
                        \ nfsMatch

 CMP &8009-&FD,Y        \ If the character from bank X does not match the same
 BNE drom12             \ character from the ROM title in nfsMatch, then bank
                        \ X is not the NFS ROM, so jump to drom13 to move on to
                        \ the next test

 INY                    \ Increment the character pointer into the ROM title in
                        \ bank X

 BNE drom12             \ Loop back until we have checked all the characters

 LDA #'N'               \ If we get here then bank X contains the correct ROM
 JSR OSWRCH             \ title for the NFS ROM, so print an "N"

 JMP drom16             \ Jump to drom16 to leave the ROM alone

                        \ We now check if ROM bank X contains the NFS ROM with
                        \ four leading spaces

 LDY #&F9               \ Set X = -7 to use as a counter for checking the ROM
                        \ title

.drom12

 LDA nfsMatch-4-&F9,Y   \ Fetch the next character of the ROM title message from
                        \ nfsMatch-2

 CMP &8009-&F9,Y        \ If the character from bank X does not match the same
 BNE drom13             \ character from the ROM title in nfsMatch-2, then bank
                        \ X is not the NFS ROM, so jump to drom13 to move on to
                        \ the next test

 INY                    \ Increment the character pointer into the ROM title in
                        \ bank X

 BNE drom12             \ Loop back until we have checked all the characters

 LDA #'N'               \ If we get here then bank X contains the correct ROM
 JSR OSWRCH             \ title for the NFS ROM, so print an "N"

 JMP drom16             \ Jump to drom16 to leave the ROM alone

.drom13

                        \ We now check if ROM bank X contains the BASIC ROM

 LDY #&FB               \ Set X = -5 to use as a counter for checking the ROM
                        \ title

.drom14

 LDA basicMatch-&FB,Y   \ Fetch the next character of the ROM title message from
                        \ basicMatch

 CMP &8009-&FB,Y        \ If the character from bank X does not match the same
 BNE drom15             \ character from the ROM title in basicMatch, then bank
                        \ X is not the NFS ROM, so jump to drom13 to move on to
                        \ the next test

 INY                    \ Increment the character pointer into the ROM title in
                        \ bank X

 BNE drom14             \ Loop back until we have checked all the characters

 LDA #'B'               \ If we get here then bank X contains the correct ROM
 JSR OSWRCH             \ title for the BASIC ROM, so print a "B"

 JMP drom16             \ Jump to drom16 to leave the ROM alone

.drom15

                        \ If we get here then the ROM in bank X is not the Elite
                        \ ROM, NFS, DNFS, ANFS or BASIC, so disable the ROM in
                        \ bank X

 LDA #'x'               \ Print an 'x' to indicate that we are disabling this
 JSR OSWRCH             \ ROM

 TXA                    \ Set &0DF0+X = &FF, where X is the ROM number
 ORA #&F0               \
 STA ZP                 \ This will ensure that this ROM is disabled when BREAK
 LDA #&0D               \ is pressed
 STA ZP+1
 LDA #&FF
 LDY #0
 STA (ZP),Y

\TXA                    \ Set &02A1+X = 0, where X is the ROM number
\CLC                    \
\ADC #&A1               \ This would ensure that this ROM were disabled
\STA ZP                 \ immediately (though only until BREAK were pressed, as
\LDA #&02               \ this table is recreated by the MOS at that point, so
\STA ZP+1               \ this setting would only persist until then)
\LDA #0                 \
\LDY #0                 \ We don't need to disable ROMs immediately, as PAGE is
\STA (ZP),Y             \ is only changed once BREAK is pressed, but I've left
                        \ this code in here in case it's ever needed

.drom16

 DEX                    \ Decrement the bank number we are testing in X

 BMI drom17             \ If we have tested all 16 banks, jump to drom13 to
                        \ return from the subroutine

 JMP drom1              \ Otherwise loop back to drom1 to test the next ROM bank

.drom17

 PLA                    \ Switch back to the ROM bank number that we saved on
 STA &F4                \ the stack at the start of the routine
 STA VIA+&30

 LDX #LO(breakKey)      \ Set (Y X) to point to breakKey (the BREAK key string)
 LDY #HI(breakKey)

 JSR OSCLI              \ Call OSCLI to run the OS command in breakKey, which
                        \ defines the BREAK key with the BREAK key string

 LDA #LO(pressBreak)    \ Print "press BREAK" message
 STA ZP
 LDA #HI(pressBreak)
 STA ZP+1
 JSR PrintString

.drom18

 JMP drom18             \ Wait for the user to press BREAK

\ ******************************************************************************
\
\       Name: PrintHexNumber
\       Type: Subroutine
\   Category: Loader
\    Summary: A routine that prints a number in hexadecimal
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The number to print
\
\ ******************************************************************************

.PrintHexNumber

 PHA                    \ Store A on the stack so we can grab the low nibble
                        \ from it later

 LSR A                  \ Shift A right so that it contains the high nibble
 LSR A                  \ of the original argument
 LSR A
 LSR A

 JSR hexn1              \ Call hexn1 below to print 0-F for the high nibble

 PLA                    \ Restore A from the stack

 AND #%00001111         \ Extract the low nibble and fall through into hexn1
                        \ to print 0-F for the low nibble

.hexn1

 CMP #10                \ If A >= 10, skip the next three instructions
 BCS P%+7

 ADC #'0'               \ A < 10, so print the number in A as a digit 0-9 and
 JMP OSWRCH             \ return from the subroutine using a tail call

 ADC #'6'               \ A >= 10, so print the number in A as a digit A-F and
 JMP OSWRCH             \ return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: PrintString
\       Type: Subroutine
\   Category: Loader
\    Summary: A routine that prints a number in hexadecimal
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   ZP(1 0)             The address of the null-terminated string to print
\
\ ******************************************************************************

.PrintString

 LDY #0                 \ Set a character counter in Y

.pstr1

 LDA (ZP),Y             \ Set A to the Y-th character to print

 BEQ pstr2              \ If A = 0 then this is the end of the string, so jump
                        \ to pstr2 to return from the subroutine

 JSR OSWRCH             \ Print the character in A

 INY                    \ Increment the character counter

 BNE pstr1              \ Loop back to print the next character, up to a maximum
                        \ of 256 characters

.pstr2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: eliteMatch
\       Type: Variable
\   Category: Loader
\    Summary: The title of the Elite ROM, used to check whether the ROM is
\             already installed in a ROM bank
\
\ ******************************************************************************

.eliteMatch

 EQUS "SRAM ELITE"

\ ******************************************************************************
\
\       Name: dnfsMatch
\       Type: Variable
\   Category: Loader
\    Summary: The title of the DNFS ROM
\
\ ******************************************************************************

.dnfsMatch

 EQUS "DFS,NET"

\ ******************************************************************************
\
\       Name: dfsMatch
\       Type: Variable
\   Category: Loader
\    Summary: The title of the DFS ROM
\
\ ******************************************************************************

.dfsMatch

 EQUS "DFS"

\ ******************************************************************************
\
\       Name: anfsMatch
\       Type: Variable
\   Category: Loader
\    Summary: The title of the ANFS ROM
\
\ ******************************************************************************

.anfsMatch

 EQUS "Acorn ANFS"

\ ******************************************************************************
\
\       Name: nfsMatch
\       Type: Variable
\   Category: Loader
\    Summary: The title of the NFS ROM (which comes in two variants, one with
\             four spaces before the NET, another with no spaces)
\
\ ******************************************************************************

 EQUS "    "

.nfsMatch

 EQUS "NET"

\ ******************************************************************************
\
\       Name: basicMatch
\       Type: Variable
\   Category: Loader
\    Summary: The title of the BASIC ROM
\
\ ******************************************************************************

.basicMatch

 EQUS "BASIC"

\ ******************************************************************************
\
\       Name: breakKey
\       Type: Variable
\   Category: Loader
\    Summary: A key definition for BREAK
\
\ ******************************************************************************

.breakKey

 EQUS "KEY10CLS:P.''"
 EQUS '"'
 EQUS "User memory now starts at &"
 EQUS '"'
 EQUS ";~PAGE"
 EQUS ":IFPAGE>&1200P."
 EQUS '"'
 EQUS "which is still too high for Elite"
 EQUS '"'
 EQUS "ELSEP."
 EQUS '"'
 EQUS "which is good enough to run Elite"
 EQUS '"'
 EQUS "''"
 EQUS '"'
 EQUS "Press any key to load Elite over Econet"
 EQUS '"'
 EQUS "':A=GET:OS.("
 EQUS '"'
 EQUS "DIR"
 EQUS '"'
 EQUS "):OS.("
 EQUS '"'
 EQUS "DIR EliteCmdrs"
 EQUS '"'
 EQUS "):*Elite|M"
 EQUB 13

\ ******************************************************************************
\
\       Name: Message strings
\       Type: Variable
\   Category: Loader
\    Summary: Message strings to print
\
\ ******************************************************************************

.pageIs

 EQUB 10, 13
 EQUB 10, 13
 EQUS "User memory starts at address &"
 EQUB 0

.romList

 EQUB 10, 13
 EQUB 10, 13
 EQUS "This means there is not enough free"
 EQUB 10, 13
 EQUS "memory right now to run Elite over"
 EQUB 10, 13
 EQUS "Econet"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "I will try to free up more memory by"
 EQUB 10, 13
 EQUS "disabling all ROMs except NFS and BASIC"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "5432109876543210"
 EQUB 10, 13
 EQUB 0

.pressBreak

 EQUB 10, 13
 EQUB 10, 13
 EQUS "Press BREAK to free up as much memory"
 EQUB 10, 13
 EQUS "as possible so we can try again"
 EQUB 10, 13
 EQUB 10, 13
 EQUB 0

.pageIsOK

 EQUB 10, 13
 EQUB 10, 13
 EQUS "You can run Elite on this computer"
 EQUB 10, 13
 EQUB 10, 13
 EQUB 0

\ ******************************************************************************
\
\ Save FixPAGE.bin
\
\ ******************************************************************************

 PRINT "S.FixPAGE ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD%
 SAVE "3-assembled-output/FixPAGE.bin", CODE%, P%, LOAD%