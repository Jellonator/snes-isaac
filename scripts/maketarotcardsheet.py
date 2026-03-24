#!/usr/bin/python3

import json
import struct
import os
import io
from PIL import Image

INPUT_PATH = "assets/sprites/tarot_cards_big.raw"
OUTPUT_PATH = "bin/tarot_cards.png"

PALETTE_DEFAULT = "assets/palettes/consumable/tarot_cards1.hex"

TILE_WIDTH = 32
TILE_HEIGHT = 32

PALETTE_FILES = [
    PALETTE_DEFAULT,
    "assets/palettes/consumable/tarot_cards_magician.hex",
    "assets/palettes/consumable/tarot_cards_high_priestess.hex",
    "assets/palettes/consumable/tarot_cards_empress.hex",
    "assets/palettes/consumable/tarot_cards_emperor.hex",
    "assets/palettes/consumable/tarot_cards_hierophant.hex",
    "assets/palettes/consumable/tarot_cards_lovers.hex",
    "assets/palettes/consumable/tarot_cards_chariot.hex",
    "assets/palettes/consumable/tarot_cards_strength.hex",
    "assets/palettes/consumable/tarot_cards_hermit.hex",
    "assets/palettes/consumable/tarot_cards_wheel_of_fortune.hex",
    "assets/palettes/consumable/tarot_cards_justice.hex",
    "assets/palettes/consumable/tarot_cards_hanged_man.hex",
    "assets/palettes/consumable/tarot_cards_death.hex",
    "assets/palettes/consumable/tarot_cards_temperance.hex",
    "assets/palettes/consumable/tarot_cards_devil.hex",
    "assets/palettes/consumable/tarot_cards_tower.hex",
    "assets/palettes/consumable/tarot_cards_star.hex",
    "assets/palettes/consumable/tarot_cards_moon.hex",
    PALETTE_DEFAULT,
    PALETTE_DEFAULT,
    "assets/palettes/consumable/tarot_cards_world.hex",
    PALETTE_DEFAULT,
    PALETTE_DEFAULT,
]

def load_palette(path):
    arr = []
    with open(path, 'r') as hexfh:
        a = 0
        for hexline in hexfh.readlines():
            r = int(hexline[0:2], 16) & 0xF8
            g = int(hexline[2:4], 16) & 0xF8
            b = int(hexline[4:6], 16) & 0xF8
            r |= (r >> 5)
            g |= (g >> 5)
            b |= (b >> 5)
            arr += [(a << 24) | (r << 0) | (g << 8) | (b << 16)]
            a = 255
    return arr

palettes = [load_palette(x) for x in PALETTE_FILES]

def get_color(index, x, y):
    ix = x // TILE_WIDTH
    iy = y // TILE_HEIGHT
    paletteindex = ix + iy * 8
    # print(paletteindex, ix, iy)
    return palettes[paletteindex][index]

imagefh = open(INPUT_PATH, 'rb')
width, height = struct.unpack("<II", imagefh.read(8))
imagedata = imagefh.read()

buffer = bytearray(4 * width * height)
for i in range(len(imagedata)):
    x = (i % width)
    y = (i // width)
    paletteindex = imagedata[i]
    struct.pack_into("<I", buffer, 4 * i, get_color(paletteindex, x, y))

image = Image.frombytes("RGBA", (width, height), buffer)
image.save(OUTPUT_PATH)