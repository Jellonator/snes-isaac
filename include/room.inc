; ROOM SIZING INFO
.DEFINE ROOM_TILE_WIDTH 12
.DEFINE ROOM_TILE_HEIGHT 8
.DEFINE ROOM_TILE_COUNT (ROOM_TILE_WIDTH*ROOM_TILE_HEIGHT)
.DEFINE MAX_ROOM_OBJECTS 32

; ROOM DEFINITION INFO
.DEFINE DOOR_DEF_UP $01
.DEFINE DOOR_DEF_LEFT $02
.DEFINE DOOR_DEF_RIGHT $04
.DEFINE DOOR_DEF_DOWN $08
.DEFINE DOOR_DEF_MASK $0F

; ROOM TYPES
.ENUMID 0
.ENUMID ROOMTYPE_EMPTY
.ENUMID ROOMTYPE_NORMAL
.ENUMID ROOMTYPE_ITEM
.ENUMID ROOMTYPE_BOSS
.ENUMID ROOMTYPE_SHOP
.ENUMID ROOMTYPE_SACRIFICE
.ENUMID ROOMTYPE_CURSE
.ENUMID ROOMTYPE_SECRET
.ENUMID ROOMTYPE_START
.ENUMID ROOMTYPE_DEVIL

; ROOM SIZES
.ENUMID 0
.ENUMID ROOM_SIZE_REGULAR

; ROOM POSITIONING AND SIZE DEFINES
.DEFINE ROOM_CENTER_Y (32 + 2*16 + 4*16)
.DEFINE ROOM_DOOR_RADIUS 6
.DEFINE ROOM_CENTER_X (8*16)
.DEFINE ROOM_LEFT (2*16)
.DEFINE ROOM_RIGHT (14*16)
.DEFINE ROOM_TOP (ROOM_CENTER_Y - 4*16)
.DEFINE ROOM_BOTTOM (ROOM_CENTER_Y + 4*16)

; SERIALIZED ENTITY DATA
.STRUCT entitystore_t SIZE 6
    type db
    variant db
    posx db
    posy db
    state db
    timer db
.ENDST

; IN-MEMORY ROOM INFO
; Actual generated room data, laid out in RAM
.STRUCT roominfo_t SIZE 352
    ; two extra tiles:
    ; tile[96] is a gap
    ; tile[97] is a solid block
    tileTypeTable INSTANCEOF byte_t ROOM_TILE_COUNT + 2
    tileVariantTable INSTANCEOF byte_t ROOM_TILE_COUNT + 2
    roomDefinition dw
    entityStoreTable INSTANCEOF entitystore_t ENTITY_STORE_COUNT
    rng INSTANCEOF rng_t
.ENDST

.MACRO .MultiplyIndexByRoomSizeA ARGS p_method, p_value
    .g_instruction lda, p_method, p_value
    asl
    asl
    asl
    clc
    .g_instruction adc, p_method, p_value
    .g_instruction adc, p_method, p_value
    .g_instruction adc, p_method, p_value
    asl
    asl
    asl
    asl
    asl
.ENDM

; ROOMGEN OBJECT DEFINITION
; Structure which defines object spawning rules
.STRUCT objectdef_t
    x db
    y db
    objectType dw
.ENDST

; ROOMGEN ROOM DEFINITION
; Defines how a room should be generated
.STRUCT roomdefinition_t
    doorMask db
    roomSize db
    numObjects db
    tileData INSTANCEOF byte_t ROOM_TILE_COUNT
    ; objectDefinitions INSTANCEOF objectdef_t *
.ENDST

; ROOMGEN POOL DEFINITION
; list of rooms to pick from
.STRUCT roompooldef_t
    numRooms db
    roomList ds 0
.ENDST

; zeropage buffers for calculating room info
; perhaps used for AI purposes? e.g. storing direction enemies should travel
.DEFINE ROOM_ZPBUF_ADDR (256-ROOM_TILE_COUNT) ; 160/$A0
.DEFINE ROOM_ZPBUFW_ADDR (256-ROOM_TILE_COUNT) ; 64/$40

; Branch to LABEL if XMEM,YMEM are out of bounds
; XMEM and YMEM are tile locations in range [0, 12) and [0, 8), respectively 
.MACRO .BranchIfTileXYOOB ARGS XMEM, YMEM, LABEL
    lda XMEM
    cmp #12
    bcs LABEL
    lda YMEM
    cmp #8
    bcs LABEL
.ENDM

.MACRO .PositionToTileIndex ARGS XACCESS, XADDR, YACCESS, YADDR, TMP
    .g_instruction lda, XACCESS, XADDR
    lsr
    lsr
    lsr
    lsr
    sta.b TMP
    .g_instruction lda, YACCESS, YADDR
    and #$FF00
    ora.b TMP
    tax
    lda.l GameTileToRoomTileIndexTable,X
.ENDM

.MACRO .TileXYToIndexA ARGS XMEM, YMEM, TEMPMEM
    lda YMEM
    asl
    asl
    sta TEMPMEM
    asl
    clc
    adc TEMPMEM
    adc XMEM
.ENDM

; devil deal flags

; Player has taken damage this floor
.DEFINE DEVILFLAG_PLAYER_TAKEN_DAMAGE $01
; Player has taken damage in the boss this floor
.DEFINE DEVILFLAG_PLAYER_TAKEN_DAMAGE_IN_BOSS $02
; Check for devil deal has already been performed (i.e., player has defeated boss)
.DEFINE DEVILFLAG_DEVIL_DEAL_CHECKED $04
; Player has bombed a shopkeeper this floor
.DEFINE DEVILFLAG_BOMBED_SHOPKEEPER $08
; Player has bombed a beggar this floor
.DEFINE DEVILFLAG_BOMBED_BEGGAR $10
