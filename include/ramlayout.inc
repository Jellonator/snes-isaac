; I wish I could use RAMSECTIONs but god do they make compile times slow

.ENUM $0100
    ; joypad inputs
    joy1raw dw
    joy1press dw
    joy1held dw
    ; flags
    is_game_update_running dw
    last_used_sprite db
    ; RNG state
    gameSeed INSTANCEOF rng_t ; seed used for entire game
    gameSeedStored INSTANCEOF rng_t ; stored seed used for game (that way it can be displayed to player)
    stageSeed INSTANCEOF rng_t ; seed used to generate stage
    ; map data
    numTilesToUpdate db ; set to $FF to update entire map
    numUsedMapSlots db
    mapTileTypeTable INSTANCEOF byte_t MAP_MAX_SIZE
    mapTileFlagsTable INSTANCEOF byte_t MAP_MAX_SIZE
    loadedMapSlot db
    loadedMapAddressOffset dw
    loadedRoomIndex INSTANCEOF maptilepos_t
    ; game data
    player INSTANCEOF player_t
    tear_bytes_used dw ; number of bytes used of tear_array
    tear_array INSTANCEOF tear_t TEAR_ARRAY_MAX_COUNT
    ; OAM data
    objectData INSTANCEOF object_t 128
    objectDataExt dsb 32 ; 2 bits per object: Xs
    objectIndex dw
    ; VQueue data
    vqueueNumOps dw
    vqueueNumMiniOps dw
    vqueueBinOffset dw
    ; Room scroll data
    gameRoomBG2Offset dw ; % 000000y0 000x0000
    gameRoomScrollX dw
    gameRoomScrollY dw
    ; end
    rawMemorySizeShared db
.ENDE

.ENUM $7E2000
    ; map data
    mapTileSlotTable INSTANCEOF byte_t MAP_MAX_SIZE
    roomInfoSlots INSTANCEOF roominfo_t MAX_MAP_SLOTS
    tilesToUpdate INSTANCEOF byte_t MAP_MAX_SIZE
    ; end
    rawMemorySize7E db
.ENDE

.ENUM $7F0000
    ; VQueue data
    vqueueOps INSTANCEOF vqueueop_t VQUEUE_MAX_SIZE
    vqueueMiniOps INSTANCEOF vqueueminiop_t 255
    vqueueBinData INSTANCEOF byte_t $4000 ; 16K of potential DMA data
    ; end
    rawMemorySize7F db
.ENDE
