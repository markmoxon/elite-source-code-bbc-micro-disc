#!/usr/bin/env python
#
# ******************************************************************************
#
# DISC ELITE CHECKSUM SCRIPT
#
# Written by Mark Moxon
#
# This script applies encryption and checksums to the compiled binary for the
# main game code. It reads these unencrypted binary files:
#
#   * ELITE4.unprot.bin
#   * D.CODE.unprot.bin
#   * T.CODE.unprot.bin
#
# and generates encrypted versions as follows:
#
#   * ELITE4.bin
#   * D.CODE.bin
#   * T.CODE.bin
#
# ******************************************************************************

from __future__ import print_function
import sys

argv = sys.argv
argc = len(argv)
Encrypt = True

if argc > 1 and argv[1] == "-u":
    Encrypt = False

print("Disc Elite Checksum")
print("Encryption = ", Encrypt)

# Configuration variables for ELITE4

load_address = 0x1900

# TVT1code block
scramble1_from = 0x2962     # TVT1code
scramble1_to = 0x2A62       # ELITE
scramble1_eor = 0xA5

# LOADcode block
scramble2_from = 0x1AED     # LOADcode
scramble2_to = 0x1B4F       # CATDcode
scramble2_eor = 0x18

# DIALS, SHIP_MISSILE and WORDS blocks
scramble3_from = 0x1D4B     # DIALS
scramble3_to = 0x294B       # OSBmod
scramble3_eor = 0xA5

# ELITE, ASOFT and CpASOFT blocks, plus padding to the end of the file
scramble4_from = 0x2A62     # ELITE
scramble4_to = 0x2E00       # End of ELITE4 file
scramble4_eor = 0xA5

data_block = bytearray()

# Load assembled code file

elite_file = open("3-assembled-output/ELITE4.unprot.bin", "rb")
data_block.extend(elite_file.read())
elite_file.close()

# Commander data checksum

na_per_cent_offset = 0x29E3 - load_address
CH = 0x4B - 2
CY = 0
for i in range(CH, 0, -1):
    CH = CH + CY + data_block[na_per_cent_offset + i + 7]
    CY = (CH > 255) & 1
    CH = CH % 256
    CH = CH ^ data_block[na_per_cent_offset + i + 8]

print("Commander checksum = ", CH)

# Must have Commander checksum otherwise game will lock:

if Encrypt:
    checksum_offset = 0x2A35 - load_address
    data_block[checksum_offset] = CH ^ 0xA9
    data_block[checksum_offset + 1] = CH

# Extract unscrambled &1100-&11E3 for use in &55FF checksum below

start_1100 = scramble1_from - load_address
end_1100 = start_1100 + 0xE3
block_1100 = data_block[start_1100:end_1100]

# EOR bytes in the various blocks

for n in range(scramble1_from, scramble1_to):
    data_block[n - load_address] = data_block[n - load_address] ^ scramble1_eor

for n in range(scramble2_from, scramble2_to):
    data_block[n - load_address] = data_block[n - load_address] ^ scramble2_eor

for n in range(scramble3_from, scramble3_to):
    data_block[n - load_address] = data_block[n - load_address] ^ scramble3_eor

for n in range(scramble4_from, scramble4_to):
    data_block[n - load_address] = data_block[n - load_address] ^ scramble4_eor

# Write output file for ELITE4

output_file = open("3-assembled-output/ELITE4.bin", "wb")
output_file.write(data_block)
output_file.close()

print("3-assembled-output/ELITE4.bin file saved")

# Configuration variables for D.CODE

load_address = 0x11E3
scramble_from = 0x1300
scramble_to = 0x5600
scramble_eor = 0x33

data_block = bytearray()

# Load assembled code file

elite_file = open("3-assembled-output/D.CODE.unprot.bin", "rb")
data_block.extend(elite_file.read())
elite_file.close()

# SC routine, which EORs bytes between &1300 and &9FFF

for n in range(scramble_from, scramble_to):
    data_block[n - load_address] = data_block[n - load_address] ^ (n % 256) ^ scramble_eor

# Write output file for D.CODE

output_file = open("3-assembled-output/D.CODE.bin", "wb")
output_file.write(data_block)
output_file.close()

print("3-assembled-output/D.CODE.bin file saved")

# Configuration variables for T.CODE

load_address = 0x11E3
scramble_from = 0x1300
scramble_to = 0x6000
scramble_eor = 0x33

data_block = bytearray()

# Load assembled code file

elite_file = open("3-assembled-output/T.CODE.unprot.bin", "rb")
data_block.extend(elite_file.read())
elite_file.close()

# SC routine, which EORs bytes between &1300 and &9FFF

for n in range(scramble_from, scramble_to):
    data_block[n - load_address] = data_block[n - load_address] ^ (n % 256) ^ scramble_eor

# LOAD routine, which calculates checksum at &55FF in docked code
# This checksum is not correct - need to fix this at some point

load_address = 0x1100
checksum_address = 0x55FF
block_to_checksum = block_1100 + data_block

d_checksum = 0x11
carry = 1
for x in range(0x11, 0x54):
    for y in [0] + list(range(255, 0, -1)):
        i = x * 256 + y
        d_checksum += block_to_checksum[i - 0x1100] + carry
        if d_checksum > 255:
            carry = 1
        else:
            carry = 0
        d_checksum = d_checksum % 256
    carry = 0
    d_checksum = d_checksum % 256
d_checksum = d_checksum % 256

# if Encrypt:
#     data_block[checksum_address - load_address] = d_checksum % 256

print("&55FF docked code checksum = ", d_checksum)

# Write output file for T.CODE

output_file = open("3-assembled-output/T.CODE.bin", "wb")
output_file.write(data_block)
output_file.close()

print("3-assembled-output/T.CODE.bin file saved")
