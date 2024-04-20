; single byte type
.STRUCT byte_t
    data db
.ENDST

; two byte type
.STRUCT word_t
    data dw
.ENDST

; three byte type
.STRUCT long_t
    data dl
.ENDST

; Position type
; Position format (for now):
; positions are one byte pixel position, one byte subpixel
; If I ever decide to have big rooms (doubtful),
; then one bit of subpixel may be added to the position instead
; Thus, speed is subpixels per frame
.STRUCT position_t
    x dw
    y dw
.ENDST

; Represents RNG state
.STRUCT rng_t
    low dw
    high dw
.ENDST

; A sprite object
.STRUCT object_t
    pos_x db
    pos_y db
    tileid db
    flags db ; vhoopppN
.ENDST

.DEFINE PLAYER_MAX_ITEM_COUNT 255
; Player object
.STRUCT playerextdata_t
    flags dw
    invuln_timer dw
    tear_timer dw
; stats
    stat_speed dw
    stat_accel dw
    stat_tear_delay dw
    stat_tear_speed dw
    stat_damage dw
; pickups
    money dw
    keys dw
    bombs dw
; health
    healthSlots INSTANCEOF byte_t HEALTHSLOT_COUNT
; items
    ; Total number of items that the player has
    playerItemCount db
    ; List of all items that the player has, in order of collected
    playerItemList ds PLAYER_MAX_ITEM_COUNT
    ; Number of each individual item that the player owns.
    ; Allows for stat upgrades to stack
    playerItemStackNumber ds 256
.ENDST

.STRUCT itemdef_t
    sprite_index db
    sprite_palette dw
    flags db
    on_pickup dl
    name ds 32
    tagline ds 32
.ENDST

; Tear array info
.DEFINE PROJECTILE_ARRAY_MAX_COUNT 64

; Represents a maptile position
.STRUCT maptilepos_t
    value db ; lower 4 bits for X, upper 4 bits for Y
.ENDST

; Serialized entity data
.STRUCT entitystore_t SIZE 8
    type db
    variant db
    posx dw
    posy dw
    state db
    timer db
.ENDST

; Actual generated room data, laid out in RAM
.STRUCT roominfo_t
    ; two extra tiles:
    ; tile[96] is a gap
    ; tile[97] is a solid block
    tileTypeTable INSTANCEOF byte_t ROOM_TILE_COUNT + 2
    tileVariantTable INSTANCEOF byte_t ROOM_TILE_COUNT + 2
    roomDefinition dw
    entityStoreTable INSTANCEOF entitystore_t ENTITY_STORE_COUNT
.ENDST

; Structure which defines object spawning rules
.STRUCT objectdef_t
    x db
    y db
    objectType dw
.ENDST

; Defines how a room should be generated
.STRUCT roomdefinition_t
    doorMask db
    roomSize db
    numObjects db
    tileData INSTANCEOF byte_t ROOM_TILE_COUNT
    ; objectDefinitions INSTANCEOF objectdef_t *
.ENDST

.STRUCT roompooldef_t
    numRooms db
    roomList ds 0
.ENDST

.STRUCT floordefinition_t
    numRooms db
    numRoomsRand db
    mapWidthLimit db
    mapHeightLimit db
.ENDST

.DEFINE VQUEUE_MODE_VRAM 0
.DEFINE VQUEUE_MODE_CGRAM 2
; Defines structure for VQueue operation
.STRUCT vqueueop_t SIZE 8
    vramAddr dw
    aAddr dl
    numBytes dw
    mode db
.ENDST

; VQueue mini operation
; Used directly with DMA transfer to VADDR and VDATA
.STRUCT vqueueminiop_t SIZE 4
    vramAddr dw
    data dw
.ENDST

; Entity Info

.STRUCT entityspriteinfo_t SIZE 4
    sprite_addr dw
    sprite_bank db
    nframes db
.ENDST

; Entity spawn groups: used to decide which entities to spawn
; Entities that should always be spawned every time the room is entered
.DEFINE ENTITY_SPAWNGROUP_ALWAYS $03
; Entities that should be spawned when entering non-completed rooms
.DEFINE ENTITY_SPAWNGROUP_ENEMY $02
; Entities that should only spawn the first time you enter a room
.DEFINE ENTITY_SPAWNGROUP_ONCE $01
; Don't spawn these; here for completion's sake
.DEFINE ENTITY_SPAWNGROUP_NEVER $00

; if set, then entity should be serialized when room is unloaded.
; in general, only set this for entities with ENTITY_SPAWNGROUP_ONCE
.DEFINE ENTITY_TYPE_FLAG_SERIALIZE $01

.STRUCT entitytypeinfo_t SIZE 8
    init_func dw
    tick_func dw
    free_func dw
    spawngroup db
    flags db
.ENDST

; Custom entity data
.STRUCT entitycustomdata_t
    for_entity dsw ENTITY_TOTAL_MAX
.ENDST

.STRUCT entitycharactercustomdata_t
    for_entity dsw ENTITY_CHARACTER_MAX
.ENDST

.STRUCT entitycharacterstatuseffectdata_t
    for_entity dsw ENTITY_CHARACTER_MAX
.ENDST

; .STRUCT entitycharacterdata_t
;     scratch ds 4
;     reserved ds 4
;     health dw
;     status_effects ds 4
;     velocx db
;     velocy db
;     ext ds 16
; .ENDST

; 2-byte structure for extra data contained in sprite table
.STRUCT spritetab_t
    spritemem db ; sprite memory index
    count db ; number of users
.ENDST

; ENTITY COLLISION DATA

; Represents 16x16 spatial partition
; Each layer allows one object to occupy a given slot
.STRUCT spatialpartitionlayer_t
    tiles ds 256
.ENDST
