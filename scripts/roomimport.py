#!/usr/bin/python3

import json
import os
from typing import Tuple
import pytiled_parser
from pathlib import Path

MAX_POOL_SIZE = 255

tiledIdsToGameIds = {
    -1: "BLOCK_REGULAR",
    0: "BLOCK_REGULAR",
    16: "BLOCK_ROCK",
    17: "BLOCK_ROCK_TINTED",
    8: "BLOCK_POOP",
}

tiledIdsToObjectIds = {
    0: "ENTITY_TYPE_ENEMY_ATTACK_FLY",
    1: "ENTITY_TYPE_ENEMY_ZOMBIE",
    2: "ENTITY_TYPE_ENEMY_BOSS_MONSTRO",
    3: "ENTITY_TYPE_ITEM_PEDASTAL"
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
out_inc.write(".SECTION \"RoomDefinitions\" FREE\n")
out_inc.write("RoomDefinitions:\n")

roomPathToId = {}

def getTilesetForGid(map: pytiled_parser.TiledMap, gid: int) -> Tuple[pytiled_parser.Tileset, int]:
    for tileset in map.tilesets.values():
        if gid >= tileset.firstgid and gid < tileset.firstgid + tileset.tile_count:
            return (tileset, gid - tileset.firstgid)
    raise RuntimeError("Invalid GID {} in map".format(gid))

for room in rooms:
    # could probably improve this heehoo
    room_id = room.replace('.tmx', '').replace('/', '_')
    roomPathToId[room] = "RoomDefinitions@{}".format(room_id)
    room_path = os.path.join("assets/rooms", room)
    tilemap = pytiled_parser.parser.parse_map(Path(room_path))
    out_inc.write("\t.DSTRUCT @{} INSTANCEOF roomdefinition_t VALUES\n".format(room_id))
    dirls = []
    if tilemap.properties["up"]:
        dirls.append("DOOR_DEF_UP")
    if tilemap.properties["left"]:
        dirls.append("DOOR_DEF_LEFT")
    if tilemap.properties["right"]:
        dirls.append("DOOR_DEF_RIGHT")
    if tilemap.properties["down"]:
        dirls.append("DOOR_DEF_DOWN")
    if len(dirls) == 0:
        mask = "0"
    else:
        mask = '|'.join(dirls)
    out_inc.write("\t\tdoorMask:   .db {}\n".format(mask))
    out_inc.write("\t\troomSize:   .db ROOM_SIZE_REGULAR\n")
    tilelayers = [x for x in tilemap.layers if isinstance(x, pytiled_parser.TileLayer)]
    objectlayers = [x for x in tilemap.layers if isinstance(x, pytiled_parser.ObjectLayer)]
    objects = []
    if len(objectlayers) > 1:
        print("Warning: too many object layers in {}".format(room_path))
    elif len(objectlayers) == 0:
        # print("Warning: no object layers in {}".format(room_path))
        pass
    else:
        objects = objectlayers[0].tiled_objects
    out_inc.write("\t\tnumObjects: .db {}\n".format(len(objects)))
    out_inc.write("\t\ttileData:\n")
    if len(tilelayers) > 1:
        print("Warning: too many tile layers in {}".format(room_path))
    elif len(tilelayers) == 0:
        print("Warning: no tile layers in {}".format(room_path))
    else:
        layer = tilelayers[0]
        for row in layer.data:
            out_inc.write("\t\t.db")
            for value in row:
                gid = value - 1
                if gid in tiledIdsToGameIds:
                    out_inc.write(" {}".format(tiledIdsToGameIds[gid]))
                else:
                    print("Warning: unrecognized GID {} in {}".format(gid, room_path))
            out_inc.write("\n")
    out_inc.write("\t.ENDST\n")
    for obj in objects:
        if isinstance(obj, pytiled_parser.tiled_object.TiledObject):
            _tileset, tileid = getTilesetForGid(tilemap, obj.gid)
            x = int(obj.coordinates.x)
            y = int(obj.coordinates.y - obj.size.height)
            out_inc.write("\t\t.DSTRUCT INSTANCEOF objectdef_t VALUES\n")
            out_inc.write("\t\t\tx: .db {}\n\t\t\ty: .db {}\n".format(x, y))
            out_inc.write("\t\t\tobjectType: .dw {}\n".format(tiledIdsToObjectIds[tileid]))
            out_inc.write("\t\t.ENDST\n")
out_inc.write(".ENDS\n")

out_inc.write(".BANK $02 SLOT \"ROM\"\n")
out_inc.write(".SECTION \"RoomPoolDefinitions\" SUPERFREE\n")
out_inc.write("RoomPoolDefinitions:\n")
for pool in json_roompools:
    out_inc.write("\t.DSTRUCT @{} INSTANCEOF roompooldef_t VALUES\n".format(pool["id"]))
    # out_inc.write("\t@{}:\n".format(pool["id"]))
    out_inc.write("\t\tnumRooms: .db {}\n".format(len(pool["rooms"])))
    # out_inc.write("\t\t\t.db {}\n".format(len(pool["rooms"])))
    # out_inc.write("\t\t@@rooms:\n")
    out_inc.write("\t.ENDST\n")
    for room in pool["rooms"]:
        out_inc.write("\t\t.dl {}\n".format(roomPathToId[room]))
out_inc.write(".ENDS\n")