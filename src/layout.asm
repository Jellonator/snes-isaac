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
    ; Indicates in what context the entity's code is being executed.
    entityExecutionContext dw
; long pointers to current room's doors
    mapDoorNorth dl
    mapDoorEast dl
    mapDoorSouth dl
    mapDoorWest dl
; temp values; these are placed later, since they are guaranteed not to
; overwrite mapgenerator values (as they are mostly used for entitites).
    entityTargetAngle db
    entityTargetFound db
    entityParentChain db
    tempDP ds $80
.ENDS

; Bank used for somewhat commonly used variables that need to be in bank 0
; (or which are accessed so much, that accessing via .w is much faster)
.RAMSECTION "Shared" BANK 0 SLOT "SharedMemory" ORGA $0100 FORCE
; joypad inputs
    joy1raw dw
    joy1press dw
    joy1held dw
; flags
    isGameUpdateRunning dw
    tickCounter dw
    currentSaveSlot dw
    loadFromSaveState db
    didPlayerJustEnterRoom db
    ; Indicates if room is transitioning. Top bit also indicates if
    ; restored backup palette data is currently in use.
    isRoomTransitioning db
; pause menu
    isGamePaused db
    shouldGamePause db
    gamePauseTimer db
    pausePage db
    pauseSelect db
; RNG state
    ; seed used for entire game
    gameSeed INSTANCEOF rng_t
    ; stored seed used for game (that way it can be displayed to player)
    gameSeedStored INSTANCEOF rng_t
    ; seed used to generate stage
    stageSeed INSTANCEOF rng_t
    quickrandIndex dw
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
    ; Indicates allocation mode for each palette
    ; [paletteAllocMode] stores bits for used subpalettes, relative to subpalette index
    ; [paletteAllocMode+1] stores bits for used subpalettes, relative to palette index
    paletteAllocMode dsw 32
; VQueue data
    vqueueNumOps dw
    vqueueNumMiniOps dw
    vqueueBinOffset dw
    vqueueNumRegOps dw
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
; Auto-cleared entity data (will be cleared on game start and between floors)
    entity_data_begin ds 0 ; data from here to entity_data_end will be cleared
    private_base_entity_combined_type_variant dsw ENTITY_TOTAL_MAX
    spatial_partition INSTANCEOF spatialpartitionlayer_t SPATIAL_LAYER_COUNT
    currentRoomEnemyCount dw
    currentRoomDoSpawnReward db
    entity_data_end ds 1
; Commonly used entity data
    entityExecutionOrder ds ENTITY_TOTAL_MAX
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
; VRAM sprite allocation data
    ; managed sprite table keys (sprite id + palette)
    spriteTableKey dsw SPRITE_TABLE_TOTAL_SIZE
    ; black-box ptr table for the sprite hash table
    spriteTablePtr dsw SPRITE_TABLE_TOTAL_SIZE
    ; managed sprite table values (VRAM index and reference count)
    spriteTableValue INSTANCEOF spritetab_t SPRITE_TABLE_TOTAL_SIZE
    ; circular queue used for allocating raw VRAM slots. Used directly for
    ; animated sprites.
    spriteQueueTabNext ds SPRITE_QUEUE_SIZE+1
    spiteTableAvailableSlots dw
; RAM sprite allocation data, indexed [1,255] (0 is NULL)
    ; 1 if block is allocated, 0 otherwise
    private_spriteAllocTabActive ds SPRITE_ALLOC_NUM_TILES
    ; Number of allocated tiles (div 128)
    private_spriteAllocTabSize ds SPRITE_ALLOC_NUM_TILES
    ; Index of data block following this block
    private_spriteAllocTabNext ds SPRITE_ALLOC_NUM_TILES
    ; Index of data block preceding this block
    private_spriteAllocTabPrev ds SPRITE_ALLOC_NUM_TILES
; other display data
    textDisplayTimer dw
    textLines dw
; extra entity data
; a lot of entity data can just be used here, since entity tick, init, and free
; are executed in bank $7E. If not in bank $7E, you must access with $long,X
    numEntities dw
    ; Y-sort of entities and flash timer
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
    ; stored max health for characters
    private_entity_char_maximum_health dsw ENTITY_CHARACTER_MAX
; boss health bar data
    boss_health_need_rerender db
    boss_contributor_count db
    boss_contributor_array ds ENTITY_CHARACTER_MAX
; room locations
    roomslot_star db
    roomslot_boss db
    roomslot_start db
    roomslot_shop db
    roomslot_secret1 db
    roomslot_secret2 db
; devil deal flags
    floors_since_devil_deal db
    devil_deal_flags db
; HDMA buffers
; We double-buffer most HDMA buffers, so that we can write to the other buffer
; while the screen draws.
    ; in-memory HDMA window position buffers
    ; we store the [left, right] window bounds together as a 16b value in each buffer.
    ; This saves on DMA slot usage.
    ; 256B each should be sufficient; this is 85 value changes total + null terminator
    hdmaWindowMainPositionBuffer1 ds 512
    hdmaWindowMainPositionBuffer2 ds 512
    hdmaWindowMainPositionActiveBufferId db
    hdmaWindowSubPositionBuffer1 ds 512
    hdmaWindowSubPositionBuffer2 ds 512
    hdmaWindowSubPositionActiveBufferId db
; reserved data
    _extraneous_data_buffer2 ds 256
.ENDS

; Should contain data that is either large or not often used
; For more efficient bank usage, this bank is mostly used for video memory management
; Perhaps will be used for decompressed animated sprites?
.RAMSECTION "7F" BANK $7F SLOT "FullMemory" ORGA $0000 FORCE
; VQueue data
    ; Making a semi-reasonable assumption that $2000 bytes of vqueue bin data
    ; is enough for each frame. The most we push to it is about $0800 for a
    ; single tilemap.
    vqueueBinData ds $2000
    vqueueOps INSTANCEOF vqueueop_t VQUEUE_MAX_SIZE
    vqueueMiniOps INSTANCEOF vqueueminiop_t 255
    ; Vqueue regops. Note that 'addr' is 16B, but 'value' is 8B
    vqueueRegOps_Addr dsw 64
    vqueueRegOps_Value dsw 64
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
    ; temporary tile data buffer
    tempTileData ds $0800
; Allocatable sprite buffer data
    ; Sprite buffer. This represents four full pages of sprites.
    ; This provides a buffer for sprites to be allocated, decompressed, and swizzled.
    spriteAllocBuffer ds SPRITE_ALLOC_TILE_SIZE * SPRITE_ALLOC_NUM_TILES
.ENDS

.DEFINE vqueueBinData_End (vqueueBinData + _sizeof_vqueueBinData) EXPORT

; SRAM LAYOUT

; Save header
.RAMSECTION "SRAM0" BANK $20 SLOT "SRAM" ORGA $6000 FORCE
    ; 16 byte check value. If not equivalent to a certain value, then save
    ; files will be cleared on boot.
    saveCheck ds 16
    ; seed timers. these are incremented every frame when within the menu.
    ; These will be copied into the game seed when selecting a new run.
    seed_timer_low dw
    seed_timer_high dw
.ENDS

.RAMSECTION "SRAM0.save1" BANK $20 SLOT "SRAM" ORGA $6800 FORCE
    saveslot.0 INSTANCEOF saveslot_t
.ENDS

.RAMSECTION "SRAM0.save2" BANK $20 SLOT "SRAM" ORGA $7000 FORCE
    saveslot.1 INSTANCEOF saveslot_t
.ENDS

.RAMSECTION "SRAM0.save3" BANK $20 SLOT "SRAM" ORGA $7800 FORCE
    saveslot.2 INSTANCEOF saveslot_t
.ENDS

; Save states
.RAMSECTION "SRAM1" BANK $21 SLOT "SRAM" ORGA $6000 FORCE
    savestate.0 INSTANCEOF savestate_t
.ENDS

.RAMSECTION "SRAM2" BANK $22 SLOT "SRAM" ORGA $6000 FORCE
    savestate.1 INSTANCEOF savestate_t
.ENDS

.RAMSECTION "SRAM3" BANK $23 SLOT "SRAM" ORGA $6000 FORCE
    savestate.2 INSTANCEOF savestate_t
.ENDS