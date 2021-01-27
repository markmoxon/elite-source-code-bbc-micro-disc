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
