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

; Player object
.STRUCT player_t
    pos instanceof position_t
    speed instanceof position_t
    tear_timer dw
    stat_speed dw
    stat_accel dw
    stat_tear_delay dw
    stat_tear_speed dw
    flags dw
    healthSlots INSTANCEOF byte_t 12
.ENDST

; ENSURE tear_t is some kind of power of 2, that way
; multiplication/division is easy
; currently, size is 16
.STRUCT tear_t
    speed instanceof position_t
    pos instanceof position_t
    lifetime dw ; frames before this tear is removed
    size db ; size; [0-3]
    type db
    damage dw
    flags dw
.ENDST

; Tear array info
.DEFINE TEAR_ARRAY_MAX_COUNT 32
.DEFINE TEAR_ARRAY_MAX_SIZE (TEAR_ARRAY_MAX_COUNT*_sizeof_tear_t)

; Represents a maptile position
.STRUCT maptilepos_t
    value db ; lower 4 bits for X, upper 4 bits for Y
.ENDST

; Serialized entity data
.STRUCT entitystore_t
    x db
    y db
    type db
    variant db
    ext dw
.ENDST

; Actual generated room data, laid out in RAM
.STRUCT roominfo_t
    tileTypeTable INSTANCEOF byte_t ROOM_TILE_COUNT
    tileVariantTable INSTANCEOF byte_t ROOM_TILE_COUNT
    ; entityStoreTable INSTANCEOF entitystore_t ENTITY_STORE_COUNT
    roomDefinition dw
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

; Defines structure for VQueue operation
; Laid out such that operations can be easily performed with MVP
.STRUCT vqueueop_t
    vramAddr dw
    param db
    bAddr db
    aAddr dl
    numBytes dw
.ENDST

; VQueue mini operation
; Used directly with DMA transfer to VADDR and VDATA
.STRUCT vqueueminiop_t
    vramAddr dw
    data dw
.ENDST

; Entity Info

.STRUCT entityspriteinfo_t
    sprite_addr dw
    sprite_bank db
    nframes db
.ENDST

.STRUCT entitytypeinfo_t
    init_func dw
    tick_func dw
    free_func dw
    padding dw
.ENDST

; Custom entity data
.STRUCT entitycustomdatatableentry_t
    for_entity dsw ENTITY_CHARACTER_MAX
.ENDST

.STRUCT entitystatuseffectdata_t
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
