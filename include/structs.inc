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

; Structure which defines existing room layout
.STRUCT roominfo_t
    tilePos INSTANCEOF maptilepos_t
    doorMask db
    roomSize db
    tileTypeTable INSTANCEOF byte_t ROOM_TILE_COUNT
    tileVariantTable INSTANCEOF byte_t ROOM_TILE_COUNT
.ENDST

; Structure which defines object spawning rules
.STRUCT objectdef_t
    x db
    y db
    objectType dw
.ENDST

; Structure which defines how a room may be laid out
.STRUCT roomdefinition_t
    doorMask db
    roomSize db
    numObjects db
    tileData INSTANCEOF byte_t ROOM_TILE_COUNT
    ; objectDefinitions INSTANCEOF objectdef_t *
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

.STRUCT vqueueminiop_t
    vramAddr dw
    data dw
.ENDST