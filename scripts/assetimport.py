#!/usr/bin/python3

import json
import struct
import os
import io
import lz4.frame
import lz4.block

SPRITE_PATH = "include/sprites"
PALETTE_PATH = "include/palettes"

if not os.path.exists(SPRITE_PATH):
    os.mkdir(SPRITE_PATH)
if not os.path.exists(PALETTE_PATH):
    os.mkdir(PALETTE_PATH)

json_palettes = json.load(open("assets/palettes.json"))
json_sprites = json.load(open("assets/sprites.json"))
json_splats = json.load(open("assets/splats.json"))

out_inc = open("include/assets.inc", 'w')

maxbank="63"
minbank="32"

MASK_MODE_INTERLACE = "interlace"
MASK_MODE_NONE = ""

out_inc.write(".BANK {} SLOT \"ROM\"\n".format(minbank))
out_inc.write(".SECTION \"IMPORTED_PALETTES\" SEMISUPERFREE BANKS {}-{}\n".format(maxbank,minbank))

for palette in json_palettes:
    name = palette["name"]
    out_inc.write("palettes.{}:\n".format(name))
    out_inc.write("\t.incbin \"palettes/{}.bin\"\n".format(name))
    # out_inc.write("\t@end:\n")
    out_path = os.path.join(PALETTE_PATH, "{}.bin".format(name))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    palettebin = open(out_path, 'wb')
    with open(palette["src"], 'r') as hexfh:
        for hexline in hexfh.readlines():
            r = int(hexline[0:2], 16) >> 3
            g = int(hexline[2:4], 16) >> 3
            b = int(hexline[4:6], 16) >> 3
            value = (b << 10) + (g << 5) + r
            palettebin.write(struct.pack("<H", value))

out_inc.write(".ENDS\n")

def write_image_tile(bin, imageindices, depth, tilex, tiley, width, mask_mode):
    indices = []
    for py in range(8):
        y = tiley * 8 + py
        for px in range(8):
            x = tilex * 8 + px
            indices.append(imageindices[y * width + x])
    # Write first two bitplanes intertwined
    for iy in range(8):
        value1 = 0
        value2 = 0
        for i in range(8):
            if indices[i + iy*8] & 1 != 0:
                value1 |= 1 << (7-i)
            if indices[i + iy*8] & 2 != 0:
                value2 |= 1 << (7-i)
        bin.write(struct.pack("<BB", value1, value2))
    # Write second two bitplanes intertwined
    if depth == 16:
        for iy in range(8):
            value1 = 0
            value2 = 0
            for i in range(8):
                if indices[i + iy*8] & 4 != 0:
                    value1 |= 1 << (7-i)
                if indices[i + iy*8] & 8 != 0:
                    value2 |= 1 << (7-i)
            bin.write(struct.pack("<BB", value1, value2))
    # Write out mask, if interlaced
    if mask_mode == MASK_MODE_INTERLACE:
        for iy in range(8):
            value = 0
            for i in range(8):
                if indices[i + iy*8] != 0:
                    value |= 1 << (7-i)
            bin.write(struct.pack("<BB", value, value))

# out_inc.write("sprites:\n")
sprite_number = 1

def debug_print_lz4_blocks_bin(data):
    block_index = 0
    calc_file_size = 0
    while True:
        # Read TOKEN
        token = data.read(1)
        # Get literal size
        literal_size = (token[0] & 0xF0) >> 4
        if literal_size == 0x0F:
            read_size = 0xFF
            while read_size == 0xFF:
                read_size = data.read(1)[0]
                literal_size += read_size
        # Read and print literal data
        calc_file_size += literal_size
        literal_data = b''
        if literal_size != 0:
            literal_data = data.read(literal_size)
        print("L{}: ".format(block_index), len(literal_data))#' '.join('{:02X}'.format(x) for x in literal_data))
        # Get match data. If none, then end
        match_data = data.read(2)
        if len(match_data) == 0:
            print("Calc size is", calc_file_size)
            return
        # Get match size
        match_size = (token[0] & 0x0F)
        if match_size == 0x0F:
            read_size = 0xFF
            while read_size == 0xFF:
                read_size = data.read(1)[0]
                match_size += read_size
        match_size += 4
        calc_file_size += match_size
        print("M{}: {}B @-{}".format(block_index, match_size, struct.unpack("<H", match_data)[0]))
        block_index += 1

def calc_num_lz4_blocks(data):
    block_index = 0
    while True:
        # Read TOKEN
        token = data.read(1)
        # Get literal size
        literal_size = (token[0] & 0xF0) >> 4
        if literal_size == 0x0F:
            read_size = 0xFF
            while read_size == 0xFF:
                read_size = data.read(1)[0]
                literal_size += read_size
        # Read and discard literal data
        if literal_size != 0:
            data.read(literal_size)
        # Get match data. If none, then end
        match_data = data.read(2)
        if len(match_data) == 0:
            return block_index+1
        # Get and discard match size
        match_size = (token[0] & 0x0F)
        if match_size == 0x0F:
            read_size = 0xFF
            while read_size == 0xFF:
                read_size = data.read(1)[0]
        block_index += 1

# total_bytes_saved = 0

def write_sprite_bin(sprite_out_path, spritebin, compression_format, sprite):
    # global total_bytes_saved
    spritebin.flush()
    spritebin_out_file = open(sprite_out_path, 'wb')
    if compression_format == "none":
        spritebin_out_file.write(spritebin.getvalue())
    elif compression_format == "lz4":
        base_len = len(spritebin.getvalue())
        compressedbin = lz4.block.compress(spritebin.getvalue(), mode='high_compression', store_size=False)
        spritebin_out_file.write(struct.pack("<H", calc_num_lz4_blocks(io.BytesIO(compressedbin))))
        spritebin_out_file.write(compressedbin)
        new_len = len(compressedbin)
        # print("Compressed {} to \t{}B ({:.2f}%)".format(sprite["name"], new_len, (new_len * 100.0 / base_len)))
        # total_bytes_saved += (base_len - new_len)
    else:
        raise RuntimeError("Invalid compression \"{}\" for {}".format(compression_format, sprite["src"]))

for sprite in json_sprites:
    name = sprite["name"]
    imagefh = open(sprite["src"], 'rb')
    width, height = struct.unpack("<II", imagefh.read(8))
    imagedata = imagefh.read()
    split_frames = False
    current_frame = 0
    sprite_out_path = os.path.join(SPRITE_PATH, "{}.bin".format(name))
    # Determine parameters
    compression_format = "none"
    if "compression" in sprite:
        compression_format = sprite["compression"]
    if "splitframes" in sprite:
        split_frames = sprite["splitframes"]
    if "crop" in sprite:
        x = sprite["crop"][0]
        y = sprite["crop"][1]
        new_width = sprite["crop"][2]
        new_height = sprite["crop"][3]
        ary = bytearray()
        for iy in range(y, y+new_height):
            for ix in range(x, x+new_width):
                ary.append(imagedata[ix + iy*width])
        imagedata = bytes(ary)
        width = new_width
        height = new_height
    if width % 8 != 0 or height % 8 != 0 or width*height != len(imagedata):
        raise RuntimeError("Invalid image size {}x{} in {}".format(width, height, sprite["src"]))
    if sprite["depth"] not in [4, 16]:
        raise RuntimeError("Invalid depth {} for {}".format(sprite["depth"], sprite["src"]))
    mask_mode = ""
    if "mask" in sprite:
        mask_mode = sprite["mask"]
        if not mask_mode in [MASK_MODE_INTERLACE]:
            raise RuntimeError("Invalid mask mode \"{}\" for {}".format(mask_mode, sprite["src"]))
    if not split_frames:
        # section header
        out_inc.write(".BANK {} SLOT \"ROM\"\n".format(minbank))
        out_inc.write(".SECTION \"IMPORTED_SPRITE_{}\" SEMISUPERFREE BANKS {}-{}\n".format(sprite_number,maxbank,minbank))
        sprite_number += 1
        # section data
        out_inc.write("spritedata.{}:\n".format(name))
        out_inc.write("\t.incbin \"sprites/{}.bin\"\n".format(name))
        # section output
        out_inc.write(".ENDS\n")
    # Write to binary file
    spritebin = io.BytesIO()
    # get size
    size_x = 1
    size_y = 1
    if "size" in sprite:
        if isinstance(sprite["size"], int):
            size_x = sprite["size"]
            size_y = sprite["size"]
        else:
            size_x = sprite["size"][0]
            size_y = sprite["size"][1]
    ntilesx = width // 8
    ntilesy = height // 8
    for ty in range(0, ntilesy, size_y):
        for tx in range(0, ntilesx, size_x):
            if split_frames:
                spritebin = io.BytesIO()
            for ty2 in range(ty, ty+size_y, 1):
                for tx2 in range(tx, tx+size_x, 1):
                    write_image_tile(spritebin, imagedata, sprite["depth"], tx2, ty2, width, mask_mode)
            if split_frames:
                # write bin
                subsprite_out_path = os.path.join(SPRITE_PATH, "{}.{}.bin".format(name, current_frame))
                write_sprite_bin(subsprite_out_path, spritebin, compression_format, sprite)
                # section header
                out_inc.write(".BANK {} SLOT \"ROM\"\n".format(minbank))
                out_inc.write(".SECTION \"IMPORTED_SPRITE_{}\" SEMISUPERFREE BANKS {}-{}\n".format(sprite_number,maxbank,minbank))
                sprite_number += 1
                # section data
                out_inc.write("spritedata.{}.{}:\n".format(name, current_frame))
                out_inc.write("\t.incbin \"sprites/{}.{}.bin\"\n".format(name, current_frame))
                # section output
                out_inc.write(".ENDS\n")
            current_frame += 1
    if not split_frames:
        write_sprite_bin(sprite_out_path, spritebin, compression_format, sprite)

# print("Saved a total of {}B".format(total_bytes_saved))

splat_number = 1

def insert_splat_run(out, x, y, length, ctx):
    # LENGTH
    out.write(
"""    lda #{}
    sta.b $05
""".format(length))
    # X
    if x == ctx["x"] + 1:
        out.write("    inc.b $07\n")
    elif x == ctx["x"] - 1:
        out.write("    dec.b $07\n")
    elif x != ctx["x"]:
        out.write(
"""    lda.b $07
    clc
    adc #{}
    sta.b $07
""".format(x - ctx["x"]))
    # Y
    if y == ctx["y"] + 1:
        out.write("    inc.b $06\n")
    elif y == ctx["y"] - 1:
        out.write("    dec.b $06\n")
    elif y != ctx["y"]:
        out.write(
"""    lda.b $06
    clc
    adc #{}
    sta.b $06
""".format(y - ctx["y"]))
    # Finalize
    out.write(
"""    jsl GroundAddOp
    sep #$20
""")
    ctx["length"] = length
    ctx["x"] = x
    ctx["y"] = y

for splat in json_splats:
    name = splat["name"]
    imagefh = open(splat["src"], 'rb')
    width, height = struct.unpack("<II", imagefh.read(8))
    imagedata = imagefh.read()
    if width*height != len(imagedata):
        raise RuntimeError("Invalid image size {}x{} in {}".format(width, height, splat["src"]))
    out_inc.write(".BANK {} SLOT \"ROM\"\n".format(minbank))
    out_inc.write(".SECTION \"IMPORTED_SPLAT_{}\" SUPERFREE\n".format(splat_number))
    splat_number += 1
    out_inc.write(
"""Splat.{}:
    sep #$30
    lda #{}
    sta.b $04
""".format(name, splat["palette"]))
    context = {
        "x": 0,
        "y": 0,
        "length": None
    }
    # print(imagedata)
    # print(imagedata[0] == 0)
    for iy in range(height):
        ix = 0
        while ix < width:
            if imagedata[iy*width+ix] != 0:
                cx = ix
                ix += 1
                while ix < width and imagedata[iy*width+ix] != 0:
                    ix += 1
                insert_splat_run(out_inc, cx, iy, ix-cx, context)
            ix += 1
    out_inc.write("    rtl\n")
    out_inc.write(".ENDS\n")
