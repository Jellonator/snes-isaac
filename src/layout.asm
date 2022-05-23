.include "base.inc"

.RAMSECTION "Flags" BANK $7E SLOT "SharedMemory"
    ; joypad inputs
    joy1raw dw
    joy1press dw
    joy1held dw
    is_game_update_running dw
    last_used_sprite db
.ENDS

.RAMSECTION "LevelData" BANK $7E SLOT "SharedMemory"
    gameSeed INSTANCEOF rng_t ; seed used for entire game
    gameSeedStored INSTANCEOF rng_t ; stored seed used for game (that way it can be displayed to player)
    stageSeed INSTANCEOF rng_t ; seed used to generate stage
.ENDS

.RAMSECTION "MapData" BANK $7E SLOT "SharedMemory"
    numTilesToUpdate db ; set to $FF to update entire map
    numUsedMapSlots db
    mapTileTypeTable INSTANCEOF byte_t MAP_MAX_SIZE
    mapTileFlagsTable INSTANCEOF byte_t MAP_MAX_SIZE
.ENDS

.RAMSECTION "GameData" BANK $7E SLOT "SharedMemory"
    player INSTANCEOF player_t
    tear_bytes_used dw ; number of bytes used of tear_array
    tear_array INSTANCEOF tear_t TEAR_ARRAY_MAX_COUNT
.ENDS

; Data that is transferred to OAM
.RAMSECTION "OAMData" BANK $7E SLOT "SharedMemory"
    objectData INSTANCEOF object_t 128
    objectDataExt dsb 32 ; 2 bits per object: Xs
    objectIndex dw
.ENDS

.RAMSECTION "MapDataExt" BANK $7E SLOT "ExtraMemory" SEMIFREE
    mapTileSlotTable INSTANCEOF byte_t MAP_MAX_SIZE
    mapSlots INSTANCEOF mapinfo_t MAX_MAP_SLOTS
    tilesToUpdate INSTANCEOF byte_t MAP_MAX_SIZE
.ENDS