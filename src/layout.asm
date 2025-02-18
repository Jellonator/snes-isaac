.include "base.inc"

.BASE $00

; $00-$3F is reserved for temporary variables
; $40 should mostly be used for commonly used variables,
; or long pointers for use with [DIRECT],Y addressing
.RAMSECTION "ZP" BANK 0 SLOT "ZeroMemory" ORGA $0040 FORCE
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
    ; quick access to current room's RNG
    currentRoomRngAddress_Low dl
    currentRoomRngAddress_High dl
    ; ... used for a variety of purposes I guess. Just treat them as temp vars
    currentConsideredTileX dw
    currentConsideredTileY dw
    entitySpawnContext dw
; long pointers to current room's doors
    mapDoorNorth dl
    mapDoorEast dl
    mapDoorSouth dl
    mapDoorWest dl
.ENDS

; Bank used for somewhat commonly used variables that need to be in bank 0
; (or which are accessed so much, that accessing via .w is much faster)
.RAMSECTION "Shared" BANK 0 SLOT "SharedMemory" ORGA $0100 FORCE
; joypad inputs
    joy1raw dw
    joy1press dw
    joy1held dw
; flags
    is_game_update_running dw
    tickCounter dw
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
; OAM data
    objectData INSTANCEOF object_t 128
    objectDataExt dsb 32 ; 2 bits per object: Xs
    objectIndex dw
    objectIndexShadow dw
; Palette allocation data
    ; pointer to currently loaded palette
    palettePtr dsw 32
    ; number of references to each palette
    paletteRefCount dsw 32
    ; number of references to each palette
    paletteAllocMode dsw 32
; VQueue data
    vqueueNumOps dw
    vqueueNumMiniOps dw
    vqueueBinOffset dw
; Room scroll data
    gameRoomBG2Offset dw ; % 000000y0 000x0000
    gameRoomScrollX dw
    gameRoomScrollY dw
; Current room data
    currentRoomGroundData dl
    currentRoomGroundPalette dw
    roomBrightness db
; Floor data
    currentFloorIndex dw
    currentFloorPointer dw
    floorFlags dw
; Commonly used entity data
    entityExecutionOrder ds ENTITY_TOTAL_MAX
    entity_data_begin ds 0
    private_base_entity_combined_type_variant dsw ENTITY_TOTAL_MAX
    private_base_entity_combined_state_timer dsw ENTITY_TOTAL_MAX
    private_base_entity_combined_mask_signal dsw ENTITY_TOTAL_MAX
    private_base_entity_health dsw ENTITY_TOTAL_MAX
    ; position
    private_base_entity_posx dsw ENTITY_TOTAL_MAX
    private_base_entity_posy dsw ENTITY_TOTAL_MAX
    ; size
    private_base_entity_combined_box_x2y2 dsw ENTITY_TOTAL_MAX
    ; velocity
    private_base_entity_velocx dsw ENTITY_TOTAL_MAX
    private_base_entity_velocy dsw ENTITY_TOTAL_MAX
; Common entity data
    currentRoomEnemyCount dw
    currentRoomDoSpawnReward db
    ; spatial collision data (for entities)
    spatial_partition INSTANCEOF spatialpartitionlayer_t SPATIAL_LAYER_COUNT
    entity_data_end ds 01
    ; pathfinding data
    _pathfind_nearest_enemy_id_reserve ds 256
    _pathfind_player_data_reserve ds 256
    _pathfind_enemy_data_reserve ds 256
.ENDS

; Should contain data that is either large or not often used.
; For more efficient bank usage, this bank is mostly used for bank/game data
.RAMSECTION "7E" BANK $7E SLOT "ExtraMemory" ORGA $2000 FORCE
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
    private_mapDoorHorizontalEmptyBuf ds MAP_MAX_HEIGHT
    mapDoorHorizontal ds MAP_MAX_SIZE ; For index i: Connects room i with room i+1
    private_mapDoorVerticalEmptyBuf ds MAP_MAX_WIDTH
    mapDoorVertical ds MAP_MAX_SIZE ; For index i: Connects room i with room i+MAP_MAX_WIDTH
; sprite allocation data
    spriteTableKey dsw SPRITE_TABLE_TOTAL_SIZE
    spriteTablePtr dsw SPRITE_TABLE_TOTAL_SIZE
    spriteTableValue INSTANCEOF spritetab_t SPRITE_TABLE_TOTAL_SIZE
    spriteQueueTabNext ds SPRITE_QUEUE_SIZE+1
    spiteTableAvailableSlots dw
; other display data
    textDisplayTimer dw
    textLines dw
; extra entity data
; a lot of entity data can just be used here, since entity tick, init, and free
; are executed in bank $7E. If not in bank $7E, you must access with $long,X
    numEntities dw
    ; Y-sort of entities
    ; I'll figure out something to combine with later.
    ; YSORT is just one byte
    private_base_entity_combined_ysort_flash dsw ENTITY_TOTAL_MAX
    ; Custom data per entity
    private_entity_custom INSTANCEOF entitycustomdata_t 4
    ; Custom data per character
    private_entity_char_custom INSTANCEOF entitycharactercustomdata_t 16
    ; status effects of entities
    private_entity_char_statfx INSTANCEOF entitycharacterstatuseffectdata_t 2
    ; entity flags
    private_base_entity_flags dsw ENTITY_TOTAL_MAX
    ; contiguous data storage for various purposes
    ; index as (index * ENTITY_DATA_ARRAY_SIZE)
    ; in tick functions, Y is (index*2), so simply:
    ; tya
    ; .MultiplyStatic (ENTITY_DATA_ARRAY_SIZE/2)
    ; tay
    entity_array_data ds (ENTITY_TOTAL_MAX + 1) * ENTITY_DATA_ARRAY_SIZE
; room locations
    roomslot_star db
    roomslot_boss db
    roomslot_start db
    roomslot_shop db
    roomslot_secret1 db
    roomslot_secret2 db
; reserved data
    _extraneous_data_buffer2 ds 256
.ENDS

; Should contain data that is either large or not often used
; For more efficient bank usage, this bank is mostly used for video memory management
; Perhaps will be used for decompressed animated sprites?
.RAMSECTION "7F" BANK $7F SLOT "FullMemory" ORGA $0000 FORCE
; VQueue data
    vqueueOps INSTANCEOF vqueueop_t VQUEUE_MAX_SIZE
    vqueueMiniOps INSTANCEOF vqueueminiop_t 255
    ; at least 4K of potential DMA data. We can only transfer ~5K per frame ($1400),
    ; so if we somehow overreach this, we've messed something up bad.
    ; Grabbing vqueue buffer space should be rare anyways.
    ; $2000 - $087C = $1784
    vqueueBinData INSTANCEOF byte_t 1 ($4000 - (255 * _sizeof_vqueueminiop_t) - (VQUEUE_MAX_SIZE * _sizeof_vqueueop_t))
; Player sprite buffer
    ; 64 sprites × 4 tiles/sprite × 32 bytes/tile = $2000 bytes
    playerSpriteBuffer ds 64 * 4 * 32
; Ground data
    ; character data for ground tiles
    groundCharacterData ds $0C00*2
    ; list of tiles currently in the queue, so we don't duplicate ops
    groundTilesInList ds (32*32) / 8
    ; start of list; add new ops to
    groundOpListStart dw
    ; end of list; read ops from
    groundOpListEnd dw
    ; if true, reset entire ground
    needResetEntireGround db
    ; groundlist operations
    groundOpList_palette ds MAX_GROUND_OPS
    groundOpList_line ds MAX_GROUND_OPS
    groundOpList_startPx ds MAX_GROUND_OPS
    groundOpList_endPx ds MAX_GROUND_OPS
.ENDS

.DEFINE vqueueBinData_End $4000
.EXPORT vqueueBinData_End
