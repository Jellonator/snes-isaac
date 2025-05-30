#!/usr/bin/python3

import json
import os
from typing import Tuple
import pytiled_parser
from pathlib import Path

BASE_ROOM_DEFINITION_SIZE = 100
ENTITY_DEFINITION_SIZE = 4
total_room_data_size = 0

MAX_POOL_SIZE = 255

tiledIdsToGameIds = {
    -1: "BLOCK_REGULAR",
    0x00: "BLOCK_REGULAR",
    0x10: "BLOCK_ROCK",
    0x11: "BLOCK_ROCK_TINTED",
    0x08: "BLOCK_POOP",
    0x18: "BLOCK_LOGS"
}

tiledIdsToObjectIds = {
    0x00: "ENTITY_TYPE_ENEMY_ATTACK_FLY",
    0x01: "ENTITY_TYPE_ENEMY_ZOMBIE",
    0x02: "ENTITY_TYPE_ENEMY_BOSS_MONSTRO",
    0x03: "entityvariant(ENTITY_TYPE_ITEM_PEDASTAL, ENTITY_ITEMPEDASTAL_POOL_ITEMROOM)",
    0x04: "ENTITY_TYPE_SHOPKEEPER",
    0x05: "entityvariant(ENTITY_TYPE_TILE, ENTITYTILE_VARIANT_FIRE_NORMAL)",
    0x10: "entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_PENNY)",
    0x11: "entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_NICKEL)",
    0x12: "entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_DIME)",
    0x13: "entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_BOMB)",
    0x14: "entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_KEY)",
    0x15: "entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_BATTERY)",
    0x16: "entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_FULL)",
    0x17: "entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_SOUL)",
    0x20: "entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_SHOP)",
    0x21: "entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_ANY)",
    0x22: "entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_COIN)",
    0x23: "entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_HEART)",
    0x30: "entityvariant(ENTITY_TYPE_ITEM_PEDASTAL, ENTITY_ITEMPEDASTAL_POOL_SHOP | ENTITY_ITEMPEDASTAL_PRICED)",
    0x31: "entityvariant(ENTITY_TYPE_ITEM_PEDASTAL, ENTITY_ITEMPEDASTAL_POOL_DEVIL | ENTITY_ITEMPEDASTAL_HEARTCOST)",
    0x40: "entityvariant(ENTITY_TYPE_ENEMY_CUBE, 0)"
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
    raise RuntimeError("Invalid GID ${:02X} in map".format(gid))

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
    if "chapter" in tilemap.properties:
        out_inc.write("\t\tchapterOverride: .db {}\n".format(tilemap.properties["chapter"]))
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
                    print("Warning: unrecognized GID ${:02X} in {}".format(gid, room_path))
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
        else:
            raise RuntimeError("Invalid object in object layer in {}".format(room))
    total_room_data_size += BASE_ROOM_DEFINITION_SIZE + len(objects)
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

print("Finished importing rooms")
print("{}B room data".format(total_room_data_size))
print()