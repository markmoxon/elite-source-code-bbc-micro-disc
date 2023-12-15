\ ******************************************************************************
\
\ DISC ELITE SHIP BLUEPRINTS FILE D
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
\ https://www.bbcelite.com/about_site/terminology_used_in_this_commentary.html
\
\ The deep dive articles referred to in this commentary can be found at
\ https://www.bbcelite.com/deep_dives
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary file:
\
\   * D.MOD.bin
\
\ ******************************************************************************

 INCLUDE "1-source-files/main-sources/elite-build-options.asm"

 GUARD &6000            \ Guard against assembling over screen memory

\ ******************************************************************************
\
\ Configuration variables
\
\ ******************************************************************************

 SHIP_MISSILE = &7F00   \ The address of the missile ship blueprint

 CODE% = &5600          \ The flight code loads this file at address &5600, at
 LOAD% = &5600          \ label XX21

 ORG CODE%

\ ******************************************************************************
\
\       Name: XX21
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprints lookup table for the D.MOD file
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
 EQUW SHIP_ASTEROID     \ AST  =  7 = Asteroid
 EQUW SHIP_SPLINTER     \ SPL  =  8 = Splinter
 EQUW 0
 EQUW 0
 EQUW SHIP_COBRA_MK_3   \ CYL  = 11 = Cobra Mk III
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW SHIP_VIPER        \ COPS = 16 = Viper
 EQUW SHIP_SIDEWINDER   \ SH3  = 17 = Sidewinder
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW SHIP_GECKO        \        21 = Gecko
 EQUW SHIP_COBRA_MK_1   \        22 = Cobra Mk I
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW SHIP_THARGOID     \ THG  = 29 = Thargoid
 EQUW SHIP_THARGON      \ TGL  = 30 = Thargon
 EQUW 0

\ ******************************************************************************
\
\       Name: E%
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprints default NEWB flags for the D.MOD file
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
 EQUB %00000000         \ Asteroid
 EQUB %00000000         \ Splinter
 EQUB 0
 EQUB 0
 EQUB %10100000         \ Cobra Mk III                      Innocent, escape pod
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB %11000010         \ Viper                   Bounty hunter, cop, escape pod
 EQUB %00001100         \ Sidewinder                             Hostile, pirate
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB %00001100         \ Gecko                                  Hostile, pirate
 EQUB %10001100         \ Cobra Mk I                 Hostile, pirate, escape pod
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB %00001100         \ Thargoid                               Hostile, pirate
 EQUB %00000100         \ Thargon                                        Hostile
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
\       Name: SHIP_ASTEROID
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for an asteroid
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_ASTEROID

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 80 * 80           \ Targetable area          = 80 * 80

 EQUB LO(SHIP_ASTEROID_EDGES - SHIP_ASTEROID)      \ Edges data offset (low)
 EQUB LO(SHIP_ASTEROID_FACES - SHIP_ASTEROID)      \ Faces data offset (low)

 EQUB 65                \ Max. edge count          = (65 - 1) / 4 = 16
 EQUB 0                 \ Gun vertex               = 0
 EQUB 34                \ Explosion count          = 7, as (4 * n) + 6 = 34
 EQUB 54                \ Number of vertices       = 54 / 6 = 9
 EQUB 21                \ Number of edges          = 21
 EQUW 5                 \ Bounty                   = 5
 EQUB 56                \ Number of faces          = 56 / 4 = 14
 EQUB 50                \ Visibility distance      = 50
 EQUB 60                \ Max. energy              = 60
 EQUB 30                \ Max. speed               = 30

 EQUB HI(SHIP_ASTEROID_EDGES - SHIP_ASTEROID)      \ Edges data offset (high)
 EQUB HI(SHIP_ASTEROID_FACES - SHIP_ASTEROID)      \ Faces data offset (high)

 EQUB 1                 \ Normals are scaled by    = 2^1 = 2
 EQUB %00000000         \ Laser power              = 0
                        \ Missiles                 = 0

.SHIP_ASTEROID_VERTICES

      \    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX    0,   80,    0,    15,     15,   15,    15,         31    \ Vertex 0
 VERTEX  -80,  -10,    0,    15,     15,   15,    15,         31    \ Vertex 1
 VERTEX    0,  -80,    0,    15,     15,   15,    15,         31    \ Vertex 2
 VERTEX   70,  -40,    0,    15,     15,   15,    15,         31    \ Vertex 3
 VERTEX   60,   50,    0,     5,      6,   12,    13,         31    \ Vertex 4
 VERTEX   50,    0,   60,    15,     15,   15,    15,         31    \ Vertex 5
 VERTEX  -40,    0,   70,     0,      1,    2,     3,         31    \ Vertex 6
 VERTEX    0,   30,  -75,    15,     15,   15,    15,         31    \ Vertex 7
 VERTEX    0,  -50,  -60,     8,      9,   10,    11,         31    \ Vertex 8

.SHIP_ASTEROID_EDGES

    \ vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     2,     7,         31    \ Edge 0
 EDGE       0,       4,     6,    13,         31    \ Edge 1
 EDGE       3,       4,     5,    12,         31    \ Edge 2
 EDGE       2,       3,     4,    11,         31    \ Edge 3
 EDGE       1,       2,     3,    10,         31    \ Edge 4
 EDGE       1,       6,     2,     3,         31    \ Edge 5
 EDGE       2,       6,     1,     3,         31    \ Edge 6
 EDGE       2,       5,     1,     4,         31    \ Edge 7
 EDGE       5,       6,     0,     1,         31    \ Edge 8
 EDGE       0,       5,     0,     6,         31    \ Edge 9
 EDGE       3,       5,     4,     5,         31    \ Edge 10
 EDGE       0,       6,     0,     2,         31    \ Edge 11
 EDGE       4,       5,     5,     6,         31    \ Edge 12
 EDGE       1,       8,     8,    10,         31    \ Edge 13
 EDGE       1,       7,     7,     8,         31    \ Edge 14
 EDGE       0,       7,     7,    13,         31    \ Edge 15
 EDGE       4,       7,    12,    13,         31    \ Edge 16
 EDGE       3,       7,     9,    12,         31    \ Edge 17
 EDGE       3,       8,     9,    11,         31    \ Edge 18
 EDGE       2,       8,    10,    11,         31    \ Edge 19
 EDGE       7,       8,     8,     9,         31    \ Edge 20

.SHIP_ASTEROID_FACES

    \ normal_x, normal_y, normal_z, visibility
 FACE        9,       66,       81,         31    \ Face 0
 FACE        9,      -66,       81,         31    \ Face 1
 FACE      -72,       64,       31,         31    \ Face 2
 FACE      -64,      -73,       47,         31    \ Face 3
 FACE       45,      -79,       65,         31    \ Face 4
 FACE      135,       15,       35,         31    \ Face 5
 FACE       38,       76,       70,         31    \ Face 6
 FACE      -66,       59,      -39,         31    \ Face 7
 FACE      -67,      -15,      -80,         31    \ Face 8
 FACE       66,      -14,      -75,         31    \ Face 9
 FACE      -70,      -80,      -40,         31    \ Face 10
 FACE       58,     -102,      -51,         31    \ Face 11
 FACE       81,        9,      -67,         31    \ Face 12
 FACE       47,       94,      -63,         31    \ Face 13

\ ******************************************************************************
\
\       Name: SHIP_SPLINTER
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a splinter
\  Deep dive: Ship blueprints
\
\ ------------------------------------------------------------------------------
\
\ The ship blueprint for the splinter reuses the edges data from the escape pod,
\ so the edges data offset is negative.
\
\ ******************************************************************************

.SHIP_SPLINTER

 EQUB 0 + (11 << 4)     \ Max. canisters on demise = 0
                        \ Market item when scooped = 11 + 1 = 12 (Minerals)
 EQUW 16 * 16           \ Targetable area          = 16 * 16

 EQUB LO(SHIP_ESCAPE_POD_EDGES - SHIP_SPLINTER)    \ Edges from escape pod
 EQUB LO(SHIP_SPLINTER_FACES - SHIP_SPLINTER) + 24 \ Faces data offset (low)

 EQUB 25                \ Max. edge count          = (25 - 1) / 4 = 6
 EQUB 0                 \ Gun vertex               = 0
 EQUB 22                \ Explosion count          = 4, as (4 * n) + 6 = 22
 EQUB 24                \ Number of vertices       = 24 / 6 = 4
 EQUB 6                 \ Number of edges          = 6
 EQUW 0                 \ Bounty                   = 0
 EQUB 16                \ Number of faces          = 16 / 4 = 4
 EQUB 8                 \ Visibility distance      = 8
 EQUB 20                \ Max. energy              = 20
 EQUB 10                \ Max. speed               = 10

 EQUB HI(SHIP_ESCAPE_POD_EDGES - SHIP_SPLINTER)    \ Edges from escape pod
 EQUB HI(SHIP_SPLINTER_FACES - SHIP_SPLINTER)      \ Faces data offset (low)

 EQUB 5                 \ Normals are scaled by    = 2^5 = 32
 EQUB %00000000         \ Laser power              = 0
                        \ Missiles                 = 0

.SHIP_SPLINTER_VERTICES

      \    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX  -24,  -25,   16,     2,      1,    3,     3,         31    \ Vertex 0
 VERTEX    0,   12,  -10,     2,      0,    3,     3,         31    \ Vertex 1
 VERTEX   11,   -6,    2,     1,      0,    3,     3,         31    \ Vertex 2
 VERTEX   12,   42,    7,     1,      0,    2,     2,         31    \ Vertex 3

.SHIP_SPLINTER_FACES

    \ normal_x, normal_y, normal_z, visibility
 FACE       35,        0,        4,         31    \ Face 0
 FACE        3,        4,        8,         31    \ Face 1
 FACE        1,        8,       12,         31    \ Face 2
 FACE       18,       12,        0,         31    \ Face 3

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
\       Name: SHIP_GECKO
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Gecko
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_GECKO

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 99 * 99           \ Targetable area          = 99 * 99

 EQUB LO(SHIP_GECKO_EDGES - SHIP_GECKO)            \ Edges data offset (low)
 EQUB LO(SHIP_GECKO_FACES - SHIP_GECKO)            \ Faces data offset (low)

 EQUB 65                \ Max. edge count          = (65 - 1) / 4 = 16
 EQUB 0                 \ Gun vertex               = 0
 EQUB 26                \ Explosion count          = 5, as (4 * n) + 6 = 26
 EQUB 72                \ Number of vertices       = 72 / 6 = 12
 EQUB 17                \ Number of edges          = 17
 EQUW 55                \ Bounty                   = 55
 EQUB 36                \ Number of faces          = 36 / 4 = 9
 EQUB 18                \ Visibility distance      = 18
 EQUB 70                \ Max. energy              = 70
 EQUB 30                \ Max. speed               = 30

 EQUB HI(SHIP_GECKO_EDGES - SHIP_GECKO)            \ Edges data offset (high)
 EQUB HI(SHIP_GECKO_FACES - SHIP_GECKO)            \ Faces data offset (high)

 EQUB 3                 \ Normals are scaled by    = 2^3 = 8
 EQUB %00010000         \ Laser power              = 2
                        \ Missiles                 = 0

.SHIP_GECKO_VERTICES

      \    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX  -10,   -4,   47,     3,      0,    5,     4,         31    \ Vertex 0
 VERTEX   10,   -4,   47,     1,      0,    3,     2,         31    \ Vertex 1
 VERTEX  -16,    8,  -23,     5,      0,    7,     6,         31    \ Vertex 2
 VERTEX   16,    8,  -23,     1,      0,    8,     7,         31    \ Vertex 3
 VERTEX  -66,    0,   -3,     5,      4,    6,     6,         31    \ Vertex 4
 VERTEX   66,    0,   -3,     2,      1,    8,     8,         31    \ Vertex 5
 VERTEX  -20,  -14,  -23,     4,      3,    7,     6,         31    \ Vertex 6
 VERTEX   20,  -14,  -23,     3,      2,    8,     7,         31    \ Vertex 7
 VERTEX   -8,   -6,   33,     3,      3,    3,     3,         16    \ Vertex 8
 VERTEX    8,   -6,   33,     3,      3,    3,     3,         17    \ Vertex 9
 VERTEX   -8,  -13,  -16,     3,      3,    3,     3,         16    \ Vertex 10
 VERTEX    8,  -13,  -16,     3,      3,    3,     3,         17    \ Vertex 11

.SHIP_GECKO_EDGES

    \ vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     3,     0,         31    \ Edge 0
 EDGE       1,       5,     2,     1,         31    \ Edge 1
 EDGE       5,       3,     8,     1,         31    \ Edge 2
 EDGE       3,       2,     7,     0,         31    \ Edge 3
 EDGE       2,       4,     6,     5,         31    \ Edge 4
 EDGE       4,       0,     5,     4,         31    \ Edge 5
 EDGE       5,       7,     8,     2,         31    \ Edge 6
 EDGE       7,       6,     7,     3,         31    \ Edge 7
 EDGE       6,       4,     6,     4,         31    \ Edge 8
 EDGE       0,       2,     5,     0,         29    \ Edge 9
 EDGE       1,       3,     1,     0,         30    \ Edge 10
 EDGE       0,       6,     4,     3,         29    \ Edge 11
 EDGE       1,       7,     3,     2,         30    \ Edge 12
 EDGE       2,       6,     7,     6,         20    \ Edge 13
 EDGE       3,       7,     8,     7,         20    \ Edge 14
 EDGE       8,      10,     3,     3,         16    \ Edge 15
 EDGE       9,      11,     3,     3,         17    \ Edge 16

.SHIP_GECKO_FACES

    \ normal_x, normal_y, normal_z, visibility
 FACE        0,       31,        5,         31    \ Face 0
 FACE        4,       45,        8,         31    \ Face 1
 FACE       25,     -108,       19,         31    \ Face 2
 FACE        0,      -84,       12,         31    \ Face 3
 FACE      -25,     -108,       19,         31    \ Face 4
 FACE       -4,       45,        8,         31    \ Face 5
 FACE      -88,       16,     -214,         31    \ Face 6
 FACE        0,        0,     -187,         31    \ Face 7
 FACE       88,       16,     -214,         31    \ Face 8

\ ******************************************************************************
\
\       Name: SHIP_COBRA_MK_1
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Cobra Mk I
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_COBRA_MK_1

 EQUB 3                 \ Max. canisters on demise = 3
 EQUW 99 * 99           \ Targetable area          = 99 * 99

 EQUB LO(SHIP_COBRA_MK_1_EDGES - SHIP_COBRA_MK_1)  \ Edges data offset (low)
 EQUB LO(SHIP_COBRA_MK_1_FACES - SHIP_COBRA_MK_1)  \ Faces data offset (low)

 EQUB 69                \ Max. edge count          = (69 - 1) / 4 = 17
 EQUB 40                \ Gun vertex               = 40 / 4 = 10
 EQUB 26                \ Explosion count          = 5, as (4 * n) + 6 = 26
 EQUB 66                \ Number of vertices       = 66 / 6 = 11
 EQUB 18                \ Number of edges          = 18
 EQUW 75                \ Bounty                   = 75
 EQUB 40                \ Number of faces          = 40 / 4 = 10
 EQUB 19                \ Visibility distance      = 19
 EQUB 90                \ Max. energy              = 90
 EQUB 26                \ Max. speed               = 26

 EQUB HI(SHIP_COBRA_MK_1_EDGES - SHIP_COBRA_MK_1)  \ Edges data offset (high)
 EQUB HI(SHIP_COBRA_MK_1_FACES - SHIP_COBRA_MK_1)  \ Faces data offset (high)

 EQUB 2                 \ Normals are scaled by    = 2^2 = 4
 EQUB %00010010         \ Laser power              = 2
                        \ Missiles                 = 2

.SHIP_COBRA_MK_1_VERTICES

      \    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX  -18,   -1,   50,     1,      0,    3,     2,         31    \ Vertex 0
 VERTEX   18,   -1,   50,     1,      0,    5,     4,         31    \ Vertex 1
 VERTEX  -66,    0,    7,     3,      2,    8,     8,         31    \ Vertex 2
 VERTEX   66,    0,    7,     5,      4,    9,     9,         31    \ Vertex 3
 VERTEX  -32,   12,  -38,     6,      2,    8,     7,         31    \ Vertex 4
 VERTEX   32,   12,  -38,     6,      4,    9,     7,         31    \ Vertex 5
 VERTEX  -54,  -12,  -38,     3,      1,    8,     7,         31    \ Vertex 6
 VERTEX   54,  -12,  -38,     5,      1,    9,     7,         31    \ Vertex 7
 VERTEX    0,   12,   -6,     2,      0,    6,     4,         20    \ Vertex 8
 VERTEX    0,   -1,   50,     1,      0,    1,     1,          2    \ Vertex 9
 VERTEX    0,   -1,   60,     1,      0,    1,     1,         31    \ Vertex 10

.SHIP_COBRA_MK_1_EDGES

    \ vertex1, vertex2, face1, face2, visibility
 EDGE       1,       0,     1,     0,         31    \ Edge 0
 EDGE       0,       2,     3,     2,         31    \ Edge 1
 EDGE       2,       6,     8,     3,         31    \ Edge 2
 EDGE       6,       7,     7,     1,         31    \ Edge 3
 EDGE       7,       3,     9,     5,         31    \ Edge 4
 EDGE       3,       1,     5,     4,         31    \ Edge 5
 EDGE       2,       4,     8,     2,         31    \ Edge 6
 EDGE       4,       5,     7,     6,         31    \ Edge 7
 EDGE       5,       3,     9,     4,         31    \ Edge 8
 EDGE       0,       8,     2,     0,         20    \ Edge 9
 EDGE       8,       1,     4,     0,         20    \ Edge 10
 EDGE       4,       8,     6,     2,         16    \ Edge 11
 EDGE       8,       5,     6,     4,         16    \ Edge 12
 EDGE       4,       6,     8,     7,         31    \ Edge 13
 EDGE       5,       7,     9,     7,         31    \ Edge 14
 EDGE       0,       6,     3,     1,         20    \ Edge 15
 EDGE       1,       7,     5,     1,         20    \ Edge 16
 EDGE      10,       9,     1,     0,          2    \ Edge 17

.SHIP_COBRA_MK_1_FACES

    \ normal_x, normal_y, normal_z, visibility
 FACE        0,       41,       10,         31    \ Face 0
 FACE        0,      -27,        3,         31    \ Face 1
 FACE       -8,       46,        8,         31    \ Face 2
 FACE      -12,      -57,       12,         31    \ Face 3
 FACE        8,       46,        8,         31    \ Face 4
 FACE       12,      -57,       12,         31    \ Face 5
 FACE        0,       49,        0,         31    \ Face 6
 FACE        0,        0,     -154,         31    \ Face 7
 FACE     -121,      111,      -62,         31    \ Face 8
 FACE      121,      111,      -62,         31    \ Face 9

\ ******************************************************************************
\
\       Name: SHIP_THARGOID
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Thargoid mothership
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_THARGOID

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 99 * 99           \ Targetable area          = 99 * 99

 EQUB LO(SHIP_THARGOID_EDGES - SHIP_THARGOID)      \ Edges data offset (low)
 EQUB LO(SHIP_THARGOID_FACES - SHIP_THARGOID)      \ Faces data offset (low)

 EQUB 101               \ Max. edge count          = (101 - 1) / 4 = 25
 EQUB 60                \ Gun vertex               = 60 / 4 = 15
 EQUB 38                \ Explosion count          = 8, as (4 * n) + 6 = 38
 EQUB 120               \ Number of vertices       = 120 / 6 = 20
 EQUB 26                \ Number of edges          = 26
 EQUW 500               \ Bounty                   = 500
 EQUB 40                \ Number of faces          = 40 / 4 = 10
 EQUB 55                \ Visibility distance      = 55
 EQUB 240               \ Max. energy              = 240
 EQUB 39                \ Max. speed               = 39

 EQUB HI(SHIP_THARGOID_EDGES - SHIP_THARGOID)      \ Edges data offset (high)
 EQUB HI(SHIP_THARGOID_FACES - SHIP_THARGOID)      \ Faces data offset (high)

 EQUB 2                 \ Normals are scaled by    = 2^2 = 4
 EQUB %00010110         \ Laser power              = 2
                        \ Missiles                 = 6

.SHIP_THARGOID_VERTICES

      \    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX   32,  -48,   48,     0,      4,    8,     8,         31    \ Vertex 0
 VERTEX   32,  -68,    0,     0,      1,    4,     4,         31    \ Vertex 1
 VERTEX   32,  -48,  -48,     1,      2,    4,     4,         31    \ Vertex 2
 VERTEX   32,    0,  -68,     2,      3,    4,     4,         31    \ Vertex 3
 VERTEX   32,   48,  -48,     3,      4,    5,     5,         31    \ Vertex 4
 VERTEX   32,   68,    0,     4,      5,    6,     6,         31    \ Vertex 5
 VERTEX   32,   48,   48,     4,      6,    7,     7,         31    \ Vertex 6
 VERTEX   32,    0,   68,     4,      7,    8,     8,         31    \ Vertex 7
 VERTEX  -24, -116,  116,     0,      8,    9,     9,         31    \ Vertex 8
 VERTEX  -24, -164,    0,     0,      1,    9,     9,         31    \ Vertex 9
 VERTEX  -24, -116, -116,     1,      2,    9,     9,         31    \ Vertex 10
 VERTEX  -24,    0, -164,     2,      3,    9,     9,         31    \ Vertex 11
 VERTEX  -24,  116, -116,     3,      5,    9,     9,         31    \ Vertex 12
 VERTEX  -24,  164,    0,     5,      6,    9,     9,         31    \ Vertex 13
 VERTEX  -24,  116,  116,     6,      7,    9,     9,         31    \ Vertex 14
 VERTEX  -24,    0,  164,     7,      8,    9,     9,         31    \ Vertex 15
 VERTEX  -24,   64,   80,     9,      9,    9,     9,         30    \ Vertex 16
 VERTEX  -24,   64,  -80,     9,      9,    9,     9,         30    \ Vertex 17
 VERTEX  -24,  -64,  -80,     9,      9,    9,     9,         30    \ Vertex 18
 VERTEX  -24,  -64,   80,     9,      9,    9,     9,         30    \ Vertex 19

.SHIP_THARGOID_EDGES

    \ vertex1, vertex2, face1, face2, visibility
 EDGE       0,       7,     4,     8,         31    \ Edge 0
 EDGE       0,       1,     0,     4,         31    \ Edge 1
 EDGE       1,       2,     1,     4,         31    \ Edge 2
 EDGE       2,       3,     2,     4,         31    \ Edge 3
 EDGE       3,       4,     3,     4,         31    \ Edge 4
 EDGE       4,       5,     4,     5,         31    \ Edge 5
 EDGE       5,       6,     4,     6,         31    \ Edge 6
 EDGE       6,       7,     4,     7,         31    \ Edge 7
 EDGE       0,       8,     0,     8,         31    \ Edge 8
 EDGE       1,       9,     0,     1,         31    \ Edge 9
 EDGE       2,      10,     1,     2,         31    \ Edge 10
 EDGE       3,      11,     2,     3,         31    \ Edge 11
 EDGE       4,      12,     3,     5,         31    \ Edge 12
 EDGE       5,      13,     5,     6,         31    \ Edge 13
 EDGE       6,      14,     6,     7,         31    \ Edge 14
 EDGE       7,      15,     7,     8,         31    \ Edge 15
 EDGE       8,      15,     8,     9,         31    \ Edge 16
 EDGE       8,       9,     0,     9,         31    \ Edge 17
 EDGE       9,      10,     1,     9,         31    \ Edge 18
 EDGE      10,      11,     2,     9,         31    \ Edge 19
 EDGE      11,      12,     3,     9,         31    \ Edge 20
 EDGE      12,      13,     5,     9,         31    \ Edge 21
 EDGE      13,      14,     6,     9,         31    \ Edge 22
 EDGE      14,      15,     7,     9,         31    \ Edge 23
 EDGE      16,      17,     9,     9,         30    \ Edge 24
 EDGE      18,      19,     9,     9,         30    \ Edge 25

.SHIP_THARGOID_FACES

    \ normal_x, normal_y, normal_z, visibility
 FACE      103,      -60,       25,         31    \ Face 0
 FACE      103,      -60,      -25,         31    \ Face 1
 FACE      103,      -25,      -60,         31    \ Face 2
 FACE      103,       25,      -60,         31    \ Face 3
 FACE       64,        0,        0,         31    \ Face 4
 FACE      103,       60,      -25,         31    \ Face 5
 FACE      103,       60,       25,         31    \ Face 6
 FACE      103,       25,       60,         31    \ Face 7
 FACE      103,      -25,       60,         31    \ Face 8
 FACE      -48,        0,        0,         31    \ Face 9

\ ******************************************************************************
\
\       Name: SHIP_THARGON
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Thargon
\  Deep dive: Ship blueprints
\
\ ------------------------------------------------------------------------------
\
\ The ship blueprint for the Thargon reuses the edges data from the cargo
\ canister, so the edges data offset is negative.
\
\ ******************************************************************************

.SHIP_THARGON

 EQUB 0 + (15 << 4)     \ Max. canisters on demise = 0
                        \ Market item when scooped = 15 + 1 = 16 (alien items)
 EQUW 40 * 40           \ Targetable area          = 40 * 40

 EQUB LO(SHIP_CANISTER_EDGES - SHIP_THARGON)       \ Edges from canister
 EQUB LO(SHIP_THARGON_FACES - SHIP_THARGON)        \ Faces data offset (low)

 EQUB 65                \ Max. edge count          = (65 - 1) / 4 = 16
 EQUB 0                 \ Gun vertex               = 0
 EQUB 18                \ Explosion count          = 3, as (4 * n) + 6 = 18
 EQUB 60                \ Number of vertices       = 60 / 6 = 10
 EQUB 15                \ Number of edges          = 15
 EQUW 50                \ Bounty                   = 50
 EQUB 28                \ Number of faces          = 28 / 4 = 7
 EQUB 20                \ Visibility distance      = 20
 EQUB 20                \ Max. energy              = 20
 EQUB 30                \ Max. speed               = 30

 EQUB HI(SHIP_CANISTER_EDGES - SHIP_THARGON)       \ Edges from canister
 EQUB HI(SHIP_THARGON_FACES - SHIP_THARGON)        \ Faces data offset (high)

 EQUB 2                 \ Normals are scaled by    = 2^2 = 4
 EQUB %00010000         \ Laser power              = 2
                        \ Missiles                 = 0

.SHIP_THARGON_VERTICES

      \    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX   -9,    0,   40,     1,      0,    5,     5,         31    \ Vertex 0
 VERTEX   -9,  -38,   12,     1,      0,    2,     2,         31    \ Vertex 1
 VERTEX   -9,  -24,  -32,     2,      0,    3,     3,         31    \ Vertex 2
 VERTEX   -9,   24,  -32,     3,      0,    4,     4,         31    \ Vertex 3
 VERTEX   -9,   38,   12,     4,      0,    5,     5,         31    \ Vertex 4
 VERTEX    9,    0,   -8,     5,      1,    6,     6,         31    \ Vertex 5
 VERTEX    9,  -10,  -15,     2,      1,    6,     6,         31    \ Vertex 6
 VERTEX    9,   -6,  -26,     3,      2,    6,     6,         31    \ Vertex 7
 VERTEX    9,    6,  -26,     4,      3,    6,     6,         31    \ Vertex 8
 VERTEX    9,   10,  -15,     5,      4,    6,     6,         31    \ Vertex 9

.SHIP_THARGON_FACES

    \ normal_x, normal_y, normal_z, visibility
 FACE      -36,        0,        0,         31    \ Face 0
 FACE       20,       -5,        7,         31    \ Face 1
 FACE       46,      -42,      -14,         31    \ Face 2
 FACE       36,        0,     -104,         31    \ Face 3
 FACE       46,       42,      -14,         31    \ Face 4
 FACE       20,        5,        7,         31    \ Face 5
 FACE       36,        0,        0,         31    \ Face 6

\ ******************************************************************************
\
\ Save D.MOD.bin
\
\ ******************************************************************************

 PRINT "S.D.MOD ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD%
 SAVE "3-assembled-output/D.MOD.bin", CODE%, CODE% + &0A00

