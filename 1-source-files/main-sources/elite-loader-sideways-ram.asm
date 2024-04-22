\ ******************************************************************************
\
\ DISC ELITE SIDEWAYS RAM LOADER SOURCE
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
\ https://www.bbcelite.com/terminology
\
\ The deep dive articles referred to in this commentary can be found at
\ https://www.bbcelite.com/deep_dives
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary file:
\
\   * MNUCODE.bin
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

 IND1V = &0230          \ The IND1 vector

 LANGROM = &028C        \ Current language ROM in MOS workspace

 ROMTYPE = &02A1        \ Paged ROM type table in MOS workspace

 XFILEV = &0DBA         \ The extended FILE vector

 XIND1V = &0DE7         \ The extended IND1 vector

                        \ --- Mod: Code added for Scoreboard: ----------------->

 XIND2V = &0DEA         \ The extended IND2 vector

 XIND3V = &0DED         \ The extended IND3 vector

                        \ --- End of added code ------------------------------->

                        \ --- Mod: Code removed for Econet: ------------------->

\XX21 = &5600           \ The address of the ship blueprints lookup table in the
\                       \ current blueprints file
\
\E% = &563E             \ The address of the default NEWB flags in the current
\                       \ blueprints file

                        \ --- And replaced by: -------------------------------->

 XX21 = &5700           \ The address of the ship blueprints lookup table in the
                        \ current blueprints file

 E% = &573E             \ The address of the default NEWB flags in the current
                        \ blueprints file

                        \ --- End of replacement ------------------------------>

 ROM_XX21 = &8100       \ The address of the ship blueprints lookup table in the
                        \ sideways RAM image that we build

 ROM_E% = &813E         \ The address of the default NEWB flags in the sideways
                        \ RAM image that we build

                        \ --- Mod: Code added for Scoreboard: ----------------->

 TransmitCmdrData = &A008   \ The address of the TransmitCmdrData routine in the
                            \ Elite ROM

 GetNetworkDetails = &A0AD  \ The address of the GetNetworkDetails routine in
                            \ the Elite ROM

                        \ --- End of added code ------------------------------->

 VIA = &FE00            \ Memory-mapped space for accessing internal hardware,
                        \ such as the video ULA, 6845 CRTC and 6522 VIAs (also
                        \ known as SHEILA)

 OSXIND1 = &FF48        \ IND1V's extended vector handler

 OSWRCH = &FFEE         \ The address for the OSWRCH routine

 OSFILE = &FFDD         \ The address for the OSFILE routine

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

.P

 SKIP 2                 \ Temporary storage, used in a number of places

.R

 SKIP 1                 \ Temporary storage, used in a number of places

.S

 SKIP 1                 \ Temporary storage, used in a number of places

.T

 SKIP 1                 \ Temporary storage, used in a number of places

.U

 SKIP 1                 \ Temporary storage, used in a number of places

.V

 SKIP 2                 \ Temporary storage, typically used for storing an
                        \ address pointer

\ ******************************************************************************
\
\ ELITE LOADER
\
\ ******************************************************************************

 ORG CODE%

\ ******************************************************************************
\
\       Name: sram%
\       Type: Variable
\   Category: Loader
\    Summary: A table for storing the status of each ROM bank
\
\ ******************************************************************************

.sram%

 SKIP 16                \ Gets set to the RAM status of each ROM bank:
                        \
                        \   * 0 = does not contain writeable sideways RAM
                        \
                        \   * &FF = contains writeable sideways RAM

\ ******************************************************************************
\
\       Name: used%
\       Type: Variable
\   Category: Loader
\    Summary: A table for storing the status of each ROM bank
\
\ ******************************************************************************

.used%

 SKIP 16                \ Gets set to the usage status of each ROM bank:
                        \
                        \   * 0 = does not contain a ROM image
                        \
                        \   * &FF = contains a RAM image

\ ******************************************************************************
\
\       Name: dupl%
\       Type: Variable
\   Category: Loader
\    Summary: A table for storing the status of each ROM bank
\
\ ******************************************************************************

.dupl%

 SKIP 16                \ Gets set to the duplicate of each ROM bank:
                        \
                        \   * If dupl%+X contains X then bank X is not a
                        \     duplicate of a ROM in a higher bank number
                        \
                        \   * If dupl%+X > X then bank X is a duplicate of the
                        \     ROM in bank number dupl%+X

\ ******************************************************************************
\
\       Name: eliterom%
\       Type: Variable
\   Category: Loader
\    Summary: The number of the bank containing the Elite ROM
\
\ ******************************************************************************

.eliterom%

 EQUB &FF               \ Gets set to the bank number containing the Elite ROM
                        \ (or &FF if the ROM is not present)

\ ******************************************************************************
\
\       Name: proflag%
\       Type: Variable
\   Category: Loader
\    Summary: A flag to record whether we are running this on a co-processor
\
\ ******************************************************************************

.proflag%

 SKIP 1                 \ Gets set to the co-processor status:
                        \
                        \   * 0 = this is not a co-processor
                        \
                        \   * &FF = this is a co-processor

\ ******************************************************************************
\
\       Name: testbbc%
\       Type: Subroutine
\   Category: Loader
\    Summary: Entry point for the ROM-testing routine
\
\ ******************************************************************************

.testbbc%

 JMP TestBBC            \ Check the state of all 16 sideways ROM banks

\ ******************************************************************************
\
\       Name: testpro%
\       Type: Subroutine
\   Category: Loader
\    Summary: Entry point for the co-processor detection routine
\
\ ******************************************************************************

.testpro%

 JMP TestPro            \ Check to see if we are running on a co-processor

\ ******************************************************************************
\
\       Name: loadrom%
\       Type: Subroutine
\   Category: Loader
\    Summary: Entry point for the ROM-loading routine
\
\ ******************************************************************************

.loadrom%

 JMP LoadRom            \ Copy a pre-generated ship blueprints ROM image into
                        \ sideways RAM

\ ******************************************************************************
\
\       Name: makerom%
\       Type: Subroutine
\   Category: Loader
\    Summary: Entry point for the routine to create the Elite ROM image in
\             sideways RAM
\
\ ******************************************************************************

.makerom%

 JMP MakeRom            \ Create a ROM image in sideways RAM that contains all
                        \ the ship blueprint files

\ ******************************************************************************
\
\       Name: LoadRom
\       Type: Subroutine
\   Category: Loader
\    Summary: Copy a pre-generated ship blueprints ROM image from address &3400
\             into sideways RAM
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The bank number of sideways RAM to use for Elite
\
\ ******************************************************************************

.LoadRom

 LDA &F4                \ Switch to the ROM bank in X, storing the current ROM
 PHA                    \ bank on the stack
 STX &F4
 STX VIA+&30

 LDA #&34               \ Modify the address at lrom1 below so we copy the ROM
 STA lrom1+2            \ image from &3400

 LDA #&80               \ Modify the address at lrom2 below so we copy the ROM
 STA lrom2+2            \ image to sideways RAM at &8000

 LDY #0                 \ Set Y to use as a counter for each byte that is copied

 LDX #&40               \ Set X as a page counter for each page of 256 bytes
                        \ that is copied

.lrom1

 LDA &3400,Y            \ Copy the Y-th byte from &3400

.lrom2

 STA &8000,Y            \ To the Y-th byte of &8000

 INY                    \ Increment the byte counter

 BNE lrom1              \ Loop back until we have copied a whole page of 256
                        \ bytes

 INC lrom1+2            \ Modify the address at lrom1 to increment the source
                        \ address

 INC lrom2+2            \ Modify the address at lrom2 to increment the
                        \ destination address

 DEX                    \ Decrement the page counter

 BNE lrom1              \ Loop back until we have copied all &40 pages of the
                        \ ROM image

 LDX &F4                \ Update the paged ROM type table in MOS workspace with
 LDA &8000+6            \ the type of the copied ROM, which is in byte #6 of the
 STA ROMTYPE,X          \ ROM header

                        \ --- Mod: Code added for Econet: --------------------->

 JMP SetFileHandler     \ Set the file handler

                        \ --- End of added code ------------------------------->

 PLA                    \ Switch back to the ROM bank number that we saved on
 STA &F4                \ the stack at the start of the routine
 STA VIA+&30

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MakeRom
\       Type: Subroutine
\   Category: Loader
\    Summary: Create a ROM image in sideways RAM that contains all the ship
\             blueprint files
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The bank number of sideways RAM to use for Elite
\
\ ******************************************************************************

.MakeRom

 LDA &F4                \ Switch to the sideways RAM bank in X, storing the
 PHA                    \ current ROM bank on the stack
 STX &F4
 STX VIA+&30

                        \ We start by copying 256 bytes from eliteRomHeader into
                        \ the sideways RAM bank at address ROM, and zeroing the
                        \ next 256 bytes at ROM + &100
                        \
                        \ This sets up the sideways RAM bank with the ROM header
                        \ needed for our sideways RAM image

 LDY #0                 \ Set a loop counter in Y to step through the 256 bytes

.mrom1

 LDA eliteRomHeader,Y   \ Copy the Y-th byte from eliteRomHeader to ROM
 STA ROM,Y

 LDA #0                 \ Zero the Y-th byte at ROM + &100
 STA ROM_XX21,Y
 INY                    \ Increment the loop counter

 BNE mrom1              \ Loop back until we have copied and zeroed all 256
                        \ bytes

                        \ Next we load all the ship blueprint files into our
                        \ sideways RAM image, from D.MOA to D.MOP, combining
                        \ them into a single, complete set of ship blueprints

 LDA #LO(ROM+&200)      \ Set ZP(1 0) = ROM + &200
 STA ZP                 \
 LDA #HI(ROM+&200)      \ So the call to LoadShipFiles loads the ship blueprint
 STA ZP+1               \ files to location &200 in the sideways RAM image

 JSR LoadShipFiles      \ Load all the ship blueprint files into the sideways
                        \ RAM image to the location in ZP(1 0)

                        \ --- Mod: Code added for Econet: --------------------->

.SetFileHandler

                        \ --- End of added code ------------------------------->

                        \ Now that we have created our sideways RAM image, we
                        \ intercept calls to OSFILE so they call our custom file
                        \ handler routine, FileHandler, in sideways RAM
                        \
                        \ For this we need to use the extended vectors, which
                        \ work like the normal vectors, except they switch to a
                        \ specified ROM bank before calling the handler, and
                        \ switch back afterwards

 LDA XFILEV             \ Copy the extended vector XFILEV into XIND1V so we can
 STA XIND1V             \ pass any calls to XFILEV down the chain by calling
 LDA XFILEV+1           \ the IND1 vector
 STA XIND1V+1
 LDA XFILEV+2
 STA XIND1V+2

 LDA #LO(FileHandler)   \ Set the extended vector XFILEV to point to the
 STA XFILEV             \ FileHandler routine in the sideways RAM bank that we
 LDA #HI(FileHandler)   \ are building
 STA XFILEV+1           \ 
 LDA &F4                \ The format for the extended vector is the address of
 STA XFILEV+2           \ the handler in the first two bytes, followed by the
                        \ ROM bank number in the third byte, which we can fetch
                        \ from &F4

 LDA #LO(OSXIND1)       \ Point IND1V to IND1V's extended vector handler, so we
 STA IND1V              \ can pass any calls to XFILEV down the chain by calling
 LDA #HI(OSXIND1)       \ JMP (IND1V) from our custom file handler in the
 STA IND1V+1            \ FileHandler routine

                        \ --- Mod: Code added for Scoreboard: ----------------->

 LDA #LO(TransmitCmdrData)  \ Set the extended vector XIND2V to point to the
 STA XIND2V                 \ TransmitCmdrData routine in the sideways RAM bank
 LDA #HI(TransmitCmdrData)  \ that we are building, so we can call it using a
 STA XIND2V+1               \ JSR OSXIND2 instruction
 LDA &F4
 STA XIND2V+2

 LDA #LO(GetNetworkDetails) \ Set the extended vector XIND3V to point to the
 STA XIND3V                 \ GetNetworkDetails routine in the sideways RAM bank
 LDA #HI(GetNetworkDetails) \ that we are building, so we can call it using a
 STA XIND3V+1               \ JSR OSXIND3 instruction
 LDA &F4
 STA XIND3V+2

                        \ --- End of added code ------------------------------->

 PLA                    \ Switch back to the ROM bank number that we saved on
 STA &F4                \ the stack at the start of the routine
 STA VIA+&30

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LoadShipFiles
\       Type: Subroutine
\   Category: Loader
\    Summary: Load all the ship blueprint files into sideways RAM
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   ZP(1 0)             The address in sideways RAM to load the ship files
\
\ ******************************************************************************

.LoadShipFiles

 LDA #'A'               \ Set the ship filename to D.MOA, so we start the
 STA shipFilename+4     \ loading process from this file

.ship1

 LDA #'.'               \ Print a full stop to show progress during loading
 JSR OSWRCH

 LDA #LO(XX21)          \ Set the load address in bytes 2 and 3 of the OSFILE 
 STA osfileBlock+2      \ block to XX21, which is where ship blueprint files
 LDA #HI(XX21)          \ get loaded in the normal disc version
 STA osfileBlock+3      \
 LDA #&FF               \ We set the address to the form &FFFFxxxx to ensure
 STA osfileBlock+4      \ that the files are loaded into the I/O Processor
 STA osfileBlock+5

 LDA #0                 \ Set byte 6 to zero to terminate the block
 STA osfileBlock+6

 LDX #LO(osfileBlock)   \ Set (Y X) = osfileBlock
 LDY #HI(osfileBlock)

 LDA #&FF               \ Call OSFILE with A = &FF to load the file specified
 JSR OSFILE             \ in the block, so this loads the ship blueprint file
                        \ to XX21

                        \ We now loop through each blueprint in the currently
                        \ loaded ship file, processing each one in turn to
                        \ merge them into one big ship blueprint file

 LDX #0                 \ Set a loop counter in X to work through the ship
                        \ blueprints

.ship2

 TXA                    \ Store the blueprint counter on the stack so we can
 PHA                    \ retrieve it after the call to ProcessBlueprint

 JSR ProcessBlueprint   \ Process blueprint entry X from the loaded blueprint
                        \ file, copying the blueprint into sideways RAM if it
                        \ hasn't already been copied

 PLA                    \ Restore the blueprint counter
 TAX

 INX                    \ Increment the blueprint counter

 CPX #31                \ Loop back until we have processed all 31 blueprint
 BNE ship2              \ entries in the blueprint file

 INC shipFilename+4     \ Increment the fifth character of the ship blueprint
                        \ filename so we step through them from D.MOA to D.MOP

 LDA shipFilename+4     \ Loop back until we have processed files D.MOA through
 CMP #'Q'               \ D.MOP
 BNE ship1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ProcessBlueprint
\       Type: Subroutine
\   Category: Loader
\    Summary: Process a blueprint entry from the loaded blueprint file, copying
\             the blueprint into sideways RAM if it hasn't already been copied
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The blueprint number to process (0 to 30)
\
\   ZP(1 0)             The address in sideways RAM to store the next ship
\                       blueprint that we add
\
\ ******************************************************************************

.proc1

                        \ If we get here then the address of the blueprint we
                        \ are adding to sideways RAM is outside of the loaded
                        \ blueprint file, so we just store the address in the
                        \ ROM_XX21 table and move on to the next blueprint
                        \
                        \ The address of the blueprint we are adding is in
                        \ P(1 0), and A still contains the high byte of P(1 0)

 STA ROM_XX21+1,Y       \ Set the X-th address in ROM_XX21 to (A P), which
 LDA P                  \ stores P(1 0) in the table as A contains the high
 STA ROM_XX21,Y         \ byte

.proc2

 RTS                    \ Return from the subroutine

.proc3

                        \ If we get here then we are processing the second
                        \ blueprint in ship blueprint file D.MOB
                        \
                        \ This means that the ROM_XX21 table contains the
                        \ addresses from the previous file, D.MOA, so the
                        \ second slot contains the address of the Coriolis space
                        \ station, as that's what D.MOA contains
                        \
                        \ We want the ROM_XX21 table to contain the Dodo space
                        \ station address, so we copy the Coriolis address to
                        \ coriolisStation(1 0), and then jump to proc5 so the
                        \ Dodo space station address gets written into ROM_XX21,
                        \ overwriting the Coriolis address
                        \
                        \ When intercepting OSFILE in FileHandler, we ensure
                        \ that the correct station blueprint is loaded from
                        \ sideways RAM, depending on the filename that is being
                        \ loaded

 LDA ROM_XX21,Y         \ Fetch the address of the Coriolis blueprint from
 STA coriolisStation    \ sideways RAM and store in coriolisStation(1 0)
 LDA ROM_XX21+1,Y
 STA coriolisStation+1

 BNE proc5              \ Jump to proc5 to process the Dodo blueprint and insert
                        \ its address into ROM_XX21, overwriting the Coriolis
                        \ address (this BNE is effectively a JMP as the high
                        \ byte of the Coriolis blueprint address is never zero)

.ProcessBlueprint

 TXA                    \ Set Y = X * 2
 ASL A                  \
 TAY                    \ So we can use Y as an index into the XX21 table to
                        \ fetch the address for blueprint number X in the
                        \ current blueprint file, as the XX21 table has two
                        \ bytes per entry (as each entry is an address)
                        \
                        \ I will refer to the two-byte address in XX21+Y as "the
                        \ X-th address in XX21", to keep things simple

 LDA XX21+1,Y           \ Set A to the high byte of the address of the blueprint
                        \ we are processing (i.e. blueprint number X)

 BEQ proc2              \ If the high byte of the address is zero then blueprint
                        \ number X is blank and has no ship allocated to it, so
                        \ jump to proc2 to return from the subroutine, as there
                        \ is nothing to process

 CPX #1                 \ If X = 1 then this is the second blueprint, which is
 BNE proc4              \ always the space station, so jump to proc4 if this
                        \ isn't the station

 LDA shipFilename+4     \ If we are processing blueprint file B.MOB then jump to
 CMP #'B'               \ proc3, so we can save the address of the Coriolis
 BEQ proc3              \ space station blueprint address before processing the
                        \ blueprint

.proc4

 LDA ROM_XX21+1,Y       \ If blueprint X in the ROM_XX21 table in sideways RAM
 BNE proc2              \ already has blueprint data associated with it, then
                        \ the X-th address in ROM_XX21 + Y will be non-zero,
                        \ so jump to proc2 to return from the subroutine and
                        \ move on to the next blueprint in the file

.proc5

                        \ If we get here then the blueprint table in sideways
                        \ RAM does not contain any data for blueprint X, so we
                        \ need to fill it with the data for blueprint X from the
                        \ file we have loaded at address XX21

 LDA ZP                 \ Set the X-th address in the ROM_XX21 table in sideways
 STA ROM_XX21,Y         \ RAM to the value of ZP(1 0), so this entry contains
 LDA ZP+1               \ the address where we should store the next ship
 STA ROM_XX21+1,Y       \ blueprint (as we are about to copy the blueprint data
                        \ to this address in sideways RAM)

 LDA E%,X               \ Set the X-th entry in the ROM_E% table in sideways
 STA ROM_E%,X           \ RAM to the X-th entry from the E% table in the loaded
                        \ ship blueprints file, so this sets the correct default
                        \ NEWB byte for the ship blueprint we are copying to
                        \ sideways RAM

 LDA XX21,Y             \ Set P(1 0) to the X-th address in the XX21 table,
 STA P                  \ which is the address of the blueprint X data within
 LDA XX21+1,Y           \ the ship blueprint file that we have loaded at address
 STA P+1				\ XX21

 CMP #HI(XX21)          \ Ship blueprint files are 9 pages in size, so if the
 BCC proc1              \ high byte of the address in P(1 0) is outside of the
 CMP #HI(XX21) + 10     \ range XX21 to XX21 + 9, it is not pointing to an
 BCS proc1              \ an address within the blueprint file that we loaded,
                        \ so jump to proc1 to store P(1 0) in the ROM_XX21 table
                        \ in sideways RAM and return from the subroutine, so we
                        \ just set the address but don't copy the blueprint data
                        \ into sideways RAM
                        \
                        \ For example, the missile blueprint is stored above
                        \ screen memory in the disc version (at &7F00), so this
                        \ ensures that the address is set correctly in the
                        \ ROM_XX21 table, even though it's outside the blueprint
                        \ file itself

 JSR SetEdgesOffset     \ Set the correct edges offset for the blueprint we are
                        \ currently processing (as the edges offset can point to
                        \ the edges data in a different blueprint, so we need to
                        \ make sure this value is calculated correctly to point
                        \ to the right blueprint within sideways RAM)

                        \ We now want to copy the data for blueprint X into
                        \ sideways RAM
                        \
                        \ We know the address of the start of the blueprint
                        \ data (we stored it in P(1 0) above), but we don't
                        \ know the address of the end of the data, so we
                        \ calculate that now
                        \
                        \ We do this by looking at the addresses of the data for
                        \ all the blueprints after blueprint X in the file, and
                        \ picking the lowest address that is greater than the
                        \ address for blueprint X
                        \
                        \ This will give us the address of the blueprint data
                        \ for the blueprint whose data is directly after the
                        \ data for blueprint X in memory, which is the same as
                        \ the address of the end of blueprint X
                        \
                        \ We don't need to check blueprints in earlier positions
                        \ as blueprints are inserted into memory in the order in
                        \ which they appear in the blueprint file
                        \
                        \ We implement the above by keeping track of the lowest
                        \ address we have found in (S R), as we loop through the
                        \ blueprints after blueprint X
                        \
                        \ We loop through the blueprints by incrementing Y by 2
                        \ on each iteration, so I will refer to the address of
                        \ the blueprint at index Y in XX21 as "the Y-th address
                        \ in XX21", to keep things simple

 LDA #LO(XX21)          \ Set (S R) to the address of the end of the ship
 STA R                  \ blueprint file (which takes up 9 pages)
 TAY                    \
 LDA #HI(XX21) + 10     \ Also set Y = 0, as the blueprint file load at &5600,
 STA S                  \ so the low byte is zero

.proc6

 LDA P                  \ If P(1 0) >= the Y-th address in XX21, jump to proc7
 CMP XX21,Y             \ to move on to the next address in XX21
 LDA P+1
 SBC XX21+1,Y
 BCS proc7

 LDA XX21,Y             \ If the Y-th address in XX21 >= (S R), jump to proc7
 CMP R                  \ to move on to the next address in XX21
 LDA XX21+1,Y
 SBC S
 BCS proc7

                        \ If we get here then the following is true:
                        \
                        \   P(1 0) < the Y-th address in XX21 < (S R)
                        \
                        \ P(1 0) is the address of the start of blueprint X
                        \ and (S R) contains the lowest blueprint address we
                        \ have found so far, so this sets (S R) to the current
                        \ blueprint address if it is smaller than the lowest
                        \ address we already have
                        \
                        \ By the end of the loop, (S R) will contain the address
                        \ we need (i.e. that of the end of blueprint X)

 LDA XX21,Y             \ Set (S R) = the Y-th address in XX21
 STA R
 LDA XX21+1,Y
 STA S

.proc7

 INY                    \ Increment the address counter in Y to point to the
 INY                    \ next address in XX21

 CPY #31 * 2            \ Loop back until we have worked our way to the end of
 BNE proc6              \ the whole set of blueprints

                        \ We now have the following:
                        \
                        \   * P(1 0) is the address of the start of the
                        \     blueprint data to copy
                        \
                        \   * (S R) is the address of the end of the blueprint
                        \     data to copy
                        \
                        \   * ZP(1 0) is the address to which we need to copy
                        \     the blueprint data
                        \
                        \ So we now copy the blueprint data into sideways RAM

 LDY #0                 \ Set a byte counter in Y

.proc8

 LDA (P),Y              \ Copy the Y-th byte of P(1 0) to the Y-th byte of
 STA (ZP),Y             \ ZP(1 0)

 INC P                  \ Increment P(1 0)
 BNE proc9
 INC P+1

.proc9

 INC ZP                 \ Increment ZP(1 0)
 BNE proc10
 INC ZP+1

.proc10

 LDA P                  \ Loop back to copy the next byte until P(1 0) = (S R),
 CMP R                  \ starting by checking the low bytes
 BNE proc8

 LDA P+1                \ And then the high bytes
 CMP S
 BNE proc8

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SetEdgesOffset
\       Type: Subroutine
\   Category: Loader
\    Summary: Calculate the edges offset within sideways RAM for the blueprint
\             we are processing and set it in bytes #3 and #16 of the blueprint
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The blueprint number to process (0 to 30)
\
\   Y                   The offset within the XX21 table for blueprint X
\
\   P(1 0)              The address of the ship blueprint in the loaded ship
\                       blueprint file
\
\   ZP(1 0)             The address in sideways RAM where we are storing the
\                       ship blueprint that we are processing
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   X                   X is preserved
\
\   Y                   Y is preserved
\
\ ******************************************************************************

.SetEdgesOffset

 TYA                    \ Store X and Y on the stack so we can preserve them
 PHA                    \ through the subroutine
 TXA
 PHA

                        \ We start by calculating the following:
                        \
                        \   (U T) = P(1 0) + offset to the edges data
                        \
                        \ where the offset to the edges data is stored in bytes
                        \ #3 and #16 of the blueprint at P(1 0)
                        \
                        \ So (U T) will be the address of the edges data for
                        \ blueprint X within the loaded blueprints file

 CLC                    \ Clear the C flag for the following addition

 LDY #3                 \ Set A to byte #3 of the ship blueprint, which contains
 LDA (P),Y              \ the low byte of the offset to the edges data

 ADC P                  \ Set T = A + P
 STA T                  \
                        \ so this adds the low bytes of the calculation

 LDY #16                \ Set A to byte #16 of the ship blueprint, which
 LDA (P),Y              \ contains the high byte of the offset to the edges data

 ADC P+1                \ Set U = A + P+1
 STA U                  \
                        \ so this adds the high bytes of the calculation

 LDY #0                 \ We now step through the addresses in the XX21 table,
                        \ so set an address counter in Y, which we will
                        \ increment by 2 for each iteration (I will refer to
                        \ the address at index Y as the Y-th address, to keep
                        \ things simple)

 LDX #0                 \ We will store the blueprint number that contains the
                        \ edges data in X, so initialise it to zero

 LDA #LO(XX21)          \ Set V(1 0) to the address of the XX21 table in the
 STA V                  \ loaded blueprints file, which is the address of the
 LDA #HI(XX21)          \ start of the blueprints file (as XX21 is the first
 STA V+1                \ bit of data in the file)

.edge1

 LDA XX21,Y             \ If the Y-th address in XX21 >= (U T), jump to edge3 to
 CMP T                  \ move on to the next address in XX21
 LDA XX21+1,Y
 SBC U
 BCS edge3

.edge2

 LDA XX21,Y             \ If the Y-th address in XX21 < V(1 0), jump to edge3 to
 CMP V                  \ move on to the next address in XX21
 LDA XX21+1,Y
 SBC V+1
 BCC edge3

                        \ If we get here then the address in the Y-th entry in
                        \ XX21 is between V(1 0) and (U T), so it's between the
                        \ start of the loaded file and the edges data
                        \
                        \ We now store the entry number (in Y) in X, and update
                        \ V(1 0) so it contains the Y-th entry in XX21, as this
                        \ entry in the blueprints file contains the edges data

 LDA XX21,Y             \ Set V(1 0) to the Y-th address in XX21
 STA V
 LDA XX21+1,Y
 STA V+1

 TYA                    \ Set X = Y
 TAX

.edge3

 INY                    \ Increment the address counter in Y to point to the
 INY                    \ next address in XX21

 CPY #31 * 2            \ Loop back until we have worked our way through the
 BNE edge1              \ whole table

                        \ At this point, X is the number of the blueprint within
                        \ the loaded blueprint file that contains the edges data
                        \ for the blueprint we are processing, and (U T)
                        \ contains the address of the edges data for the
                        \ blueprint we are processing
                        \
                        \ We now use these values to calculate the offset for
                        \ the edges data within sideways RAM
                        \
                        \ First, we take the address in (U T), which is an
                        \ address within the X-th blueprint in the loaded ship
                        \ blueprint file, and convert it to the equivalent
                        \ address within the sideways RAM blueprints
                        \
                        \ We can do this by subtracting the address of the X-th
                        \ blueprint in the loaded ship file, and adding the
                        \ address of the X-th blueprint in sideways RAM

 SEC                    \ Set (U T) = (U T) - the X-th address in XX21
 LDA T
 SBC XX21,X
 STA T
 LDA U
 SBC XX21+1,X
 STA U

 CLC                    \ Set (U T) = (U T) + the X-th address in ROM_XX21
 LDA ROM_XX21,X
 ADC T
 STA T
 LDA ROM_XX21+1,X
 ADC U
 STA U

                        \ We now have the address of the edges data in sideways
                        \ RAM in (U T), so we can convert this to an offset by
                        \ subtracting the address of the start of the blueprint
                        \ we are storing, which is in ZP(1 0)

 SEC                    \ Set the edges data offset in bytes #3 and #16 in the
 LDA T                  \ blueprint in sideways RAM to the following:
 SBC ZP                 \
 LDY #3                 \   (U T) - ZP(1 0)
 STA (P),Y
 LDA U
 SBC ZP+1
 LDY #16
 STA (P),Y

 PLA                    \ Restore X and Y from the stack so they are preserved
 TAX                    \ through the subroutine
 PLA
 TAY

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TestBBC
\       Type: Subroutine
\   Category: Loader
\    Summary: Fetch details on all the ROMs in the BBC Micro (i.e. the host) and
\             populate the sram%, used%, dupl% and eliterom% variables
\
\ ******************************************************************************

.TestBBC

 LDA &F4                \ Store the current ROM bank on the stack
 PHA

 LDX #15                \ We loop through each sideways ROM, so set a counter in
                        \ X to keep track of the bank number we are testing

.tbbc1

 STX &F4                \ Switch ROM bank X into memory
 STX VIA+&30

                        \ We start by checking if ROM bank X contains RAM, and
                        \ update the X-th entry in the sram% table accordingly

 LDA &8000+6            \ Set A to the type of ROM in bank X, which is in byte
 PHA                    \ #6 of the ROM header, and store it on the stack
 
 EOR #%00000001         \ Flip bit 0 of the ROM type and store the updated type
 STA &8000+6            \ in byte #6 of bank X

 CMP &8000+6            \ If the flipped bit was not stored properly then this
 BNE tbbc2              \ bank is not writeable sideways RAM, so jump to tbbc2
                        \ to move on to the next test

 DEC sram%,X            \ Otherwise this bank is sideways RAM, so decrement the
                        \ X-th entry in the sram% table to &FF

.tbbc2

 PLA                    \ Retrieve the type of ROM in bank X and store it in
 STA &8000+6            \ byte #6 of the ROM header, to reverse the above change

                        \ We now check if ROM bank X contains a ROM image, and
                        \ update the X-th entry in the used% table accordingly

 LDY &8000+7            \ Set Y to the offset of the ROM's copyright message,
                        \ which is in byte #7 of bank X

 LDX #&FC               \ Set X = -4 to use as a counter for checking whether
                        \ bank X contains a copyright message, in which case it
                        \ contains a ROM image
                        \
                        \ We do this by checking for the four copyright
                        \ characters from copyMatch (the negation makes the loop
                        \ check slightly simpler)

.tbbc3

 LDA copyMatch-&FC,X    \ Fetch the next character of the copyright message from
                        \ copyMatch

 CMP &8000,Y            \ If the character from bank X does not match the same
 BNE tbbc4              \ character from the copyright message in copyMatch,
                        \ then bank X is not a valid ROM, so jump to tbbc4 to
                        \ the top four bits of the first byte in ROM bank X and
                        \ move on to the next test

 INY                    \ Increment the character pointer into the copyright
                        \ message in bank X

 INX                    \ Increment the character pointer into the copyright
                        \ message in copyMatch

 BNE tbbc3              \ Loop back until we have checked all four characters

 LDX &F4                \ If we get here then bank X contains the correct
 DEC used%,X            \ copyright string for identifying a ROM, so decrement
                        \ the X-th entry in the used% table to &FF

 JMP tbbc5              \ Jump to tbbc5 to skip the following

.tbbc4

                        \ If we get here then ROM bank X is not a valid ROM

 LDX &F4                \ Set the first byte in ROM bank X to &FX (e.g. set it
 TXA                    \ to &F9 when X = 9), assuming it contains writeable
 ORA #&F0               \ sideways RAM
 STA &8000              \
                        \ I am not sure why we do this

.tbbc5

                        \ We now check if ROM bank X contains the Elite ROM, and
                        \ update the bank number in eliterom% if it does

 BIT eliterom%          \ If bit 7 of eliterom% is clear then we have already
 BPL tbbc7              \ set it to the bank number of the Elite ROM, so jump to
                        \ tbbc7 to move on to the next test
                        \
                        \ Otherwise eliterom% is still set to the default value
                        \ of &FF, so we now check bank X to see if it has the
                        \ correct title for the Elite ROM

 LDY #&F2               \ Set X = -14 to use as a counter for checking whether
                        \ bank X contains a copyright message, in which case it
                        \ contains a ROM image
                        \
                        \ We do this by checking for the 10 title characters in
                        \ titleMatch and the four characters in copyMatch (the
                        \ negation makes the loop check slightly simpler)

.tbbc6

 LDA titleMatch-&F2,Y   \ Fetch the next character of the ROM title message from
                        \ titleMatch

 CMP &8009-&F2,Y        \ If the character from bank X does not match the same
 BNE tbbc7              \ character from the ROM title in titleMatch, then bank
                        \ X is not the Elite ROM, so jump to tbbc7 to move on to
                        \ the next test

 INY                    \ Increment the character pointer into the ROM title in
                        \ bank X

 BNE tbbc6              \ Loop back until we have checked all 14 characters

 STX eliterom%          \ If we get here then bank X contains the correct ROM
                        \ title for the Elite ROM, so store the bank number in
                        \ eliterom%

.tbbc7

                        \ We now check if ROM bank X contains a duplicate ROM,
                        \ update the X-th entry in the dupl% table accordingly

 TXA                    \ Copy the bank number we are checking into A

                        \ We now loop through each of the sideways ROM banks
                        \ that we have already checked to see whether any of
                        \ them contain the same ROM as in in bank X

 LDY #16                \ Set a counter in Y to keep track of the bank number we
                        \ are testing against bank X, starting from the highest
                        \ bank number and working down to bank X

.tbbc8

 STX &F4                \ Switch ROM bank X into memory
 STX VIA+&30

 DEY                    \ Decrement the ROM bank counter in Y, so it counts down
                        \ from 15 to X over the course of the loop

 TYA                    \ If Y = X then we have checked all the ROMs that we
 CMP &F4                \ have already processed, so jump tbbc10 with Y set to X
 BEQ tbbc10             \ to store this value in the dupl% to indicate that this
                        \ ROM is not a duplicate of a ROM in a higher bank

 TYA                    \ Set (&F7 &F6) = (&7F ~Y)
 EOR #%11111111         \
 STA &F6                \ So this goes from &7FF0 to &7FFF as Y decrements from
 LDA #&7F               \ 15 to 1, and (&F7 &F6) + Y is always &7FFF
 STA &F7                \
                        \ This seems wrong, as (&F7 &F6) + Y should start from
                        \ &8000 (though there's no harm as location &7FFF will
                        \ always contain the same value, irrespective of which
                        \ ROM bank is switched in)

.tbbc9

 STX &F4                \ Switch ROM bank X into memory
 STX VIA+&30

 LDA (&F6),Y            \ Fetch the Y-th byte from (&F7 &F6)

 STY &F4                \ Switch ROM bank Y into memory
 STY VIA+&30

 CMP (&F6),Y            \ Compare the byte from ROM bank X with the same byte
                        \ from ROM bank Y

 BNE tbbc8              \ If the bytes do not match, jump to tbbc8 to move on
                        \ to the next ROM, as the ROM in bank Y does not match
                        \ the ROM in bank X

 INC &F6                \ Increment (&F7 &F6), starting with the low byte

 BNE tbbc9              \ Loop back to tbbc9 until we have checked the first
                        \ 256 bytes

 INC &F7                \ Increment the high byte of (&F7 &F6) to move on to
                        \ the next page

 LDA &F7                \ Loop back to keep checking until (&F7 &F6) = &8400,
 CMP #&84               \ by which point we have checked the first three pages
 BNE tbbc9              \ of the ROM

                        \ If we get here then the first three pages of ROM bank
                        \ X match the first three pages of ROM bank Y, so we can
                        \ assume the ROMs are identical, so we fall through to
                        \ set the value of dupl% + X to Y to record that bank X
                        \ is a duplicate

.tbbc10

 TYA                    \ Set the dupl% flag for bank X to Y (so this will be
 STA dupl%,X            \ set to X is bank X is not a duplicate of a ROM in a
                        \ higher bank, otherwise it will be set to the bank
                        \ number of the ROM that bank X is a duplicate of)

 DEX                    \ Decrement the bank number we are testing in X

 BMI tbbc11             \ If we have tested all 16 banks, jump to tbbc11 to
                        \ return from the subroutine

 JMP tbbc1              \ Otherwise loop back to tbbc1 to test the next ROM bank

.tbbc11

 PLA                    \ Switch back to the ROM bank number that we saved on
 STA &F4                \ the stack at the start of the routine
 STA VIA+&30

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TestPro
\       Type: Subroutine
\   Category: Loader
\    Summary: Test whether we are running this on a co-processor
\
\ ******************************************************************************

.TestPro

 LDA #0                 \ If this is a co-processor, then the DEC A instruction
 DEC A                  \ will be supported and will decrement A to &FF, but if
                        \ this is not a co-processor, the DEC A instruction will
                        \ have no effect

 STA proflag%           \ Set proflag% to A, which will be &FF if this is a
                        \ co-processor, 0 otherwise

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: titleMatch
\       Type: Variable
\   Category: Loader
\    Summary: The title of the Elite ROM, used to check whether the ROM is
\             already installed in a ROM bank
\
\ ******************************************************************************

.titleMatch

 EQUS "SRAM ELITE"      \ The ROM title

\ ******************************************************************************
\
\       Name: copyMatch
\       Type: Variable
\   Category: Loader
\    Summary: The start of the copyright string from a valid ROM bank, used to
\             check whether a ROM bank contains a ROM image
\
\ ******************************************************************************

.copyMatch

 EQUB 0                 \ NULL and "(C)", required for the MOS to recognise the
 EQUS "(C)"             \ ROM

\ ******************************************************************************
\
\       Name: osfileBlock
\       Type: Variable
\   Category: Loader
\    Summary: OSFILE configuration block for loading a ship blueprint file
\
\ ******************************************************************************

.osfileBlock

 EQUW shipFilename      \ The address of the filename to load

 EQUD &FFFF0000 + XX21  \ Load address of the file

 EQUD &00000000         \ Execution address (not used when loading a file)

 EQUD &00000000         \ Start address (not used when loading a file)

 EQUD &00000000         \ End address (not used when loading a file)

\ ******************************************************************************
\
\       Name: shipFilename
\       Type: Variable
\   Category: Loader
\    Summary: The filename of the ship blueprint file to load with OSFILE
\
\ ******************************************************************************

.shipFilename

 EQUS "D.MOA"
 EQUB 13

\ ******************************************************************************
\
\       Name: eliteRomHeader
\       Type: Variable
\   Category: Loader
\    Summary: The ROM header code that gets copied to &8000 to create a sideways
\             RAM image containing the ship blueprint files
\
\ ******************************************************************************

.eliteRomHeader

 CLEAR &7C00, &7C00     \ Clear the guard we set above so we can assemble into
                        \ the sideways ROM part of memory

 ORG &8000              \ Set the assembly address for sideways RAM

\ ******************************************************************************
\
\       Name: ROM
\       Type: Variable
\   Category: Loader
\    Summary: The ROM header code that forms the first part of the sideways RAM
\             image containing the ship blueprint files
\
\ ******************************************************************************

.ROM

 JMP srom1              \ Language entry point

 JMP srom1              \ Service entry point

 EQUB %10000001         \ The ROM type:
                        \
                        \   * Bit 7 set = ROM contains a service entry
                        \
                        \   * Bits 0-3 = ROM CPU type (1 = Turbo6502)

 EQUB romCopy - ROM     \ Offset to copyright string

 EQUB 0                 \ Version number

.romTitle

 EQUS "SRAM ELITE"      \ The ROM title

.romCopy

 EQUB 0                 \ NULL and "(C)", required for the MOS to recognise the
 EQUS "(C)Acornsoft"    \ ROM
 EQUB 0

.srom1

 RTS                    \ Return from the subroutine, so the language and
                        \ service entry points do nothing

\ ******************************************************************************
\
\       Name: FileHandler
\       Type: Subroutine
\   Category: Loader
\    Summary: The custom file handler that checks whether OSFILE is loading a
\             ship blueprint file and if so, redirects the load to sideways RAM
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   (Y X)               The address of the OSFILE parameter block
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   A                   A is preserved
\
\   (Y X)               (Y X) is preserved
\
\ ******************************************************************************

.FileHandler

 PHA                    \ Store A on the stack, so we can preserve it through
                        \ the subroutine call

 STX &F0                \ Store (Y X) in (&F1 F0), so we can preserve it through
 STY &F1                \ the subroutine call (&F0 and F1 are reserved by the
                        \ MOS for storing the values of X and Y during OS calls,
                        \ so we can use them accordingly)

 LDY #0                 \ Set (&F3 F2) to the address at (Y X)
 LDA (&F0),Y            \
 STA &F2                \ (Y X) points to the OSFILE parameter block, and the
 INY                    \ first entry in the parameter block is the address of
 LDA (&F0),Y            \ the filename being loaded, so this sets (&F3 F2) to
 STA &F3                \ the address of the filename, terminated by a carriage
                        \ return

                        \ We now check whether the file that's being loaded by
                        \ OSFILE matches the pattern in filenamePattern
                        \
                        \ The patten contains D.MO, then a zero, then a carriage
                        \ return
                        \
                        \ The following code matches the zero with any filename
                        \ character, so this pattern matches the ship blueprint
                        \ files from D.MOA to D.MOP (it also matches files D.MOQ
                        \ to D.MOZ and so on, but this isn't an issue as Elite
                        \ doesn't load those files)

 LDY #5                 \ Set a counter in Y to loop through the six characters
                        \ in the filename pattern to match

.file1

 LDA filenamePattern,Y  \ Set A to the Y-th character to match from the filename
                        \ pattern

 BEQ file2              \ If the character fetched is zero then this matches any
                        \ character, so jump to file2 to move on to the next
                        \ character in the pattern

 CMP (&F2),Y            \ If the Y-th character in the pattern doesn't match the
 BNE file5              \ Y-th character in the OSFILE filename, then we are not
                        \ loading a ship blueprint file, so jump to file5 to
                        \ pass the OSFILE call down the vector chain to FILEV
                        \ via IND1V

.file2

 DEY                    \ Decrement the loop counter to move on to the next
                        \ character to match

 BPL file1              \ Loop back until we have matched all six characters

                        \ If we get here then OSFILE has been called to load a
                        \ ship blueprint file, so we want to intercept it to
                        \ point the game to the ship blueprints in sideways RAM
                        \ instead
                        \
                        \ We do this by copying the ROM_XX21 table from the
                        \ Elite ROM in sideways RAM to XX21 in the main flight
                        \ code (which is where the ship blueprint file would
                        \ normally be loaded)
                        \
                        \ ROM_XX21 contains addresses for all of the ship
                        \ blueprints in sideways RAM, so this ensures that when
                        \ the game fetches any data from a ship blueprint, it
                        \ fetches it from the Elite ROM
                        \
                        \ We don't need to copy an entire page of data from the
                        \ ROM to XX21 (we only need to copy the XX21 and E%
                        \ tables), but copying 256 bytes keeps the loop logic
                        \ simple

 INY                    \ Increment Y to 0, so we can use it as a byte counter

.file3

 LDA ROM_XX21,Y         \ Copy the Y-th byte of ROM_XX21 to XX21
 STA XX21,Y

 INY                    \ Increment the byte counter

 BNE file3              \ Loop back until we have copied all 256 bytes from the
                        \ start of the Elite ROM to XX21 in the main flight code

                        \ We now check whether the ship blueprint file being
                        \ loaded needs to contain a Coriolis space station, as
                        \ the ROM_XX21 table has the address of the Dodo station
                        \ as its second blueprint, which might not be what we
                        \ want

 LDY #4                 \ Set A to the fifth character of the ship blueprint
 LDA (&F2),Y            \ filename in (&F3 &F2), which contains the letter of
                        \ blueprint file (i.e. A for D.MOA, B for D.MOB and so
                        \ on)

 AND #%00000001         \ If the letter has an even ASCII code (which is true of
 BEQ file4              \ files B, D, F, H, J, L, N, P) then the file being
                        \ loaded needs to contain a Dodo station, which is the
                        \ default address of the ROM table, so jump to file4 to
                        \ skip the following as we already have the correct
                        \ XX21 address in XX21

 LDA coriolisStation    \ Set the second address in the XX21 table at XX21(3 2)
 STA XX21+2             \ to the address of the Coriolis space station, to
 LDA coriolisStation+1  \ override the Dodo station address that we just copied
 STA XX21+3             \ from the Elite ROM

.file4

 TSX                    \ Set X to the stack pointer, so &100+X is the address
                        \ of the next free space on the stack

 LDA &F4                \ Set A to the ROM bank number of the Elite ROM

 STA &100+4,X           \ Change the "previous ROM bank" that the MOS puts on
                        \ the stack when calling an extended vector, so the MOS
                        \ switches "back" to the Elite ROM after calling the
                        \ XFILEV handler, which ensures that the Elite ROM
                        \ remains switched into memory at &8000, so the game
                        \ code can load ship blueprint data directly from the
                        \ sideways RAM image

 STA LANGROM            \ Set the current language in MOS workspace to the Elite
                        \ ROM, to prevent any other language ROM from switching
                        \ into memory at &8000

 LDX &F0                \ Retrieve the value of (Y X) from (&F1 F0), so it is
 LDY &F1                \ unchanged by the routine

 PLA                    \ Retrieve the value of A from the stack, so it is
                        \ unchanged by the routine

 RTS                    \ Return from the subroutine, as we have processed the
                        \ request to load the file and do not want to pass it
                        \ on down the chain

.file5

 LDX &F0                \ Retrieve the value of (Y X) from (&F1 F0), so it is
 LDY &F1                \ unchanged by the routine

 PLA                    \ Retrieve the value of A from the stack, so it is
                        \ unchanged by the routine

 JMP (IND1V)            \ Jump to the IND1V vector, which we set above to point
                        \ to the original FILEV file vector, so this passes the
                        \ file operation on down the chain

\ ******************************************************************************
\
\       Name: filenamePattern
\       Type: Variable
\   Category: Loader
\    Summary: The filename pattern for which we intercept OSFILE to return the
\             ship blueprints from sideways RAM
\
\ ******************************************************************************

.filenamePattern

 EQUS "D.MO"
 EQUB 0
 EQUB 13

\ ******************************************************************************
\
\       Name: coriolisStation
\       Type: Variable
\   Category: Loader
\    Summary: The address in sideways RAM of the ship blueprint for the Coriolis
\             space station
\
\ ******************************************************************************

.coriolisStation

 SKIP 2

 COPYBLOCK ROM, P%, eliteRomHeader

 ORG eliteRomHeader + P% - ROM

\ ******************************************************************************
\
\ Save MNUCODE.bin
\
\ ******************************************************************************

 PRINT "T.MNUCODE ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD%
 SAVE "3-assembled-output/MNUCODE.bin", CODE%, P%, LOAD%