; Position format (for now):
; positions are one byte pixel position, one byte subpixel
; If I ever decide to have big rooms (doubtful),
; then one bit of subpixel may be added to the position instead
; Thus, speed is subpixels per frame

.STRUCT byte_t
    data db
.ENDST

.STRUCT word_t
    data dw
.ENDST

.STRUCT position_t
    x dw
    y dw
.ENDST

.STRUCT rng_t
    low dw
    high dw
.ENDST

.ENUMID 0
.ENUMID HEALTH_NULL
.ENUMID HEALTH_REDHEART_EMPTY
.ENUMID HEALTH_REDHEART_HALF
.ENUMID HEALTH_REDHEART_FULL
.ENUMID HEALTH_SOULHEART_FULL
.ENUMID HEALTH_SOULHEART_HALF
.ENUMID HEALTH_ETERNALHEART

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

.DEFINE TEAR_ARRAY_MAX_COUNT 32
.DEFINE TEAR_ARRAY_MAX_SIZE (TEAR_ARRAY_MAX_COUNT*_sizeof_tear_t)

.DEFINE ROOM_TILE_WIDTH 12
.DEFINE ROOM_TILE_HEIGHT 8
.DEFINE ROOM_TILE_COUNT (ROOM_TILE_WIDTH*ROOM_TILE_HEIGHT)
.DEFINE DOOR_UP $01
.DEFINE DOOR_LEFT $02
.DEFINE DOOR_RIGHT $04
.DEFINE DOOR_DOWN $08
.DEFINE MAX_ROOM_OBJECTS 32

.ENUMID 0
.ENUMID ROOM_SIZE_REGULAR

.ENUMID 0
.ENUMID ROOMTYPE_EMPTY
.ENUMID ROOMTYPE_NORMAL
.ENUMID ROOMTYPE_ITEM
.ENUMID ROOMTYPE_BOSS
.ENUMID ROOMTYPE_SHOP
.ENUMID ROOMTYPE_SACRIFICE
.ENUMID ROOMTYPE_CURSE
.ENUMID ROOMTYPE_SECRET
; maptile flags
.DEFINE MAPTILE_EXPLORED $01
.DEFINE MAPTILE_HAS_PLAYER $02
.DEFINE MAPTILE_COMPLETED $04
; used for generation step; marks tiles in the mapgenAvailableRooms table
.DEFINE MAPTILE_AVAILABLE $80

.ENUMID 0
.ENUMID OBJECT_TYPE_PENNY
.ENUMID OBJECT_TYPE_NICKEL
.ENUMID OBJECT_TYPE_DIME

.DEFINE MAP_MAX_WIDTH 16
.DEFINE MAP_MAX_HEIGHT 10
.DEFINE MAP_MAX_SIZE (MAP_MAX_WIDTH*MAP_MAX_HEIGHT)
.DEFINE MAX_MAP_SLOTS 160

; Represents a maptile position
.STRUCT maptilepos_t
    value db ; lower 4 bits for X, upper 4 bits for Y
.ENDST

; Structure which defines existing room layout
.STRUCT mapinfo_t
    tilex db
    tiley db
    doorMask db
    roomSize db
    tileData INSTANCEOF word_t ROOM_TILE_COUNT
.ENDST

; Structure which defines object spawning rules
.STRUCT objectdef_t
    x db
    y db
    objectType dw
.ENDST

; Structure which defines how a room may be laid out
.STRUCT mapdef_t
    doorMask db
    roomSize db
    tileData INSTANCEOF byte_t ROOM_TILE_COUNT
    numObjects db
    objectDefinitions INSTANCEOF objectdef_t MAX_ROOM_OBJECTS
.ENDST