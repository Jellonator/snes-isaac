#!/usr/bin/python3

import json
import os
import pytiled_parser
from pathlib import Path

MAX_POOL_SIZE = 255

tiledIdsToGameIds = {
    -1: 0,
    0: 0,
    16: 1,
    17: 2,
    8: 3,
}

ROOMPOOL_OUT = "include/roompools.inc"
ROOMPOOL_IN = "assets/rooms/roompools.json"

out_inc = open(ROOMPOOL_OUT, 'w')

json_roompools = json.load(open(ROOMPOOL_IN))

rooms = set()
for pool in json_roompools:
    if len(pool["rooms"]) > MAX_POOL_SIZE:
        print("Warning: too many rooms in pool {}".format(pool["name"]))
    for room in pool["rooms"]:
        rooms.add(room)

out_inc.write(".BANK $02 SLOT \"ROM\"\n")
out_inc.write(".SECTION \"RoomDefinitions\" SUPERFREE\n")
out_inc.write("RoomDefinitions:\n")

roomPathToId = {}

for room in rooms:
    # could probably improve this heehoo
    room_id = room.replace('.tmx', '').replace('/', '_')
    roomPathToId[room] = "RoomDefinitions@{}".format(room_id)
    room_path = os.path.join("assets/rooms", room)
    out_inc.write("\t.DSTRUCT @{} INSTANCEOF roomdefinition_t VALUES\n".format(room_id))
    out_inc.write("\t\tdoorMask:   .db DOOR_MASK\n")
    out_inc.write("\t\troomSize:   .db ROOM_SIZE_REGULAR\n")
    out_inc.write("\t\tnumObjects: .db 0\n")
    out_inc.write("\t\ttileData:\n")
    tilemap = pytiled_parser.parser.parse_map(Path(room_path))
    if len(tilemap.layers) > 1:
        print("Warning: too many tile layers in {}".format(room_path))
    elif len(tilemap.layers) == 0:
        print("Warning: no tile layers in {}".format(room_path))
    else:
        layer = tilemap.layers[0]
        for row in layer.data:
            out_inc.write("\t\t.db")
            for value in row:
                gid = value - 1
                if gid in tiledIdsToGameIds:
                    out_inc.write(" {}".format(tiledIdsToGameIds[gid]))
                else:
                    print("Warning: unrecognized GID {} in {}".format(gid, room_path), data)
            out_inc.write("\n")
    out_inc.write("\t.ENDST\n")
out_inc.write(".ENDS\n")

out_inc.write(".BANK $02 SLOT \"ROM\"\n")
out_inc.write(".SECTION \"RoomPoolDefinitions\" SUPERFREE\n")
out_inc.write("RoomPoolDefinitions:\n")
for pool in json_roompools:
    out_inc.write("\t@{}:\n".format(pool["id"]))
    out_inc.write("\t\t.db {}\n".format(len(pool["rooms"])))
    out_inc.write("\t\t@@rooms:\n")
    for room in pool["rooms"]:
        out_inc.write("\t\t\t.dl {}\n".format(roomPathToId[room]))
    out_inc.write("\t\t\t@@end:\n")
out_inc.write(".ENDS\n")