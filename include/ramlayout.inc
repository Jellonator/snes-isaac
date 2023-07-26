; I wish I could use RAMSECTIONs but god do they make compile times slow

; $00-$3F is reserved for temporary variables
; $40 should mostly be used for commonly used variables,
; or long pointers for use with [DIRECT],Y addressing
.ENUM $40
    currentRoomSlot db
    currentRoomTileTypeTableAddress dl
    currentRoomTileVariantTableAddress dl
    currentConsideredTileX dw
    currentConsideredTileY dw
    ; end
    rawMemorySizeZP db
.ENDE

; Bank used for somewhat commonly used variables that need to be in bank 0
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
    ; Commonly used entity data
    entity_type ds ENTITY_TOTAL_MAX
    entity_state ds ENTITY_TOTAL_MAX
    entity_variant ds ENTITY_TOTAL_MAX
    entity_timer ds ENTITY_TOTAL_MAX
    entity_posx ds ENTITY_TOTAL_MAX
    entity_posy ds ENTITY_TOTAL_MAX
    entity_data INSTANCEOF entitycharacterdata_t ENTITY_CHARACTER_MAX
    ; end
    rawMemorySizeShared db
.ENDE

; Should contain data that is either large or not often used.
; For more efficient bank usage, this bank is mostly used for bank/game data
.ENUM $7E2000
    ; map data
    mapTileSlotTable INSTANCEOF byte_t MAP_MAX_SIZE
    roomSlotTiles INSTANCEOF roominfo_t MAX_MAP_SLOTS
    roomSlotDoorMask ds MAX_MAP_SLOTS
    roomSlotMapPos INSTANCEOF maptilepos_t MAX_MAP_SLOTS
    roomSlotRoomType ds MAX_MAP_SLOTS
    roomSlotRoomSize ds MAX_MAP_SLOTS
    tilesToUpdate INSTANCEOF byte_t MAP_MAX_SIZE
    _mapDoorHorizontalEmptyBuf ds MAP_MAX_HEIGHT
    mapDoorHorizontal ds MAP_MAX_SIZE ; For index i: Connects room i with room i+1
    _mapDoorVerticalEmptyBuf ds MAP_MAX_WIDTH
    mapDoorVertical ds MAP_MAX_SIZE ; For index i: Connects room i with room i+MAP_MAX_WIDTH
    ; mapDoor variables are a bit larger than necessary for efficiency's sake
    tempData ds 256 ; Temp data that can be used for whatever purpose
    ; sprite allocation data
    spriteTableKey dsw SPRITE_TABLE_TOTAL_SIZE
    spriteTablePtr dsw SPRITE_TABLE_TOTAL_SIZE
    spriteTableValue INSTANCEOF spritetab_t SPRITE_TABLE_TOTAL_SIZE
    spriteQueueTabNext ds SPRITE_QUEUE_SIZE+1
    ; end
    rawMemorySize7E db
.ENDE

; Should contain data that is either large or not often used
; For more efficient bank usage, this bank is mostly used for video memory management
; Perhaps will be used for decompressed animated sprites?
.ENUM $7F0000
    ; VQueue data
    vqueueOps INSTANCEOF vqueueop_t VQUEUE_MAX_SIZE
    vqueueMiniOps INSTANCEOF vqueueminiop_t 255
    vqueueBinData INSTANCEOF byte_t $4000 ; 16K of potential DMA data
    ; end
    rawMemorySize7F db
.ENDE
