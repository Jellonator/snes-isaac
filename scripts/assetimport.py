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

out_inc = open("include/assets.inc", 'w')

paletterefs = {}

for palette in json_palettes:
    paletterefs[palette["name"]] = palette
    palette["colors"][0] = [0, 0, 0]
    indices = {}
    for i, col in enumerate(palette["colors"]):
        if i == 0:
            continue
        if not (col[0], col[1], col[2]) in indices:
            indices[(col[0], col[1], col[2])] = i
    palette["indices"] = indices

while len(json_palettes) < 16:
    json_palettes.append({
        "name": "pallete{}".format(len(json_palettes)),
        "colors": [[0, 0, 0]] * 16
    })

out_inc.write("palettes:\n")
for palette in json_palettes:
    name = palette["name"]
    out_inc.write("\t@{}:\n".format(name))
    out_inc.write("\t\t.incbin \"palettes/{}.bin\"\n".format(name))
    out_inc.write("\t\t@@end:\n");
    palettebin = open(os.path.join(PALETTE_PATH, "{}.bin".format(name)), 'wb')
    for color in palette["colors"]:
        r = color[0]
        g = color[1]
        b = color[2]
        value = (b << 10) + (g << 5) + r
        palettebin.write(struct.pack("<H", value))

def write_image_tile(bin, image, palette, depth, tilex, tiley):
    indices = []
    for py in range(8):
        y = tiley * 8 + py
        for px in range(8):
            x = tilex * 8 + px
            color = image.getpixel((x, y))
            # print((x, y), color)
            if color[3] == 0:
                indices.append(0)
            elif color[3] != 255:
                raise RuntimeError()
            else:
                rcol = (color[0] >> 3, color[1] >> 3, color[2] >> 3)
                if not rcol in palette["indices"]:
                    raise RuntimeError()
                index = palette["indices"][rcol]
                if index >= depth:
                    print(index, depth, palette["indices"])
                    raise RuntimeError()
                indices.append(index)
    # Write first two bitplanes intertwined
    for iy in range(8):
        value1 = 0
        value2 = 0
        for i in range(8):
            if indices[i + iy*8] & 1 != 0:
                value1 |= 1 << i
            if indices[i + iy*8] & 2 != 0:
                value2 |= 1 << i
        bin.write(struct.pack("<BB", value1, value2))
    if depth == 16:
        # Write second two bitplanes intertwined
        for iy in range(8):
            value1 = 0
            value2 = 0
            for i in range(8):
                if indices[i + iy*8] & 4 != 0:
                    value1 |= 1 << i
                if indices[i + iy*8] & 8 != 0:
                    value2 |= 1 << i
            bin.write(struct.pack("<BB", value1, value2))

out_inc.write("sprites:\n")
for sprite in json_sprites:
    name = sprite["name"]
    image = Image.open(sprite["src"]).convert("RGBA")
    if image.size[0] not in [8, 16, 32, 64, 128]:
        raise RuntimeError("Invalid width {} in {}".format(image.size[0], sprite["src"]))
    if image.size[1] not in [8, 16, 32, 64, 128]:
        raise RuntimeError("Invalid height {} in {}".format(image.size[1], sprite["src"]))
    if sprite["depth"] not in [4, 16]:
        raise RuntimeError("Invalid depth {} for {}".format(sprite["depth"], sprite["src"]))
    sprite_out_path = os.path.join(SPRITE_PATH, "{}.bin".format(name))
    # Write info to assets.inc
    out_inc.write("\t@{}:\n".format(name))
    out_inc.write("\t\t.incbin \"sprites/{}.bin\"\n".format(name))
    out_inc.write("\t\t@@end:\n")
    # Write to binary file
    spritebin = open(sprite_out_path, 'wb')
    palette = paletterefs[sprite["palette"]]
    indices = []
    for ty in range(image.size[1] // 8):
        for tx in range(image.size[0] // 8):
            write_image_tile(spritebin, image, palette, sprite["depth"], tx, ty)

