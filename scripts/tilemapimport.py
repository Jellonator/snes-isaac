#!/usr/bin/python3

import json
import os
from typing import Tuple
import pytiled_parser
from pathlib import Path
import struct

TILEMAP_OUT_PATH = "include/tilemaps"
TILEMAPS_IN = "assets/tilemaps.json"

if not os.path.exists(TILEMAP_OUT_PATH):
    os.mkdir(TILEMAP_OUT_PATH)

json_tilemaps = json.load(open(TILEMAPS_IN))

out_inc = open("include/tilemaps.inc", 'w')

maxbank="63"
minbank="32"

out_inc.write(".BANK {} SLOT \"ROM\"\n".format(minbank))
out_inc.write(".SECTION \"IMPORTED_TILEMAPS\" SEMISUPERFREE BANKS {}-{}\n".format(maxbank,minbank))

for json_tilemap in json_tilemaps:
    name = json_tilemap["name"]
    out = open(os.path.join(TILEMAP_OUT_PATH, "{}.bin".format(name)), 'wb')
    map_path = json_tilemap["src"]
    map_palette = json_tilemap["palette"] << 10
    map_priority = 0x2000 if json_tilemap["priority"] else 0x000
    map_default = json_tilemap["default"]
    tilemap = pytiled_parser.parser.parse_map(Path(map_path))
    tilelayers = [x for x in tilemap.layers if isinstance(x, pytiled_parser.TileLayer)]
    objectlayers = [x for x in tilemap.layers if isinstance(x, pytiled_parser.ObjectLayer)]
    data_size = 0
    if len(objectlayers) != 0:
        print("Warning: too many object layers in {}".format(map_path))
    if len(tilelayers) > 1:
        print("Warning: too many tile layers in {}".format(map_path))
    elif len(tilelayers) == 0:
        print("Warning: no tile layers in {}".format(map_path))
    else:
        layer = tilelayers[0]
        for row in layer.data:
            for cell in row:
                cell_id = 0
                cell_flipx = (cell & 0x8000_0000) >> 17
                cell_flipy = (cell & 0x4000_0000) >> 15
                if cell == 0:
                    cell_id = map_default
                else:
                    cell_id = (cell & 0x0FFF_FFFF) - 1
                    if cell_id >= 0x0400:
                        print("Warning: tilemap contains invalid cells")
                        cell_id = map_default
                value = cell_id | cell_flipx | cell_flipy | map_palette | map_priority
                out.write(struct.pack("<H", value))
                data_size += 2
    out_inc.write("tilemap.{}:\n".format(name))
    out_inc.write("\t.incbin \"tilemaps/{}.bin\"\n".format(name))
    print(map_path)
    print("Size: {}B".format(data_size))

out_inc.write(".ENDS\n")