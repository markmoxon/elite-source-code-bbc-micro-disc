#!/usr/bin/env python
#
# ******************************************************************************
#
# DISC ELITE CHECKSUM SCRIPT
#
# Written by Mark Moxon
#
# This script applies encryption and checksums to the compiled binary for the
# main game code. It reads the unencrypted "D.CODE.decrypt.bin" and
# "T.CODE.decrypt.bin" binaries and generates encrypted versions as "D.CODE" and
# "T.CODE"
#
# ******************************************************************************

from __future__ import print_function

# Configuration variables for ELITE4

load_address = 0x1900

# BEGIN block
scramble1_from = 0x2962
scramble1_to = 0x2A62
scramble1_eor = 0xA5

# LOD2 block
scramble2_from = 0x1AED
scramble2_to = 0x1B4F
scramble2_eor = 0x18

# DIALS and SHIP_MISSILE blocks
scramble3_from = 0x1D4B
scramble3_to = 0x294B
scramble3_eor = 0xA5

# ELITE, ASOFT, CpASOFT blocks and padding to the end of the file
scramble4_from = 0x2A62
scramble4_to = 0x2E00
scramble4_eor = 0xA5

data_block = bytearray()

# Load assembled code file

elite_file = open('output/ELITE4.unprot.bin', 'rb')
data_block.extend(elite_file.read())
elite_file.close()

# EOR bytes in the various blocks

for n in range(scramble1_from, scramble1_to):
    data_block[n - load_address] = data_block[n - load_address] ^ scramble1_eor

for n in range(scramble2_from, scramble2_to):
    data_block[n - load_address] = data_block[n - load_address] ^ scramble2_eor

for n in range(scramble3_from, scramble3_to):
    data_block[n - load_address] = data_block[n - load_address] ^ scramble3_eor

for n in range(scramble4_from, scramble4_to):
    data_block[n - load_address] = data_block[n - load_address] ^ scramble4_eor

# Write output file for 'ELITE4.bin'

output_file = open('output/ELITE4.bin', 'wb')
output_file.write(data_block)
output_file.close()

print('"output/ELITE4.bin" file saved')

# Configuration variables for D.CODE

load_address = 0x11E3
scramble_from = 0x1300
scramble_to = 0x5600
scramble_eor = 0x33

data_block = bytearray()

# Load assembled code file

elite_file = open('output/D.CODE.unprot.bin', 'rb')
data_block.extend(elite_file.read())
elite_file.close()

# SC routine, which EORs bytes between &1300 and &9FFF

for n in range(scramble_from, scramble_to):
    data_block[n - load_address] = data_block[n - load_address] ^ (n % 256) ^ scramble_eor

# Write output file for 'D.CODE.bin'

output_file = open('output/D.CODE.bin', 'wb')
output_file.write(data_block)
output_file.close()

print('"output/D.CODE.bin" file saved')

# Configuration variables for T.CODE

load_address = 0x11E3
scramble_from = 0x1300
scramble_to = 0x6000
scramble_eor = 0x33

data_block = bytearray()

# Load assembled code file

elite_file = open('output/T.CODE.unprot.bin', 'rb')
data_block.extend(elite_file.read())
elite_file.close()

# SC routine, which EORs bytes between &1300 and &9FFF

for n in range(scramble_from, scramble_to):
    data_block[n - load_address] = data_block[n - load_address] ^ (n % 256) ^ scramble_eor

# Write output file for 'T.CODE.bin'

output_file = open('output/T.CODE.bin', 'wb')
output_file.write(data_block)
output_file.close()

print('"output/T.CODE.bin" file saved')
