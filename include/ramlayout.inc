; I wish I could use RAMSECTIONs but god do they make compile times slow

; $00-$3F is reserved for temporary variables
; $40 should mostly be used for commonly used variables,
; or long pointers for use with [DIRECT],Y addressing
.ENUM $40
    ; Slot for the currently loaded room
    currentRoomSlot db
    ; map position of the currently loaded room
    loadedRoomIndex INSTANCEOF maptilepos_t
    ; Definition for current room
    currentRoomDefinition dw
    ; quick-read table for the current room's tile types
    currentRoomTileTypeTableAddress dl
    ; quick-read table for the current room's tile variants
    currentRoomTileVariantTableAddress dl
    ; ... used for a variety of purposes I guess. Just treat them as temp vars
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

.FUNCTION MAP_DOOR_MEM_LOC(i) (mapDoorNorth + (i * 3))

; Bank used for somewhat commonly used variables that need to be in bank 0
; (or which are accessed so much, that accessing via .w is much faster)
.ENUM $0100
; joypad inputs
    joy1raw dw
    joy1press dw
    joy1held dw
; flags
    is_game_update_running dw
; RNG state
    ; seed used for entire game
    gameSeed INSTANCEOF rng_t 
    ; stored seed used for game (that way it can be displayed to player)
    gameSeedStored INSTANCEOF rng_t 
    ; seed used to generate stage
    stageSeed INSTANCEOF rng_t
; map data
    ; set to $FF to update entire map.
    numTilesToUpdate db
    ; number of room slots currently in use
    numUsedMapSlots db
    ; type of each map tile (by location). See the 'ROOMTYPE' enum
    mapTileTypeTable INSTANCEOF byte_t MAP_MAX_SIZE
    ; flags for each map tile (by location). See the 'MAPTILE' enum
    mapTileFlagsTable INSTANCEOF byte_t MAP_MAX_SIZE
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
; Common entity data
    currentRoomEnemyCount dw
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
.define player_damageflag (ENTITY_INDEX_PLAYER + entity_health)

.define projectile_size _projectile_base_size_type
.define projectile_type (_projectile_base_size_type+1)

.REPT 16 INDEX i
    .define entity_char_custom.{i+1} _ext_entity_custom.{i+1} - 2
.ENDR

; Should contain data that is either large or not often used.
; For more efficient bank usage, this bank is mostly used for bank/game data
.ENUM $7E2000
; map data
    ; maps [maptilepos_t] -> [room slot]
    mapTileSlotTable INSTANCEOF byte_t MAP_MAX_SIZE
    ; full info for each room
    roomSlotTiles INSTANCEOF roominfo_t MAX_MAP_SLOTS
    ; door mask of each room, determines how it connects to nearby rooms
    roomSlotDoorMask ds MAX_MAP_SLOTS
    ; maps [room slot] -> [maptilepos_t]
    roomSlotMapPos INSTANCEOF maptilepos_t MAX_MAP_SLOTS
    ; room type (by slot). See the 'ROOMTYPE' enum
    roomSlotRoomType ds MAX_MAP_SLOTS
    ; room door data
    ; mapDoor variables are a bit larger than necessary for efficiency's sake
    _mapDoorHorizontalEmptyBuf ds MAP_MAX_HEIGHT
    mapDoorHorizontal ds MAP_MAX_SIZE ; For index i: Connects room i with room i+1
    _mapDoorVerticalEmptyBuf ds MAP_MAX_WIDTH
    mapDoorVertical ds MAP_MAX_SIZE ; For index i: Connects room i with room i+MAP_MAX_WIDTH
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
    ; ops + miniops: $087C
    vqueueOps INSTANCEOF vqueueop_t VQUEUE_MAX_SIZE
    vqueueMiniOps INSTANCEOF vqueueminiop_t 255
    ; at least 4K of potential DMA data. We can only transfer ~5K per frame ($1400),
    ; so if we somehow overreach this, we've messed something up bad.
    ; Grabbing vqueue buffer space should be rare anyways.
    ; $2000 - $087C = $1784
    vqueueBinData INSTANCEOF byte_t 1 ($2000 - (255 * _sizeof_vqueueminiop_t) - (VQUEUE_MAX_SIZE * _sizeof_vqueueop_t))
; end
    rawMemorySize7F db
.ENDE
