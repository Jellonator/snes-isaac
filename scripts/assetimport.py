#!/usr/bin/python3

from email.mime import image
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

out_inc = open("include/assets.inc", 'w')

out_inc.write("palettes:\n")
for palette in json_palettes:
    name = palette["name"]
    out_inc.write("\t@{}:\n".format(name))
    out_inc.write("\t\t.incbin \"palettes/{}.bin\"\n".format(name))
    out_inc.write("\t\t@@end:\n");
    palettebin = open(os.path.join(PALETTE_PATH, "{}.bin".format(name)), 'wb')
    with open(palette["src"], 'r') as hexfh:
        for hexline in hexfh.readlines():
            r = int(hexline[0:2], 16) >> 3
            g = int(hexline[2:4], 16) >> 3
            b = int(hexline[4:6], 16) >> 3
            value = (b << 10) + (g << 5) + r
            palettebin.write(struct.pack("<H", value))

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

out_inc.write("sprites:\n")
for sprite in json_sprites:
    name = sprite["name"]
    # image = Image.open(sprite["src"]).convert("RGBA")
    imagefh = open(sprite["src"], 'rb')
    width, height = struct.unpack("<II", imagefh.read(8))
    imagedata = imagefh.read()
    if width % 8 != 0 or height % 8 != 0 or width*height != len(imagedata):
        raise RuntimeError("Invalid image size {}x{} in {}".format(width*height, sprite["src"]))
    if sprite["depth"] not in [4, 16]:
        raise RuntimeError("Invalid depth {} for {}".format(sprite["depth"], sprite["src"]))
    sprite_out_path = os.path.join(SPRITE_PATH, "{}.bin".format(name))
    # Write info to assets.inc
    out_inc.write("\t@{}:\n".format(name))
    out_inc.write("\t\t.incbin \"sprites/{}.bin\"\n".format(name))
    out_inc.write("\t\t@@end:\n")
    # Write to binary file
    spritebin = open(sprite_out_path, 'wb')
    for ty in range(height // 8):
        for tx in range(width // 8):
            write_image_tile(spritebin, imagedata, sprite["depth"], tx, ty, width)

