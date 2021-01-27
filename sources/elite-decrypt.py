#!/usr/bin/env python
#
# ******************************************************************************
#
# DISC ELITE DECRYPTION SCRIPT
#
# Written by Mark Moxon
#
# This script removes encryption and checksums from the compiled binary for the
# main game code. It reads the encrypted "D.CODE" and "T.CODE" binaries and
# generates decrypted versions as "D.CODE.decrypt.bin" and "T.CODE.decrypt.bin"
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

elite_file = open('binaries/D.CODE', 'rb')
data_block.extend(elite_file.read())
elite_file.close()

# SC routine, which EORs bytes between &1300 and &9FFF
# Can be reversed by simply repeating the EOR

for n in range(scramble_from, scramble_to):
    data_block[n - load_address] = data_block[n - load_address] ^ (n % 256) ^ scramble_eor

# Write output file for 'D.CODE.decrypt.bin'

output_file = open('binaries/D.CODE.decrypt.bin', 'wb')
output_file.write(data_block)
output_file.close()

print('"extracted/D.CODE.decrypt.bin" file saved')

# Configuration variables for T.CODE

load_address = 0x11E3
scramble_from = 0x1300
scramble_to = 0x6000
scramble_eor = 0x33

data_block = bytearray()

# Load assembled code file

elite_file = open('binaries/T.CODE', 'rb')
data_block.extend(elite_file.read())
elite_file.close()

# SC routine, which EORs bytes between &1300 and &9FFF
# Can be reversed by simply repeating the EOR

for n in range(scramble_from, scramble_to):
    data_block[n - load_address] = data_block[n - load_address] ^ (n % 256) ^ scramble_eor

# Write output file for 'T.CODE.decrypt.bin'

output_file = open('binaries/T.CODE.decrypt.bin', 'wb')
output_file.write(data_block)
output_file.close()

print('"extracted/T.CODE.decrypt.bin" file saved')
