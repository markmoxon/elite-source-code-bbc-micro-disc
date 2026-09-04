\ ******************************************************************************
\
\ BBC MICRO DISC ELITE SIDEWAYS RAM LOADING SCREEN SOURCE
\
\ BBC Micro disc Elite was written by Ian Bell and David Braben and is copyright
\ Acornsoft 1984
\
\ The sideways RAM menu and loader were written by Stuart McConnachie in 1988-9
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
\ This source file contains the loading screen for the sideways RAM variant of
\ BBC Micro disc Elite.
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary file:
\
\   * SCREEN.bin
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

 CODE% = &7800          \ The address where the code will be run

 LOAD% = &7800          \ The address where the code will be loaded

 OSWRCH = &FFEE         \ The address for the OSWRCH routine

\ ******************************************************************************
\
\ ELITE LOADING SCREEN
\
\ ******************************************************************************

 ORG CODE%              \ Set the assembly address to CODE%

\ ******************************************************************************
\
\       Name: screenData
\       Type: Variable
\   Category: Loader
\    Summary: The Acornsoft mode 7 loading screen data
\
\ ******************************************************************************

.screenData

 INCBIN "1-source-files/images/$.SCREEN.bin"

\ ******************************************************************************
\
\       Name: LoadScreen
\       Type: Subroutine
\   Category: Loader
\    Summary: Print the screen data onto the mode 7 screen
\
\ ******************************************************************************

.LoadScreen

                        \ We print the screen data onto the screen memory, one
                        \ character at a time, which will display the loading
                        \ screen in mode 7
                        \
                        \ The screen data is exactly 1000 characters long,
                        \ though we only print 999 of these to prevent a newline
                        \ being inserted at the end, as that would scroll the
                        \ screen up by a line (the bottom-right character is a
                        \ space, so this is fine)
                        \
                        \ The following loop prints characters in batches of
                        \ 256, so we start the first inner loop at 25 to give
                        \ us the correct total at the end of the fourth outer
                        \ loop (so the first loop prints 256 - 25 = 231
                        \ characters, and the other three print 256 characters,
                        \ giving a total of 231 + 256 * 3 = 999 characters)

 LDY #25                \ We will use Y as a character counter in the inner loop
                        \ to work through each character, so set it to 25 to
                        \ skip to the correct number for the first outer loop

 LDX #4                 \ Set X to the outer loop counter

.loop1

 LDA screenData-25,Y    \ Set A to byte Y - 25 from the screen data, so we start
                        \ printing characters from the start of the screen data
                        \ (as we start with Y set to 25)

 JSR OSWRCH             \ Print the character in A

 INY                    \ Increment the inner loop counter in Y

 BNE loop1              \ Loop back until we have finished the inner loop (which
                        \ will print 231 characters on the first inner loop and
                        \ 256 on each of the next three loops)

 INC loop1+2            \ Increment the high byte of the LDA instruction above
                        \ to move on to the next page of bytes

 DEX                    \ Decrement the outer loop counter in X

 BNE loop1              \ Loop back until we have done all four outer loops

 RTS                    \ Return from the subroutine

 EQUB &20, &20          \ These bytes appear to be unused
 EQUB &20, &20

\ ******************************************************************************
\
\ Save SCREEN.bin
\
\ ******************************************************************************

 PRINT "S.SCREEN ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD%
 SAVE "3-assembled-output/SCREEN.bin", CODE%, P%, LOAD%