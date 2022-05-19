.define TEAR_ARRAY_MAX_COUNT 32
.define TEAR_ARRAY_MAX_SIZE (TEAR_ARRAY_MAX_COUNT*_sizeof_tear_t)

.RAMSECTION "V1" BANK $7E SLOT "MainMemory"
    ; joypad inputs
    joy1raw dw
    joy1press dw
    joy1held dw
    is_game_update_running dw
    last_used_sprite db
    sprite_data_ext INSTANCEOF byte_t 32
    gameSeed INSTANCEOF rng_t ; seed used for entire game
    gameSeedStored INSTANCEOF rng_t ; stored seed used for game (that way it can be displayed to player)
    stageSeed INSTANCEOF rng_t ; seed used to generate stage
    player INSTANCEOF player_t
    tear_bytes_used dw ; number of bytes used of tear_array
    tear_array INSTANCEOF tear_t TEAR_ARRAY_MAX_COUNT
    mapTileTypeTable INSTANCEOF byte_t MAP_MAX_SIZE
    mapTileFlagsTable INSTANCEOF byte_t MAP_MAX_SIZE
    numTilesToUpdate db ; set to $FF to update entire map
    numUsedMapSlots db
.ENDS

.RAMSECTION "V2" BANK $7E SLOT "ExtraMemory" SEMIFREE
    mapTileSlotTable INSTANCEOF byte_t MAP_MAX_SIZE
    mapSlots INSTANCEOF mapinfo_t MAX_MAP_SLOTS
    tilesToUpdate INSTANCEOF byte_t MAP_MAX_SIZE
.ENDS