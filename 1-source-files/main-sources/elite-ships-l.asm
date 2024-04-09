\ ******************************************************************************
\
\ DISC ELITE SHIP BLUEPRINTS FILE L
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
\   * D.MOL.bin
\
\ ******************************************************************************

 INCLUDE "1-source-files/main-sources/elite-build-options.asm"

 GUARD &6000            \ Guard against assembling over screen memory

\ ******************************************************************************
\
\ Configuration variables
\
\ ******************************************************************************

 CODE% = &5600          \ The flight code runs this file at address &5600, at
                        \ label XX21

 LOAD% = &5600          \ The flight code loads this file at address &5600, at
                        \ label XX21

 SHIP_MISSILE = &7F00   \ The address of the missile ship blueprint

 ORG CODE%

\ ******************************************************************************
\
\       Name: XX21
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprints lookup table for the D.MOL file
\  Deep dive: Ship blueprints in the disc version
\
\ ******************************************************************************

.XX21

 EQUW SHIP_MISSILE      \ MSL  =  1 = Missile
 EQUW SHIP_DODO         \ SST  =  2 = Dodo space station
 EQUW SHIP_ESCAPE_POD   \ ESC  =  3 = Escape pod
 EQUW 0
 EQUW SHIP_CANISTER     \ OIL  =  5 = Cargo canister
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW SHIP_COBRA_MK_3   \ CYL  = 11 = Cobra Mk III
 EQUW 0
 EQUW 0
 EQUW SHIP_ANACONDA     \ ANA  = 14 = Anaconda
 EQUW 0
 EQUW SHIP_VIPER        \ COPS = 16 = Viper
 EQUW SHIP_SIDEWINDER   \ SH3  = 17 = Sidewinder
 EQUW SHIP_MAMBA        \        18 = Mamba
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW SHIP_WORM         \ WRM  = 23 = Worm
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW SHIP_FER_DE_LANCE \        27 = Fer-de-lance
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW 0

\ ******************************************************************************
\
\       Name: E%
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprints default NEWB flags for the D.MOL file
\  Deep dive: Ship blueprints in the disc version
\             Advanced tactics with the NEWB flags
\
\ ******************************************************************************

.E%

 EQUB %00000000         \ Missile
 EQUB %00000000         \ Dodo space station
 EQUB %00000001         \ Escape pod                                      Trader
 EQUB 0
 EQUB %00000000         \ Cargo canister
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB %10100000         \ Cobra Mk III                      Innocent, escape pod
 EQUB 0
 EQUB 0
 EQUB %10100001         \ Anaconda                  Trader, innocent, escape pod
 EQUB 0
 EQUB %11000010         \ Viper                   Bounty hunter, cop, escape pod
 EQUB %00001100         \ Sidewinder                             Hostile, pirate
 EQUB %10001100         \ Mamba                      Hostile, pirate, escape pod
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB %00000100         \ Worm                                           Hostile
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB %10000010         \ Fer-de-lance                 Bounty hunter, escape pod
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB 0

\ ******************************************************************************
\
\       Name: VERTEX
\       Type: Macro
\   Category: Drawing ships
\    Summary: Macro definition for adding vertices to ship blueprints
\  Deep dive: Ship blueprints
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used to build the ship blueprints:
\
\   VERTEX x, y, z, face1, face2, face3, face4, visibility
\
\ See the deep dive on "Ship blueprints" for details of how vertices are stored
\ in the ship blueprints, and the deep dive on "Drawing ships" for information
\ on how vertices are used to draw 3D wireframe ships.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   x                   The vertex's x-coordinate
\
\   y                   The vertex's y-coordinate
\
\   z                   The vertex's z-coordinate
\
\   face1               The number of face 1 associated with this vertex
\
\   face2               The number of face 2 associated with this vertex
\
\   face3               The number of face 3 associated with this vertex
\
\   face4               The number of face 4 associated with this vertex
\
\   visibility          The visibility distance, beyond which the vertex is not
\                       shown
\
\ ******************************************************************************

MACRO VERTEX x, y, z, face1, face2, face3, face4, visibility

 IF x < 0
  s_x = 1 << 7
 ELSE
  s_x = 0
 ENDIF

 IF y < 0
  s_y = 1 << 6
 ELSE
  s_y = 0
 ENDIF

 IF z < 0
  s_z = 1 << 5
 ELSE
  s_z = 0
 ENDIF

 s = s_x + s_y + s_z + visibility
 f1 = face1 + (face2 << 4)
 f2 = face3 + (face4 << 4)
 ax = ABS(x)
 ay = ABS(y)
 az = ABS(z)

 EQUB ax, ay, az, s, f1, f2

ENDMACRO

\ ******************************************************************************
\
\       Name: EDGE
\       Type: Macro
\   Category: Drawing ships
\    Summary: Macro definition for adding edges to ship blueprints
\  Deep dive: Ship blueprints
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used to build the ship blueprints:
\
\   EDGE vertex1, vertex2, face1, face2, visibility
\
\ See the deep dive on "Ship blueprints" for details of how edges are stored
\ in the ship blueprints, and the deep dive on "Drawing ships" for information
\ on how edges are used to draw 3D wireframe ships.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   vertex1             The number of the vertex at the start of the edge
\
\   vertex1             The number of the vertex at the end of the edge
\
\   face1               The number of face 1 associated with this edge
\
\   face2               The number of face 2 associated with this edge
\
\   visibility          The visibility distance, beyond which the edge is not
\                       shown
\
\ ******************************************************************************

MACRO EDGE vertex1, vertex2, face1, face2, visibility

 f = face1 + (face2 << 4)
 EQUB visibility, f, vertex1 << 2, vertex2 << 2

ENDMACRO

\ ******************************************************************************
\
\       Name: FACE
\       Type: Macro
\   Category: Drawing ships
\    Summary: Macro definition for adding faces to ship blueprints
\  Deep dive: Ship blueprints
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used to build the ship blueprints:
\
\   FACE normal_x, normal_y, normal_z, visibility
\
\ See the deep dive on "Ship blueprints" for details of how faces are stored
\ in the ship blueprints, and the deep dive on "Drawing ships" for information
\ on how faces are used to draw 3D wireframe ships.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   normal_x            The face normal's x-coordinate
\
\   normal_y            The face normal's y-coordinate
\
\   normal_z            The face normal's z-coordinate
\
\   visibility          The visibility distance, beyond which the edge is always
\                       shown
\
\ ******************************************************************************

MACRO FACE normal_x, normal_y, normal_z, visibility

 IF normal_x < 0
  s_x = 1 << 7
 ELSE
  s_x = 0
 ENDIF

 IF normal_y < 0
  s_y = 1 << 6
 ELSE
  s_y = 0
 ENDIF

 IF normal_z < 0
  s_z = 1 << 5
 ELSE
  s_z = 0
 ENDIF

 s = s_x + s_y + s_z + visibility
 ax = ABS(normal_x)
 ay = ABS(normal_y)
 az = ABS(normal_z)

 EQUB s, ax, ay, az

ENDMACRO

\ ******************************************************************************
\
\       Name: SHIP_DODO
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Dodecahedron ("Dodo") space station
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_DODO

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 180 * 180         \ Targetable area          = 180 * 180

 EQUB LO(SHIP_DODO_EDGES - SHIP_DODO)              \ Edges data offset (low)
 EQUB LO(SHIP_DODO_FACES - SHIP_DODO)              \ Faces data offset (low)

 EQUB 97                \ Max. edge count          = (97 - 1) / 4 = 24
 EQUB 0                 \ Gun vertex               = 0
 EQUB 54                \ Explosion count          = 12, as (4 * n) + 6 = 54
 EQUB 144               \ Number of vertices       = 144 / 6 = 24
 EQUB 34                \ Number of edges          = 34
 EQUW 0                 \ Bounty                   = 0
 EQUB 48                \ Number of faces          = 48 / 4 = 12
 EQUB 125               \ Visibility distance      = 125
 EQUB 240               \ Max. energy              = 240
 EQUB 0                 \ Max. speed               = 0

 EQUB HI(SHIP_DODO_EDGES - SHIP_DODO)              \ Edges data offset (high)
 EQUB HI(SHIP_DODO_FACES - SHIP_DODO)              \ Faces data offset (high)

 EQUB 0                 \ Normals are scaled by    = 2^0 = 1
 EQUB %00000000         \ Laser power              = 0
                        \ Missiles                 = 0

.SHIP_DODO_VERTICES

      \    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX    0,  150,  196,     1,      0,    5,     5,         31    \ Vertex 0
 VERTEX  143,   46,  196,     1,      0,    2,     2,         31    \ Vertex 1
 VERTEX   88, -121,  196,     2,      0,    3,     3,         31    \ Vertex 2
 VERTEX  -88, -121,  196,     3,      0,    4,     4,         31    \ Vertex 3
 VERTEX -143,   46,  196,     4,      0,    5,     5,         31    \ Vertex 4
 VERTEX    0,  243,   46,     5,      1,    6,     6,         31    \ Vertex 5
 VERTEX  231,   75,   46,     2,      1,    7,     7,         31    \ Vertex 6
 VERTEX  143, -196,   46,     3,      2,    8,     8,         31    \ Vertex 7
 VERTEX -143, -196,   46,     4,      3,    9,     9,         31    \ Vertex 8
 VERTEX -231,   75,   46,     5,      4,   10,    10,         31    \ Vertex 9
 VERTEX  143,  196,  -46,     6,      1,    7,     7,         31    \ Vertex 10
 VERTEX  231,  -75,  -46,     7,      2,    8,     8,         31    \ Vertex 11
 VERTEX    0, -243,  -46,     8,      3,    9,     9,         31    \ Vertex 12
 VERTEX -231,  -75,  -46,     9,      4,   10,    10,         31    \ Vertex 13
 VERTEX -143,  196,  -46,     6,      5,   10,    10,         31    \ Vertex 14
 VERTEX   88,  121, -196,     7,      6,   11,    11,         31    \ Vertex 15
 VERTEX  143,  -46, -196,     8,      7,   11,    11,         31    \ Vertex 16
 VERTEX    0, -150, -196,     9,      8,   11,    11,         31    \ Vertex 17
 VERTEX -143,  -46, -196,    10,      9,   11,    11,         31    \ Vertex 18
 VERTEX  -88,  121, -196,    10,      6,   11,    11,         31    \ Vertex 19
 VERTEX  -16,   32,  196,     0,      0,    0,     0,         30    \ Vertex 20
 VERTEX  -16,  -32,  196,     0,      0,    0,     0,         30    \ Vertex 21
 VERTEX   16,   32,  196,     0,      0,    0,     0,         23    \ Vertex 22
 VERTEX   16,  -32,  196,     0,      0,    0,     0,         23    \ Vertex 23

.SHIP_DODO_EDGES

    \ vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     1,     0,         31    \ Edge 0
 EDGE       1,       2,     2,     0,         31    \ Edge 1
 EDGE       2,       3,     3,     0,         31    \ Edge 2
 EDGE       3,       4,     4,     0,         31    \ Edge 3
 EDGE       4,       0,     5,     0,         31    \ Edge 4
 EDGE       5,      10,     6,     1,         31    \ Edge 5
 EDGE      10,       6,     7,     1,         31    \ Edge 6
 EDGE       6,      11,     7,     2,         31    \ Edge 7
 EDGE      11,       7,     8,     2,         31    \ Edge 8
 EDGE       7,      12,     8,     3,         31    \ Edge 9
 EDGE      12,       8,     9,     3,         31    \ Edge 10
 EDGE       8,      13,     9,     4,         31    \ Edge 11
 EDGE      13,       9,    10,     4,         31    \ Edge 12
 EDGE       9,      14,    10,     5,         31    \ Edge 13
 EDGE      14,       5,     6,     5,         31    \ Edge 14
 EDGE      15,      16,    11,     7,         31    \ Edge 15
 EDGE      16,      17,    11,     8,         31    \ Edge 16
 EDGE      17,      18,    11,     9,         31    \ Edge 17
 EDGE      18,      19,    11,    10,         31    \ Edge 18
 EDGE      19,      15,    11,     6,         31    \ Edge 19
 EDGE       0,       5,     5,     1,         31    \ Edge 20
 EDGE       1,       6,     2,     1,         31    \ Edge 21
 EDGE       2,       7,     3,     2,         31    \ Edge 22
 EDGE       3,       8,     4,     3,         31    \ Edge 23
 EDGE       4,       9,     5,     4,         31    \ Edge 24
 EDGE      10,      15,     7,     6,         31    \ Edge 25
 EDGE      11,      16,     8,     7,         31    \ Edge 26
 EDGE      12,      17,     9,     8,         31    \ Edge 27
 EDGE      13,      18,    10,     9,         31    \ Edge 28
 EDGE      14,      19,    10,     6,         31    \ Edge 29
 EDGE      20,      21,     0,     0,         30    \ Edge 30
 EDGE      21,      23,     0,     0,         20    \ Edge 31
 EDGE      23,      22,     0,     0,         23    \ Edge 32
 EDGE      22,      20,     0,     0,         20    \ Edge 33

.SHIP_DODO_FACES

    \ normal_x, normal_y, normal_z, visibility
 FACE        0,        0,      196,         31    \ Face 0
 FACE      103,      142,       88,         31    \ Face 1
 FACE      169,      -55,       89,         31    \ Face 2
 FACE        0,     -176,       88,         31    \ Face 3
 FACE     -169,      -55,       89,         31    \ Face 4
 FACE     -103,      142,       88,         31    \ Face 5
 FACE        0,      176,      -88,         31    \ Face 6
 FACE      169,       55,      -89,         31    \ Face 7
 FACE      103,     -142,      -88,         31    \ Face 8
 FACE     -103,     -142,      -88,         31    \ Face 9
 FACE     -169,       55,      -89,         31    \ Face 10
 FACE        0,        0,     -196,         31    \ Face 11

\ ******************************************************************************
\
\       Name: SHIP_ESCAPE_POD
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for an escape pod
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_ESCAPE_POD

 EQUB 0 + (2 << 4)      \ Max. canisters on demise = 0
                        \ Market item when scooped = 2 + 1 = 3 (slaves)
 EQUW 16 * 16           \ Targetable area          = 16 * 16

 EQUB LO(SHIP_ESCAPE_POD_EDGES - SHIP_ESCAPE_POD)  \ Edges data offset (low)
 EQUB LO(SHIP_ESCAPE_POD_FACES - SHIP_ESCAPE_POD)  \ Faces data offset (low)

 EQUB 25                \ Max. edge count          = (25 - 1) / 4 = 6
 EQUB 0                 \ Gun vertex               = 0
 EQUB 22                \ Explosion count          = 4, as (4 * n) + 6 = 22
 EQUB 24                \ Number of vertices       = 24 / 6 = 4
 EQUB 6                 \ Number of edges          = 6
 EQUW 0                 \ Bounty                   = 0
 EQUB 16                \ Number of faces          = 16 / 4 = 4
 EQUB 8                 \ Visibility distance      = 8
 EQUB 17                \ Max. energy              = 17
 EQUB 8                 \ Max. speed               = 8

 EQUB HI(SHIP_ESCAPE_POD_EDGES - SHIP_ESCAPE_POD)  \ Edges data offset (high)
 EQUB HI(SHIP_ESCAPE_POD_FACES - SHIP_ESCAPE_POD)  \ Faces data offset (high)

 EQUB 4                 \ Normals are scaled by    =  2^4 = 16
 EQUB %00000000         \ Laser power              = 0
                        \ Missiles                 = 0

.SHIP_ESCAPE_POD_VERTICES

      \    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX   -7,    0,   36,     2,      1,    3,     3,         31    \ Vertex 0
 VERTEX   -7,  -14,  -12,     2,      0,    3,     3,         31    \ Vertex 1
 VERTEX   -7,   14,  -12,     1,      0,    3,     3,         31    \ Vertex 2
 VERTEX   21,    0,    0,     1,      0,    2,     2,         31    \ Vertex 3

.SHIP_ESCAPE_POD_EDGES

    \ vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     3,     2,         31    \ Edge 0
 EDGE       1,       2,     3,     0,         31    \ Edge 1
 EDGE       2,       3,     1,     0,         31    \ Edge 2
 EDGE       3,       0,     2,     1,         31    \ Edge 3
 EDGE       0,       2,     3,     1,         31    \ Edge 4
 EDGE       3,       1,     2,     0,         31    \ Edge 5

.SHIP_ESCAPE_POD_FACES

    \ normal_x, normal_y, normal_z, visibility
 FACE       52,        0,     -122,         31    \ Face 0
 FACE       39,      103,       30,         31    \ Face 1
 FACE       39,     -103,       30,         31    \ Face 2
 FACE     -112,        0,        0,         31    \ Face 3

\ ******************************************************************************
\
\       Name: SHIP_CANISTER
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a cargo canister
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_CANISTER

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 20 * 20           \ Targetable area          = 20 * 20

 EQUB LO(SHIP_CANISTER_EDGES - SHIP_CANISTER)      \ Edges data offset (low)
 EQUB LO(SHIP_CANISTER_FACES - SHIP_CANISTER)      \ Faces data offset (low)

 EQUB 49                \ Max. edge count          = (49 - 1) / 4 = 12
 EQUB 0                 \ Gun vertex               = 0
 EQUB 18                \ Explosion count          = 3, as (4 * n) + 6 = 18
 EQUB 60                \ Number of vertices       = 60 / 6 = 10
 EQUB 15                \ Number of edges          = 15
 EQUW 0                 \ Bounty                   = 0
 EQUB 28                \ Number of faces          = 28 / 4 = 7
 EQUB 12                \ Visibility distance      = 12
 EQUB 17                \ Max. energy              = 17
 EQUB 15                \ Max. speed               = 15

 EQUB HI(SHIP_CANISTER_EDGES - SHIP_CANISTER)      \ Edges data offset (high)
 EQUB HI(SHIP_CANISTER_FACES - SHIP_CANISTER)      \ Faces data offset (high)

 EQUB 2                 \ Normals are scaled by    = 2^2 = 4
 EQUB %00000000         \ Laser power              = 0
                        \ Missiles                 = 0

.SHIP_CANISTER_VERTICES

      \    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX   24,   16,    0,     0,      1,    5,     5,         31    \ Vertex 0
 VERTEX   24,    5,   15,     0,      1,    2,     2,         31    \ Vertex 1
 VERTEX   24,  -13,    9,     0,      2,    3,     3,         31    \ Vertex 2
 VERTEX   24,  -13,   -9,     0,      3,    4,     4,         31    \ Vertex 3
 VERTEX   24,    5,  -15,     0,      4,    5,     5,         31    \ Vertex 4
 VERTEX  -24,   16,    0,     1,      5,    6,     6,         31    \ Vertex 5
 VERTEX  -24,    5,   15,     1,      2,    6,     6,         31    \ Vertex 6
 VERTEX  -24,  -13,    9,     2,      3,    6,     6,         31    \ Vertex 7
 VERTEX  -24,  -13,   -9,     3,      4,    6,     6,         31    \ Vertex 8
 VERTEX  -24,    5,  -15,     4,      5,    6,     6,         31    \ Vertex 9

.SHIP_CANISTER_EDGES

    \ vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     0,     1,         31    \ Edge 0
 EDGE       1,       2,     0,     2,         31    \ Edge 1
 EDGE       2,       3,     0,     3,         31    \ Edge 2
 EDGE       3,       4,     0,     4,         31    \ Edge 3
 EDGE       0,       4,     0,     5,         31    \ Edge 4
 EDGE       0,       5,     1,     5,         31    \ Edge 5
 EDGE       1,       6,     1,     2,         31    \ Edge 6
 EDGE       2,       7,     2,     3,         31    \ Edge 7
 EDGE       3,       8,     3,     4,         31    \ Edge 8
 EDGE       4,       9,     4,     5,         31    \ Edge 9
 EDGE       5,       6,     1,     6,         31    \ Edge 10
 EDGE       6,       7,     2,     6,         31    \ Edge 11
 EDGE       7,       8,     3,     6,         31    \ Edge 12
 EDGE       8,       9,     4,     6,         31    \ Edge 13
 EDGE       9,       5,     5,     6,         31    \ Edge 14

.SHIP_CANISTER_FACES

    \ normal_x, normal_y, normal_z, visibility
 FACE       96,        0,        0,         31    \ Face 0
 FACE        0,       41,       30,         31    \ Face 1
 FACE        0,      -18,       48,         31    \ Face 2
 FACE        0,      -51,        0,         31    \ Face 3
 FACE        0,      -18,      -48,         31    \ Face 4
 FACE        0,       41,      -30,         31    \ Face 5
 FACE      -96,        0,        0,         31    \ Face 6

\ ******************************************************************************
\
\       Name: SHIP_COBRA_MK_3
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Cobra Mk III
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_COBRA_MK_3

 EQUB 3                 \ Max. canisters on demise = 3
 EQUW 95 * 95           \ Targetable area          = 95 * 95

 EQUB LO(SHIP_COBRA_MK_3_EDGES - SHIP_COBRA_MK_3)  \ Edges data offset (low)
 EQUB LO(SHIP_COBRA_MK_3_FACES - SHIP_COBRA_MK_3)  \ Faces data offset (low)

 EQUB 153               \ Max. edge count          = (153 - 1) / 4 = 38
 EQUB 84                \ Gun vertex               = 84 / 4 = 21
 EQUB 42                \ Explosion count          = 9, as (4 * n) + 6 = 42
 EQUB 168               \ Number of vertices       = 168 / 6 = 28
 EQUB 38                \ Number of edges          = 38
 EQUW 0                 \ Bounty                   = 0
 EQUB 52                \ Number of faces          = 52 / 4 = 13
 EQUB 50                \ Visibility distance      = 50
 EQUB 150               \ Max. energy              = 150
 EQUB 28                \ Max. speed               = 28

 EQUB HI(SHIP_COBRA_MK_3_EDGES - SHIP_COBRA_MK_3)  \ Edges data offset (low)
 EQUB HI(SHIP_COBRA_MK_3_FACES - SHIP_COBRA_MK_3)  \ Faces data offset (low)

 EQUB 1                 \ Normals are scaled by    = 2^1 = 2
 EQUB %00010011         \ Laser power              = 2
                        \ Missiles                 = 3

.SHIP_COBRA_MK_3_VERTICES

      \    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX   32,    0,   76,    15,     15,   15,    15,         31    \ Vertex 0
 VERTEX  -32,    0,   76,    15,     15,   15,    15,         31    \ Vertex 1
 VERTEX    0,   26,   24,    15,     15,   15,    15,         31    \ Vertex 2
 VERTEX -120,   -3,   -8,     3,      7,   10,    10,         31    \ Vertex 3
 VERTEX  120,   -3,   -8,     4,      8,   12,    12,         31    \ Vertex 4
 VERTEX  -88,   16,  -40,    15,     15,   15,    15,         31    \ Vertex 5
 VERTEX   88,   16,  -40,    15,     15,   15,    15,         31    \ Vertex 6
 VERTEX  128,   -8,  -40,     8,      9,   12,    12,         31    \ Vertex 7
 VERTEX -128,   -8,  -40,     7,      9,   10,    10,         31    \ Vertex 8
 VERTEX    0,   26,  -40,     5,      6,    9,     9,         31    \ Vertex 9
 VERTEX  -32,  -24,  -40,     9,     10,   11,    11,         31    \ Vertex 10
 VERTEX   32,  -24,  -40,     9,     11,   12,    12,         31    \ Vertex 11
 VERTEX  -36,    8,  -40,     9,      9,    9,     9,         20    \ Vertex 12
 VERTEX   -8,   12,  -40,     9,      9,    9,     9,         20    \ Vertex 13
 VERTEX    8,   12,  -40,     9,      9,    9,     9,         20    \ Vertex 14
 VERTEX   36,    8,  -40,     9,      9,    9,     9,         20    \ Vertex 15
 VERTEX   36,  -12,  -40,     9,      9,    9,     9,         20    \ Vertex 16
 VERTEX    8,  -16,  -40,     9,      9,    9,     9,         20    \ Vertex 17
 VERTEX   -8,  -16,  -40,     9,      9,    9,     9,         20    \ Vertex 18
 VERTEX  -36,  -12,  -40,     9,      9,    9,     9,         20    \ Vertex 19
 VERTEX    0,    0,   76,     0,     11,   11,    11,          6    \ Vertex 20
 VERTEX    0,    0,   90,     0,     11,   11,    11,         31    \ Vertex 21
 VERTEX  -80,   -6,  -40,     9,      9,    9,     9,          8    \ Vertex 22
 VERTEX  -80,    6,  -40,     9,      9,    9,     9,          8    \ Vertex 23
 VERTEX  -88,    0,  -40,     9,      9,    9,     9,          6    \ Vertex 24
 VERTEX   80,    6,  -40,     9,      9,    9,     9,          8    \ Vertex 25
 VERTEX   88,    0,  -40,     9,      9,    9,     9,          6    \ Vertex 26
 VERTEX   80,   -6,  -40,     9,      9,    9,     9,          8    \ Vertex 27

.SHIP_COBRA_MK_3_EDGES

    \ vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     0,    11,         31    \ Edge 0
 EDGE       0,       4,     4,    12,         31    \ Edge 1
 EDGE       1,       3,     3,    10,         31    \ Edge 2
 EDGE       3,       8,     7,    10,         31    \ Edge 3
 EDGE       4,       7,     8,    12,         31    \ Edge 4
 EDGE       6,       7,     8,     9,         31    \ Edge 5
 EDGE       6,       9,     6,     9,         31    \ Edge 6
 EDGE       5,       9,     5,     9,         31    \ Edge 7
 EDGE       5,       8,     7,     9,         31    \ Edge 8
 EDGE       2,       5,     1,     5,         31    \ Edge 9
 EDGE       2,       6,     2,     6,         31    \ Edge 10
 EDGE       3,       5,     3,     7,         31    \ Edge 11
 EDGE       4,       6,     4,     8,         31    \ Edge 12
 EDGE       1,       2,     0,     1,         31    \ Edge 13
 EDGE       0,       2,     0,     2,         31    \ Edge 14
 EDGE       8,      10,     9,    10,         31    \ Edge 15
 EDGE      10,      11,     9,    11,         31    \ Edge 16
 EDGE       7,      11,     9,    12,         31    \ Edge 17
 EDGE       1,      10,    10,    11,         31    \ Edge 18
 EDGE       0,      11,    11,    12,         31    \ Edge 19
 EDGE       1,       5,     1,     3,         29    \ Edge 20
 EDGE       0,       6,     2,     4,         29    \ Edge 21
 EDGE      20,      21,     0,    11,          6    \ Edge 22
 EDGE      12,      13,     9,     9,         20    \ Edge 23
 EDGE      18,      19,     9,     9,         20    \ Edge 24
 EDGE      14,      15,     9,     9,         20    \ Edge 25
 EDGE      16,      17,     9,     9,         20    \ Edge 26
 EDGE      15,      16,     9,     9,         19    \ Edge 27
 EDGE      14,      17,     9,     9,         17    \ Edge 28
 EDGE      13,      18,     9,     9,         19    \ Edge 29
 EDGE      12,      19,     9,     9,         19    \ Edge 30
 EDGE       2,       9,     5,     6,         30    \ Edge 31
 EDGE      22,      24,     9,     9,          6    \ Edge 32
 EDGE      23,      24,     9,     9,          6    \ Edge 33
 EDGE      22,      23,     9,     9,          8    \ Edge 34
 EDGE      25,      26,     9,     9,          6    \ Edge 35
 EDGE      26,      27,     9,     9,          6    \ Edge 36
 EDGE      25,      27,     9,     9,          8    \ Edge 37

.SHIP_COBRA_MK_3_FACES

    \ normal_x, normal_y, normal_z, visibility
 FACE        0,       62,       31,         31    \ Face 0
 FACE      -18,       55,       16,         31    \ Face 1
 FACE       18,       55,       16,         31    \ Face 2
 FACE      -16,       52,       14,         31    \ Face 3
 FACE       16,       52,       14,         31    \ Face 4
 FACE      -14,       47,        0,         31    \ Face 5
 FACE       14,       47,        0,         31    \ Face 6
 FACE      -61,      102,        0,         31    \ Face 7
 FACE       61,      102,        0,         31    \ Face 8
 FACE        0,        0,      -80,         31    \ Face 9
 FACE       -7,      -42,        9,         31    \ Face 10
 FACE        0,      -30,        6,         31    \ Face 11
 FACE        7,      -42,        9,         31    \ Face 12

\ ******************************************************************************
\
\       Name: SHIP_ANACONDA
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for an Anaconda
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_ANACONDA

 EQUB 7                 \ Max. canisters on demise = 7
 EQUW 100 * 100         \ Targetable area          = 100 * 100

 EQUB LO(SHIP_ANACONDA_EDGES - SHIP_ANACONDA)      \ Edges data offset (low)
 EQUB LO(SHIP_ANACONDA_FACES - SHIP_ANACONDA)      \ Faces data offset (low)

 EQUB 89                \ Max. edge count          = (89 - 1) / 4 = 22
 EQUB 48                \ Gun vertex               = 48 / 4 = 12
 EQUB 46                \ Explosion count          = 10, as (4 * n) + 6 = 46
 EQUB 90                \ Number of vertices       = 90 / 6 = 15
 EQUB 25                \ Number of edges          = 25
 EQUW 0                 \ Bounty                   = 0
 EQUB 48                \ Number of faces          = 48 / 4 = 12
 EQUB 50                \ Visibility distance      = 50
 EQUB 252               \ Max. energy              = 252
 EQUB 14                \ Max. speed               = 14

 EQUB HI(SHIP_ANACONDA_EDGES - SHIP_ANACONDA)      \ Edges data offset (high)
 EQUB HI(SHIP_ANACONDA_FACES - SHIP_ANACONDA)      \ Faces data offset (high)

 EQUB 1                 \ Normals are scaled by    = 2^1 = 2
 EQUB %00111111         \ Laser power              = 7
                        \ Missiles                 = 7

.SHIP_ANACONDA_VERTICES

      \    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX    0,    7,  -58,     1,      0,    5,     5,         30    \ Vertex 0
 VERTEX  -43,  -13,  -37,     1,      0,    2,     2,         30    \ Vertex 1
 VERTEX  -26,  -47,   -3,     2,      0,    3,     3,         30    \ Vertex 2
 VERTEX   26,  -47,   -3,     3,      0,    4,     4,         30    \ Vertex 3
 VERTEX   43,  -13,  -37,     4,      0,    5,     5,         30    \ Vertex 4
 VERTEX    0,   48,  -49,     5,      1,    6,     6,         30    \ Vertex 5
 VERTEX  -69,   15,  -15,     2,      1,    7,     7,         30    \ Vertex 6
 VERTEX  -43,  -39,   40,     3,      2,    8,     8,         31    \ Vertex 7
 VERTEX   43,  -39,   40,     4,      3,    9,     9,         31    \ Vertex 8
 VERTEX   69,   15,  -15,     5,      4,   10,    10,         30    \ Vertex 9
 VERTEX  -43,   53,  -23,    15,     15,   15,    15,         31    \ Vertex 10
 VERTEX  -69,   -1,   32,     7,      2,    8,     8,         31    \ Vertex 11
 VERTEX    0,    0,  254,    15,     15,   15,    15,         31    \ Vertex 12
 VERTEX   69,   -1,   32,     9,      4,   10,    10,         31    \ Vertex 13
 VERTEX   43,   53,  -23,    15,     15,   15,    15,         31    \ Vertex 14

.SHIP_ANACONDA_EDGES

    \ vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     1,     0,         30    \ Edge 0
 EDGE       1,       2,     2,     0,         30    \ Edge 1
 EDGE       2,       3,     3,     0,         30    \ Edge 2
 EDGE       3,       4,     4,     0,         30    \ Edge 3
 EDGE       0,       4,     5,     0,         30    \ Edge 4
 EDGE       0,       5,     5,     1,         29    \ Edge 5
 EDGE       1,       6,     2,     1,         29    \ Edge 6
 EDGE       2,       7,     3,     2,         29    \ Edge 7
 EDGE       3,       8,     4,     3,         29    \ Edge 8
 EDGE       4,       9,     5,     4,         29    \ Edge 9
 EDGE       5,      10,     6,     1,         30    \ Edge 10
 EDGE       6,      10,     7,     1,         30    \ Edge 11
 EDGE       6,      11,     7,     2,         30    \ Edge 12
 EDGE       7,      11,     8,     2,         30    \ Edge 13
 EDGE       7,      12,     8,     3,         31    \ Edge 14
 EDGE       8,      12,     9,     3,         31    \ Edge 15
 EDGE       8,      13,     9,     4,         30    \ Edge 16
 EDGE       9,      13,    10,     4,         30    \ Edge 17
 EDGE       9,      14,    10,     5,         30    \ Edge 18
 EDGE       5,      14,     6,     5,         30    \ Edge 19
 EDGE      10,      14,    11,     6,         30    \ Edge 20
 EDGE      10,      12,    11,     7,         31    \ Edge 21
 EDGE      11,      12,     8,     7,         31    \ Edge 22
 EDGE      12,      13,    10,     9,         31    \ Edge 23
 EDGE      12,      14,    11,    10,         31    \ Edge 24

.SHIP_ANACONDA_FACES

    \ normal_x, normal_y, normal_z, visibility
 FACE        0,      -51,      -49,         30    \ Face 0
 FACE      -51,       18,      -87,         30    \ Face 1
 FACE      -77,      -57,      -19,         30    \ Face 2
 FACE        0,      -90,       16,         31    \ Face 3
 FACE       77,      -57,      -19,         30    \ Face 4
 FACE       51,       18,      -87,         30    \ Face 5
 FACE        0,      111,      -20,         30    \ Face 6
 FACE      -97,       72,       24,         31    \ Face 7
 FACE     -108,      -68,       34,         31    \ Face 8
 FACE      108,      -68,       34,         31    \ Face 9
 FACE       97,       72,       24,         31    \ Face 10
 FACE        0,       94,       18,         31    \ Face 11

\ ******************************************************************************
\
\       Name: SHIP_VIPER
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Viper
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_VIPER

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 75 * 75           \ Targetable area          = 75 * 75

 EQUB LO(SHIP_VIPER_EDGES - SHIP_VIPER)            \ Edges data offset (low)
 EQUB LO(SHIP_VIPER_FACES - SHIP_VIPER)            \ Faces data offset (low)

 EQUB 77                \ Max. edge count          = (77 - 1) / 4 = 19
 EQUB 0                 \ Gun vertex               = 0
 EQUB 42                \ Explosion count          = 9, as (4 * n) + 6 = 42
 EQUB 90                \ Number of vertices       = 90 / 6 = 15
 EQUB 20                \ Number of edges          = 20
 EQUW 0                 \ Bounty                   = 0
 EQUB 28                \ Number of faces          = 28 / 4 = 7
 EQUB 23                \ Visibility distance      = 23
 EQUB 100               \ Max. energy              = 100
 EQUB 32                \ Max. speed               = 32

 EQUB HI(SHIP_VIPER_EDGES - SHIP_VIPER)            \ Edges data offset (high)
 EQUB HI(SHIP_VIPER_FACES - SHIP_VIPER)            \ Faces data offset (high)

 EQUB 1                 \ Normals are scaled by    = 2^1 = 2
 EQUB %00010001         \ Laser power              = 2
                        \ Missiles                 = 1

.SHIP_VIPER_VERTICES

      \    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX    0,    0,   72,     1,      2,    3,     4,         31    \ Vertex 0
 VERTEX    0,   16,   24,     0,      1,    2,     2,         30    \ Vertex 1
 VERTEX    0,  -16,   24,     3,      4,    5,     5,         30    \ Vertex 2
 VERTEX   48,    0,  -24,     2,      4,    6,     6,         31    \ Vertex 3
 VERTEX  -48,    0,  -24,     1,      3,    6,     6,         31    \ Vertex 4
 VERTEX   24,  -16,  -24,     4,      5,    6,     6,         30    \ Vertex 5
 VERTEX  -24,  -16,  -24,     5,      3,    6,     6,         30    \ Vertex 6
 VERTEX   24,   16,  -24,     0,      2,    6,     6,         31    \ Vertex 7
 VERTEX  -24,   16,  -24,     0,      1,    6,     6,         31    \ Vertex 8
 VERTEX  -32,    0,  -24,     6,      6,    6,     6,         19    \ Vertex 9
 VERTEX   32,    0,  -24,     6,      6,    6,     6,         19    \ Vertex 10
 VERTEX    8,    8,  -24,     6,      6,    6,     6,         19    \ Vertex 11
 VERTEX   -8,    8,  -24,     6,      6,    6,     6,         19    \ Vertex 12
 VERTEX   -8,   -8,  -24,     6,      6,    6,     6,         18    \ Vertex 13
 VERTEX    8,   -8,  -24,     6,      6,    6,     6,         18    \ Vertex 14

.SHIP_VIPER_EDGES

    \ vertex1, vertex2, face1, face2, visibility
 EDGE       0,       3,     2,     4,         31    \ Edge 0
 EDGE       0,       1,     1,     2,         30    \ Edge 1
 EDGE       0,       2,     3,     4,         30    \ Edge 2
 EDGE       0,       4,     1,     3,         31    \ Edge 3
 EDGE       1,       7,     0,     2,         30    \ Edge 4
 EDGE       1,       8,     0,     1,         30    \ Edge 5
 EDGE       2,       5,     4,     5,         30    \ Edge 6
 EDGE       2,       6,     3,     5,         30    \ Edge 7
 EDGE       7,       8,     0,     6,         31    \ Edge 8
 EDGE       5,       6,     5,     6,         30    \ Edge 9
 EDGE       4,       8,     1,     6,         31    \ Edge 10
 EDGE       4,       6,     3,     6,         30    \ Edge 11
 EDGE       3,       7,     2,     6,         31    \ Edge 12
 EDGE       3,       5,     6,     4,         30    \ Edge 13
 EDGE       9,      12,     6,     6,         19    \ Edge 14
 EDGE       9,      13,     6,     6,         18    \ Edge 15
 EDGE      10,      11,     6,     6,         19    \ Edge 16
 EDGE      10,      14,     6,     6,         18    \ Edge 17
 EDGE      11,      14,     6,     6,         16    \ Edge 18
 EDGE      12,      13,     6,     6,         16    \ Edge 19

.SHIP_VIPER_FACES

    \ normal_x, normal_y, normal_z, visibility
 FACE        0,       32,        0,         31    \ Face 0
 FACE      -22,       33,       11,         31    \ Face 1
 FACE       22,       33,       11,         31    \ Face 2
 FACE      -22,      -33,       11,         31    \ Face 3
 FACE       22,      -33,       11,         31    \ Face 4
 FACE        0,      -32,        0,         31    \ Face 5
 FACE        0,        0,      -48,         31    \ Face 6

\ ******************************************************************************
\
\       Name: SHIP_SIDEWINDER
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Sidewinder
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_SIDEWINDER

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 65 * 65           \ Targetable area          = 65 * 65

 EQUB LO(SHIP_SIDEWINDER_EDGES - SHIP_SIDEWINDER)  \ Edges data offset (low)
 EQUB LO(SHIP_SIDEWINDER_FACES - SHIP_SIDEWINDER)  \ Faces data offset (low)

 EQUB 61                \ Max. edge count          = (61 - 1) / 4 = 15
 EQUB 0                 \ Gun vertex               = 0
 EQUB 30                \ Explosion count          = 6, as (4 * n) + 6 = 30
 EQUB 60                \ Number of vertices       = 60 / 6 = 10
 EQUB 15                \ Number of edges          = 15
 EQUW 50                \ Bounty                   = 50
 EQUB 28                \ Number of faces          = 28 / 4 = 7
 EQUB 20                \ Visibility distance      = 20
 EQUB 70                \ Max. energy              = 70
 EQUB 37                \ Max. speed               = 37

 EQUB HI(SHIP_SIDEWINDER_EDGES - SHIP_SIDEWINDER)  \ Edges data offset (high)
 EQUB HI(SHIP_SIDEWINDER_FACES - SHIP_SIDEWINDER)  \ Faces data offset (high)

 EQUB 2                 \ Normals are scaled by    = 2^2 = 4
 EQUB %00010000         \ Laser power              = 2
                        \ Missiles                 = 0

.SHIP_SIDEWINDER_VERTICES

      \    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX  -32,    0,   36,     0,      1,    4,     5,         31    \ Vertex 0
 VERTEX   32,    0,   36,     0,      2,    5,     6,         31    \ Vertex 1
 VERTEX   64,    0,  -28,     2,      3,    6,     6,         31    \ Vertex 2
 VERTEX  -64,    0,  -28,     1,      3,    4,     4,         31    \ Vertex 3
 VERTEX    0,   16,  -28,     0,      1,    2,     3,         31    \ Vertex 4
 VERTEX    0,  -16,  -28,     3,      4,    5,     6,         31    \ Vertex 5
 VERTEX  -12,    6,  -28,     3,      3,    3,     3,         15    \ Vertex 6
 VERTEX   12,    6,  -28,     3,      3,    3,     3,         15    \ Vertex 7
 VERTEX   12,   -6,  -28,     3,      3,    3,     3,         12    \ Vertex 8
 VERTEX  -12,   -6,  -28,     3,      3,    3,     3,         12    \ Vertex 9

.SHIP_SIDEWINDER_EDGES

    \ vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     0,     5,         31    \ Edge 0
 EDGE       1,       2,     2,     6,         31    \ Edge 1
 EDGE       1,       4,     0,     2,         31    \ Edge 2
 EDGE       0,       4,     0,     1,         31    \ Edge 3
 EDGE       0,       3,     1,     4,         31    \ Edge 4
 EDGE       3,       4,     1,     3,         31    \ Edge 5
 EDGE       2,       4,     2,     3,         31    \ Edge 6
 EDGE       3,       5,     3,     4,         31    \ Edge 7
 EDGE       2,       5,     3,     6,         31    \ Edge 8
 EDGE       1,       5,     5,     6,         31    \ Edge 9
 EDGE       0,       5,     4,     5,         31    \ Edge 10
 EDGE       6,       7,     3,     3,         15    \ Edge 11
 EDGE       7,       8,     3,     3,         12    \ Edge 12
 EDGE       6,       9,     3,     3,         12    \ Edge 13
 EDGE       8,       9,     3,     3,         12    \ Edge 14

.SHIP_SIDEWINDER_FACES

    \ normal_x, normal_y, normal_z, visibility
 FACE        0,       32,        8,         31    \ Face 0
 FACE      -12,       47,        6,         31    \ Face 1
 FACE       12,       47,        6,         31    \ Face 2
 FACE        0,        0,     -112,         31    \ Face 3
 FACE      -12,      -47,        6,         31    \ Face 4
 FACE        0,      -32,        8,         31    \ Face 5
 FACE       12,      -47,        6,         31    \ Face 6

\ ******************************************************************************
\
\       Name: SHIP_MAMBA
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Mamba
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_MAMBA

 EQUB 1                 \ Max. canisters on demise = 1
 EQUW 70 * 70           \ Targetable area          = 70 * 70

 EQUB LO(SHIP_MAMBA_EDGES - SHIP_MAMBA)            \ Edges data offset (low)
 EQUB LO(SHIP_MAMBA_FACES - SHIP_MAMBA)            \ Faces data offset (low)

 EQUB 93                \ Max. edge count          = (93 - 1) / 4 = 23
 EQUB 0                 \ Gun vertex               = 0
 EQUB 34                \ Explosion count          = 7, as (4 * n) + 6 = 34
 EQUB 150               \ Number of vertices       = 150 / 6 = 25
 EQUB 28                \ Number of edges          = 28
 EQUW 150               \ Bounty                   = 150
 EQUB 20                \ Number of faces          = 20 / 4 = 5
 EQUB 25                \ Visibility distance      = 25
 EQUB 90                \ Max. energy              = 90
 EQUB 30                \ Max. speed               = 30

 EQUB HI(SHIP_MAMBA_EDGES - SHIP_MAMBA)            \ Edges data offset (high)
 EQUB HI(SHIP_MAMBA_FACES - SHIP_MAMBA)            \ Faces data offset (high)

 EQUB 2                 \ Normals are scaled by    = 2^2 = 4
 EQUB %00010010         \ Laser power              = 2
                        \ Missiles                 = 2

.SHIP_MAMBA_VERTICES

      \    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX    0,    0,   64,     0,      1,    2,     3,         31    \ Vertex 0
 VERTEX  -64,   -8,  -32,     0,      2,    4,     4,         31    \ Vertex 1
 VERTEX  -32,    8,  -32,     1,      2,    4,     4,         30    \ Vertex 2
 VERTEX   32,    8,  -32,     1,      3,    4,     4,         30    \ Vertex 3
 VERTEX   64,   -8,  -32,     0,      3,    4,     4,         31    \ Vertex 4
 VERTEX   -4,    4,   16,     1,      1,    1,     1,         14    \ Vertex 5
 VERTEX    4,    4,   16,     1,      1,    1,     1,         14    \ Vertex 6
 VERTEX    8,    3,   28,     1,      1,    1,     1,         13    \ Vertex 7
 VERTEX   -8,    3,   28,     1,      1,    1,     1,         13    \ Vertex 8
 VERTEX  -20,   -4,   16,     0,      0,    0,     0,         20    \ Vertex 9
 VERTEX   20,   -4,   16,     0,      0,    0,     0,         20    \ Vertex 10
 VERTEX  -24,   -7,  -20,     0,      0,    0,     0,         20    \ Vertex 11
 VERTEX  -16,   -7,  -20,     0,      0,    0,     0,         16    \ Vertex 12
 VERTEX   16,   -7,  -20,     0,      0,    0,     0,         16    \ Vertex 13
 VERTEX   24,   -7,  -20,     0,      0,    0,     0,         20    \ Vertex 14
 VERTEX   -8,    4,  -32,     4,      4,    4,     4,         13    \ Vertex 15
 VERTEX    8,    4,  -32,     4,      4,    4,     4,         13    \ Vertex 16
 VERTEX    8,   -4,  -32,     4,      4,    4,     4,         14    \ Vertex 17
 VERTEX   -8,   -4,  -32,     4,      4,    4,     4,         14    \ Vertex 18
 VERTEX  -32,    4,  -32,     4,      4,    4,     4,          7    \ Vertex 19
 VERTEX   32,    4,  -32,     4,      4,    4,     4,          7    \ Vertex 20
 VERTEX   36,   -4,  -32,     4,      4,    4,     4,          7    \ Vertex 21
 VERTEX  -36,   -4,  -32,     4,      4,    4,     4,          7    \ Vertex 22
 VERTEX  -38,    0,  -32,     4,      4,    4,     4,          5    \ Vertex 23
 VERTEX   38,    0,  -32,     4,      4,    4,     4,          5    \ Vertex 24

.SHIP_MAMBA_EDGES

    \ vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     0,     2,         31    \ Edge 0
 EDGE       0,       4,     0,     3,         31    \ Edge 1
 EDGE       1,       4,     0,     4,         31    \ Edge 2
 EDGE       1,       2,     2,     4,         30    \ Edge 3
 EDGE       2,       3,     1,     4,         30    \ Edge 4
 EDGE       3,       4,     3,     4,         30    \ Edge 5
 EDGE       5,       6,     1,     1,         14    \ Edge 6
 EDGE       6,       7,     1,     1,         12    \ Edge 7
 EDGE       7,       8,     1,     1,         13    \ Edge 8
 EDGE       5,       8,     1,     1,         12    \ Edge 9
 EDGE       9,      11,     0,     0,         20    \ Edge 10
 EDGE       9,      12,     0,     0,         16    \ Edge 11
 EDGE      10,      13,     0,     0,         16    \ Edge 12
 EDGE      10,      14,     0,     0,         20    \ Edge 13
 EDGE      13,      14,     0,     0,         14    \ Edge 14
 EDGE      11,      12,     0,     0,         14    \ Edge 15
 EDGE      15,      16,     4,     4,         13    \ Edge 16
 EDGE      17,      18,     4,     4,         14    \ Edge 17
 EDGE      15,      18,     4,     4,         12    \ Edge 18
 EDGE      16,      17,     4,     4,         12    \ Edge 19
 EDGE      20,      21,     4,     4,          7    \ Edge 20
 EDGE      20,      24,     4,     4,          5    \ Edge 21
 EDGE      21,      24,     4,     4,          5    \ Edge 22
 EDGE      19,      22,     4,     4,          7    \ Edge 23
 EDGE      19,      23,     4,     4,          5    \ Edge 24
 EDGE      22,      23,     4,     4,          5    \ Edge 25
 EDGE       0,       2,     1,     2,         30    \ Edge 26
 EDGE       0,       3,     1,     3,         30    \ Edge 27

.SHIP_MAMBA_FACES

    \ normal_x, normal_y, normal_z, visibility
 FACE        0,      -24,        2,         30    \ Face 0
 FACE        0,       24,        2,         30    \ Face 1
 FACE      -32,       64,       16,         30    \ Face 2
 FACE       32,       64,       16,         30    \ Face 3
 FACE        0,        0,     -127,         30    \ Face 4

\ ******************************************************************************
\
\       Name: SHIP_WORM
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Worm
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_WORM

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 99 * 99           \ Targetable area          = 99 * 99

 EQUB LO(SHIP_WORM_EDGES - SHIP_WORM)              \ Edges data offset (low)
 EQUB LO(SHIP_WORM_FACES - SHIP_WORM)              \ Faces data offset (low)

 EQUB 73                \ Max. edge count          = (73 - 1) / 4 = 18
 EQUB 0                 \ Gun vertex               = 0
 EQUB 18                \ Explosion count          = 3, as (4 * n) + 6 = 18
 EQUB 60                \ Number of vertices       = 60 / 6 = 10
 EQUB 16                \ Number of edges          = 16
 EQUW 0                 \ Bounty                   = 0
 EQUB 32                \ Number of faces          = 32 / 4 = 8
 EQUB 19                \ Visibility distance      = 19
 EQUB 30                \ Max. energy              = 30
 EQUB 23                \ Max. speed               = 23

 EQUB HI(SHIP_WORM_EDGES - SHIP_WORM)              \ Edges data offset (high)
 EQUB HI(SHIP_WORM_FACES - SHIP_WORM)              \ Faces data offset (high)

 EQUB 3                 \ Normals are scaled by    = 2^3 = 8
 EQUB %00001000         \ Laser power              = 1
                        \ Missiles                 = 0

.SHIP_WORM_VERTICES

      \    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX   10,  -10,   35,     2,      0,    7,     7,         31    \ Vertex 0
 VERTEX  -10,  -10,   35,     3,      0,    7,     7,         31    \ Vertex 1
 VERTEX    5,    6,   15,     1,      0,    4,     2,         31    \ Vertex 2
 VERTEX   -5,    6,   15,     1,      0,    5,     3,         31    \ Vertex 3
 VERTEX   15,  -10,   25,     4,      2,    7,     7,         31    \ Vertex 4
 VERTEX  -15,  -10,   25,     5,      3,    7,     7,         31    \ Vertex 5
 VERTEX   26,  -10,  -25,     6,      4,    7,     7,         31    \ Vertex 6
 VERTEX  -26,  -10,  -25,     6,      5,    7,     7,         31    \ Vertex 7
 VERTEX    8,   14,  -25,     4,      1,    6,     6,         31    \ Vertex 8
 VERTEX   -8,   14,  -25,     5,      1,    6,     6,         31    \ Vertex 9

.SHIP_WORM_EDGES

    \ vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     7,     0,         31    \ Edge 0
 EDGE       1,       5,     7,     3,         31    \ Edge 1
 EDGE       5,       7,     7,     5,         31    \ Edge 2
 EDGE       7,       6,     7,     6,         31    \ Edge 3
 EDGE       6,       4,     7,     4,         31    \ Edge 4
 EDGE       4,       0,     7,     2,         31    \ Edge 5
 EDGE       0,       2,     2,     0,         31    \ Edge 6
 EDGE       1,       3,     3,     0,         31    \ Edge 7
 EDGE       4,       2,     4,     2,         31    \ Edge 8
 EDGE       5,       3,     5,     3,         31    \ Edge 9
 EDGE       2,       8,     4,     1,         31    \ Edge 10
 EDGE       8,       6,     6,     4,         31    \ Edge 11
 EDGE       3,       9,     5,     1,         31    \ Edge 12
 EDGE       9,       7,     6,     5,         31    \ Edge 13
 EDGE       2,       3,     1,     0,         31    \ Edge 14
 EDGE       8,       9,     6,     1,         31    \ Edge 15

.SHIP_WORM_FACES

    \ normal_x, normal_y, normal_z, visibility
 FACE        0,       88,       70,         31    \ Face 0
 FACE        0,       69,       14,         31    \ Face 1
 FACE       70,       66,       35,         31    \ Face 2
 FACE      -70,       66,       35,         31    \ Face 3
 FACE       64,       49,       14,         31    \ Face 4
 FACE      -64,       49,       14,         31    \ Face 5
 FACE        0,        0,     -200,         31    \ Face 6
 FACE        0,      -80,        0,         31    \ Face 7

\ ******************************************************************************
\
\       Name: SHIP_FER_DE_LANCE
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Fer-de-Lance
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_FER_DE_LANCE

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 40 * 40           \ Targetable area          = 40 * 40

 EQUB LO(SHIP_FER_DE_LANCE_EDGES - SHIP_FER_DE_LANCE) \ Edges data offset (low)
 EQUB LO(SHIP_FER_DE_LANCE_FACES - SHIP_FER_DE_LANCE) \ Faces data offset (low)

 EQUB 105               \ Max. edge count          = (105 - 1) / 4 = 26
 EQUB 0                 \ Gun vertex               = 0
 EQUB 26                \ Explosion count          = 5, as (4 * n) + 6 = 26
 EQUB 114               \ Number of vertices       = 114 / 6 = 19
 EQUB 27                \ Number of edges          = 27
 EQUW 0                 \ Bounty                   = 0
 EQUB 40                \ Number of faces          = 40 / 4 = 10
 EQUB 40                \ Visibility distance      = 40
 EQUB 160               \ Max. energy              = 160
 EQUB 30                \ Max. speed               = 30

 EQUB HI(SHIP_FER_DE_LANCE_EDGES - SHIP_FER_DE_LANCE) \ Edges data offset (high)
 EQUB HI(SHIP_FER_DE_LANCE_FACES - SHIP_FER_DE_LANCE) \ Faces data offset (high)

 EQUB 1                 \ Normals are scaled by    = 2^1 = 2
 EQUB %00010010         \ Laser power              = 2
                        \ Missiles                 = 2

.SHIP_FER_DE_LANCE_VERTICES

      \    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX    0,  -14,  108,     1,      0,    9,     5,         31    \ Vertex 0
 VERTEX  -40,  -14,   -4,     2,      1,    9,     9,         31    \ Vertex 1
 VERTEX  -12,  -14,  -52,     3,      2,    9,     9,         31    \ Vertex 2
 VERTEX   12,  -14,  -52,     4,      3,    9,     9,         31    \ Vertex 3
 VERTEX   40,  -14,   -4,     5,      4,    9,     9,         31    \ Vertex 4
 VERTEX  -40,   14,   -4,     1,      0,    6,     2,         28    \ Vertex 5
 VERTEX  -12,    2,  -52,     3,      2,    7,     6,         28    \ Vertex 6
 VERTEX   12,    2,  -52,     4,      3,    8,     7,         28    \ Vertex 7
 VERTEX   40,   14,   -4,     4,      0,    8,     5,         28    \ Vertex 8
 VERTEX    0,   18,  -20,     6,      0,    8,     7,         15    \ Vertex 9
 VERTEX   -3,  -11,   97,     0,      0,    0,     0,         11    \ Vertex 10
 VERTEX  -26,    8,   18,     0,      0,    0,     0,          9    \ Vertex 11
 VERTEX  -16,   14,   -4,     0,      0,    0,     0,         11    \ Vertex 12
 VERTEX    3,  -11,   97,     0,      0,    0,     0,         11    \ Vertex 13
 VERTEX   26,    8,   18,     0,      0,    0,     0,          9    \ Vertex 14
 VERTEX   16,   14,   -4,     0,      0,    0,     0,         11    \ Vertex 15
 VERTEX    0,  -14,  -20,     9,      9,    9,     9,         12    \ Vertex 16
 VERTEX  -14,  -14,   44,     9,      9,    9,     9,         12    \ Vertex 17
 VERTEX   14,  -14,   44,     9,      9,    9,     9,         12    \ Vertex 18

.SHIP_FER_DE_LANCE_EDGES

    \ vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     9,     1,         31    \ Edge 0
 EDGE       1,       2,     9,     2,         31    \ Edge 1
 EDGE       2,       3,     9,     3,         31    \ Edge 2
 EDGE       3,       4,     9,     4,         31    \ Edge 3
 EDGE       0,       4,     9,     5,         31    \ Edge 4
 EDGE       0,       5,     1,     0,         28    \ Edge 5
 EDGE       5,       6,     6,     2,         28    \ Edge 6
 EDGE       6,       7,     7,     3,         28    \ Edge 7
 EDGE       7,       8,     8,     4,         28    \ Edge 8
 EDGE       0,       8,     5,     0,         28    \ Edge 9
 EDGE       5,       9,     6,     0,         15    \ Edge 10
 EDGE       6,       9,     7,     6,         11    \ Edge 11
 EDGE       7,       9,     8,     7,         11    \ Edge 12
 EDGE       8,       9,     8,     0,         15    \ Edge 13
 EDGE       1,       5,     2,     1,         14    \ Edge 14
 EDGE       2,       6,     3,     2,         14    \ Edge 15
 EDGE       3,       7,     4,     3,         14    \ Edge 16
 EDGE       4,       8,     5,     4,         14    \ Edge 17
 EDGE      10,      11,     0,     0,          8    \ Edge 18
 EDGE      11,      12,     0,     0,          9    \ Edge 19
 EDGE      10,      12,     0,     0,         11    \ Edge 20
 EDGE      13,      14,     0,     0,          8    \ Edge 21
 EDGE      14,      15,     0,     0,          9    \ Edge 22
 EDGE      13,      15,     0,     0,         11    \ Edge 23
 EDGE      16,      17,     9,     9,         12    \ Edge 24
 EDGE      16,      18,     9,     9,         12    \ Edge 25
 EDGE      17,      18,     9,     9,          8    \ Edge 26

.SHIP_FER_DE_LANCE_FACES

    \ normal_x, normal_y, normal_z, visibility
 FACE        0,       24,        6,         28    \ Face 0
 FACE      -68,        0,       24,         31    \ Face 1
 FACE      -63,        0,      -37,         31    \ Face 2
 FACE        0,        0,     -104,         31    \ Face 3
 FACE       63,        0,      -37,         31    \ Face 4
 FACE       68,        0,       24,         31    \ Face 5
 FACE      -12,       46,      -19,         28    \ Face 6
 FACE        0,       45,      -22,         28    \ Face 7
 FACE       12,       46,      -19,         28    \ Face 8
 FACE        0,      -28,        0,         31    \ Face 9

\ ******************************************************************************
\
\ Save D.MOL.bin
\
\ ******************************************************************************

 PRINT "S.D.MOL ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD%
 SAVE "3-assembled-output/D.MOL.bin", CODE%, CODE% + &0A00

