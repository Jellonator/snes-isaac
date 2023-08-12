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
; long pointers to current room's doors
    mapDoorNorth dl
    mapDoorEast dl
    mapDoorSouth dl
    mapDoorWest dl
    ; end
    rawMemorySizeZP db
.ENDE

; Bank used for somewhat commonly used variables that need to be in bank 0
; (or which are accessed so much, that accessing via .w is much faster)
.ENUM $0100
; joypad inputs
    joy1raw dw
    joy1press dw
    joy1held dw
; flags
    is_game_update_running dw
    last_used_sprite db
; RNG state
    ; seed used for entire game
    gameSeed INSTANCEOF rng_t 
    ; stored seed used for game (that way it can be displayed to player)
    gameSeedStored INSTANCEOF rng_t 
    ; seed used to generate stage
    stageSeed INSTANCEOF rng_t
; map data
    ; set to $FF to update entire map
    numTilesToUpdate db
    numUsedMapSlots db
    mapTileTypeTable INSTANCEOF byte_t MAP_MAX_SIZE
    mapTileFlagsTable INSTANCEOF byte_t MAP_MAX_SIZE
    loadedMapSlot db
    loadedRoomIndex INSTANCEOF maptilepos_t
; player ext data
    playerData INSTANCEOF playerextdata_t
; tear/projectile data
    projectile_velocx dsw PROJECTILE_ARRAY_MAX_COUNT
    projectile_velocy dsw PROJECTILE_ARRAY_MAX_COUNT
    projectile_posx dsw PROJECTILE_ARRAY_MAX_COUNT
    projectile_posy dsw PROJECTILE_ARRAY_MAX_COUNT
    projectile_lifetime dsw PROJECTILE_ARRAY_MAX_COUNT
    projectile_flags dsw PROJECTILE_ARRAY_MAX_COUNT
    projectile_damage dsw PROJECTILE_ARRAY_MAX_COUNT
    _projectile_base_size_type dsw PROJECTILE_ARRAY_MAX_COUNT
    projectile_count_2x dw
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
    _base_entity_combined_type_variant dsw ENTITY_TOTAL_MAX
    _base_entity_combined_state_timer dsw ENTITY_TOTAL_MAX
    _base_entity_combined_mask_signal dsw ENTITY_TOTAL_MAX
    _base_entity_health dsw ENTITY_TOTAL_MAX
    ; position
    _base_entity_posx dsw ENTITY_TOTAL_MAX
    _base_entity_posy dsw ENTITY_TOTAL_MAX
    ; size
    _base_entity_combined_box_x2y2 dsw ENTITY_TOTAL_MAX
    ; velocity
    _base_entity_velocx dsw ENTITY_TOTAL_MAX
    _base_entity_velocy dsw ENTITY_TOTAL_MAX
    ; Extraneous entity data (only for certain entity types)
    _ext_entity_custom INSTANCEOF entitycustomdatatableentry_t 16
    _ext_entity_statfx INSTANCEOF entitystatuseffectdata_t 2
    _bleh ds 11
; spatial collision data (for entities)
    spatial_partition INSTANCEOF spatialpartitionlayer_t SPATIAL_LAYER_COUNT
; pathfinding data
    pathfind_player_data ds 256
; end
    rawMemorySizeShared db
.ENDE

.define entity_type (_base_entity_combined_type_variant - 2)
.define entity_variant (_base_entity_combined_type_variant - 1)
.define entity_state (_base_entity_combined_state_timer - 2)
.define entity_timer (_base_entity_combined_state_timer - 1)
.define entity_health (_base_entity_health - 2)
.define entity_posx (_base_entity_posx - 2)
.define entity_posy (_base_entity_posy - 2)
.define entity_velocx (_base_entity_velocx - 2)
.define entity_velocy (_base_entity_velocy - 2)
.define entity_box_x1 (entity_posx + 1)
.define entity_box_y1 (entity_posy + 1)
.define entity_box_x2 (_base_entity_combined_box_x2y2 - 2)
.define entity_box_y2 (_base_entity_combined_box_x2y2 - 1)
.define entity_mask (_base_entity_combined_mask_signal - 2)
.define entity_signal (_base_entity_combined_mask_signal - 1)

.define player_posx (ENTITY_INDEX_PLAYER + entity_posx)
.define player_posy (ENTITY_INDEX_PLAYER + entity_posy)
.define player_velocx (ENTITY_INDEX_PLAYER + entity_velocx)
.define player_velocy (ENTITY_INDEX_PLAYER + entity_velocy)
.define player_box_x1 (ENTITY_INDEX_PLAYER + entity_box_x1)
.define player_box_x2 (ENTITY_INDEX_PLAYER + entity_box_x2)
.define player_box_y1 (ENTITY_INDEX_PLAYER + entity_box_y1)
.define player_box_y2 (ENTITY_INDEX_PLAYER + entity_box_y2)
.define player_mask (ENTITY_INDEX_PLAYER + entity_mask)
.define player_signal (ENTITY_INDEX_PLAYER + entity_signal)
.define player_type (ENTITY_INDEX_PLAYER + entity_type)

.define projectile_size _projectile_base_size_type
.define projectile_type (_projectile_base_size_type+1)

.REPT 16 INDEX i
    .define entity_char_custom.{i+1} _ext_entity_custom.{i+1} - 2
.ENDR

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
    ; sprite allocation data
    spriteTableKey dsw SPRITE_TABLE_TOTAL_SIZE
    spriteTablePtr dsw SPRITE_TABLE_TOTAL_SIZE
    spriteTableValue INSTANCEOF spritetab_t SPRITE_TABLE_TOTAL_SIZE
    spriteQueueTabNext ds SPRITE_QUEUE_SIZE+1
    ; reserve tempdata buffer, just to make sure it has space
    _res_tempData ds 256 ; Temp data that can be used for whatever purpose
    ; end
    rawMemorySize7E db
.ENDE

.DEFINE tempData $7EFF00

; Should contain data that is either large or not often used
; For more efficient bank usage, this bank is mostly used for video memory management
; Perhaps will be used for decompressed animated sprites?
.ENUM $7F0000
; VQueue data
    vqueueOps INSTANCEOF vqueueop_t VQUEUE_MAX_SIZE
    vqueueMiniOps INSTANCEOF vqueueminiop_t 255
    ; 16K of potential DMA data. We can only transfer ~5K per frame,
    ; so if we somehow overreach this, we've messed something up bad.
    vqueueBinData INSTANCEOF byte_t $4000
; end
    rawMemorySize7F db
.ENDE
