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
#   * output/ELITE4.unprot.bin
#   * output/D.CODE.unprot.bin
#   * output/T.CODE.unprot.bin
#
# and generates encrypted versions as follows:
#
#   * output/ELITE4.bin
#   * output/D.CODE.bin
#   * output/T.CODE.bin
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
scramble1_from = 0x2962
scramble1_to = 0x2A62
scramble1_eor = 0xA5

# LOADcode block
scramble2_from = 0x1AED
scramble2_to = 0x1B4F
scramble2_eor = 0x18

# DIALS, SHIP_MISSILE and WORDS blocks
scramble3_from = 0x1D4B
scramble3_to = 0x294B
scramble3_eor = 0xA5

# ELITE, ASOFT and CpASOFT blocks, plus padding to the end of the file
scramble4_from = 0x2A62
scramble4_to = 0x2E00
scramble4_eor = 0xA5

data_block = bytearray()

# Load assembled code file

elite_file = open("output/ELITE4.unprot.bin", "rb")
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

output_file = open("output/ELITE4.bin", "wb")
output_file.write(data_block)
output_file.close()

print("output/ELITE4.bin file saved")

# Configuration variables for D.CODE

load_address = 0x11E3
scramble_from = 0x1300
scramble_to = 0x5600
scramble_eor = 0x33

data_block = bytearray()

# Load assembled code file

elite_file = open("output/D.CODE.unprot.bin", "rb")
data_block.extend(elite_file.read())
elite_file.close()

# SC routine, which EORs bytes between &1300 and &9FFF

for n in range(scramble_from, scramble_to):
    data_block[n - load_address] = data_block[n - load_address] ^ (n % 256) ^ scramble_eor

# Write output file for D.CODE

output_file = open("output/D.CODE.bin", "wb")
output_file.write(data_block)
output_file.close()

print("output/D.CODE.bin file saved")

# Configuration variables for T.CODE

load_address = 0x11E3
scramble_from = 0x1300
scramble_to = 0x6000
scramble_eor = 0x33

data_block = bytearray()

# Load assembled code file

elite_file = open("output/T.CODE.unprot.bin", "rb")
data_block.extend(elite_file.read())
elite_file.close()

# SC routine, which EORs bytes between &1300 and &9FFF

for n in range(scramble_from, scramble_to):
    data_block[n - load_address] = data_block[n - load_address] ^ (n % 256) ^ scramble_eor

# Write output file for T.CODE

output_file = open("output/T.CODE.bin", "wb")
output_file.write(data_block)
output_file.close()

print("output/T.CODE.bin file saved")
