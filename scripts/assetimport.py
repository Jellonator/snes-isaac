#!/usr/bin/python3

import json
import struct
import os
from PIL import Image

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

out_inc.write(".BANK {} SLOT \"ROM\"\n".format(minbank))
out_inc.write(".SECTION \"IMPORTED_PALETTES\" SEMISUPERFREE BANKS {}-{}\n".format(maxbank,minbank))

for palette in json_palettes:
    name = palette["name"]
    out_inc.write("palettes.{}:\n".format(name))
    out_inc.write("\t.incbin \"palettes/{}.bin\"\n".format(name))
    # out_inc.write("\t@end:\n")
    palettebin = open(os.path.join(PALETTE_PATH, "{}.bin".format(name)), 'wb')
    with open(palette["src"], 'r') as hexfh:
        for hexline in hexfh.readlines():
            r = int(hexline[0:2], 16) >> 3
            g = int(hexline[2:4], 16) >> 3
            b = int(hexline[4:6], 16) >> 3
            value = (b << 10) + (g << 5) + r
            palettebin.write(struct.pack("<H", value))

out_inc.write(".ENDS\n")

def write_image_tile(bin, imageindices, depth, tilex, tiley, width):
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
    if depth == 16:
        # Write second two bitplanes intertwined
        for iy in range(8):
            value1 = 0
            value2 = 0
            for i in range(8):
                if indices[i + iy*8] & 4 != 0:
                    value1 |= 1 << (7-i)
                if indices[i + iy*8] & 8 != 0:
                    value2 |= 1 << (7-i)
            bin.write(struct.pack("<BB", value1, value2))

# out_inc.write("sprites:\n")
sprite_number = 1

for sprite in json_sprites:
    name = sprite["name"]
    # image = Image.open(sprite["src"]).convert("RGBA")
    imagefh = open(sprite["src"], 'rb')
    width, height = struct.unpack("<II", imagefh.read(8))
    imagedata = imagefh.read()
    if width % 8 != 0 or height % 8 != 0 or width*height != len(imagedata):
        raise RuntimeError("Invalid image size {}x{} in {}".format(width, height, sprite["src"]))
    if sprite["depth"] not in [4, 16]:
        raise RuntimeError("Invalid depth {} for {}".format(sprite["depth"], sprite["src"]))
    sprite_out_path = os.path.join(SPRITE_PATH, "{}.bin".format(name))
    # section header
    out_inc.write(".BANK {} SLOT \"ROM\"\n".format(minbank))
    out_inc.write(".SECTION \"IMPORTED_SPRITE_{}\" SEMISUPERFREE BANKS {}-{}\n".format(sprite_number,maxbank,minbank))
    sprite_number += 1
    # section data
    out_inc.write("spritedata.{}:\n".format(name))
    out_inc.write("\t.incbin \"sprites/{}.bin\"\n".format(name))
    # out_inc.write("\t@end:\n")
    # section output
    out_inc.write(".ENDS\n")
    # Write to binary file
    spritebin = open(sprite_out_path, 'wb')
    # get size
    size = sprite["size"] if "size" in sprite else 1
    ntilesx = width // 8
    ntilesy = height // 8
    for ty in range(0, ntilesy, size):
        for tx in range(0, ntilesx, size):
            for ty2 in range(ty, ty+size, 1):
                for tx2 in range(tx, tx+size, 1):
                    write_image_tile(spritebin, imagedata, sprite["depth"], tx2, ty2, width)

splat_number = 1

def insert_splat_run(out, x, y, length, ctx):
    # LENGTH
    # if ctx["length"] == None or abs(ctx["length"] - length) > 1:
    out.write(
"""    lda #{}
    sta.b $05
""".format(length))
    # elif length == ctx["length"] + 1:
    #     out.write("    inc.b $05\n")
    # elif length == ctx["length"] - 1:
    #     out.write("    dec.b $05\n")
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
