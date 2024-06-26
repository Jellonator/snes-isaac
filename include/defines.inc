.DEFINE TRUE 1
.DEFINE FALSE 0

.ASCIITABLE
    MAP '0' TO '9' = $00
    MAP 'A' TO 'Z' = $0A
    MAP '.' = $24
    MAP ',' = $25
    MAP '!' = $26
    MAP '?' = $27
    MAP "'" = $28
    MAP '"' = $29
    MAP ':' = $2A
    MAP ' ' = $2B
.ENDA

; Joy buttons
.DEFINE JOY_A $0080 ; RIGHT
.DEFINE JOY_X $0040 ; UP
.DEFINE JOY_L $0020
.DEFINE JOY_R $0010
.DEFINE JOY_B $8000 ; DOWN
.DEFINE JOY_Y $4000 ; LEFT
.DEFINE JOY_SELECT $2000
.DEFINE JOY_START $1000
.DEFINE JOY_UP $0800
.DEFINE JOY_DOWN $0400
.DEFINE JOY_LEFT $0200
.DEFINE JOY_RIGHT $0100
.DEFINE JOY_ID $00FF
.DEFINE JOY_SHOOT_LEFT JOY_Y
.DEFINE JOY_SHOOT_RIGHT JOY_A
.DEFINE JOY_SHOOT_UP JOY_X
.DEFINE JOY_SHOOT_DOWN JOY_B

; Health slot IDs
.ENUMID 0
.ENUMID HEALTH_NULL
.ENUMID HEALTH_REDHEART_EMPTY
.ENUMID HEALTH_REDHEART_HALF
.ENUMID HEALTH_REDHEART_FULL
.ENUMID HEALTH_SOULHEART_FULL
.ENUMID HEALTH_SOULHEART_HALF
.ENUMID HEALTH_ETERNALHEART

.DEFINE HEALTHSLOT_COUNT 16

; Map room types
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

; Map sizes
.ENUMID 0
.ENUMID ROOM_SIZE_REGULAR

; Player flags
.DEFINE PLAYER_FLAG_EYE $0001
.DEFINE PLAYER_FLAG_INVALIDATE_ITEM_CACHE $0002

; base stats
.DEFINE PLAYER_STATBASE_ACCEL 24
.DEFINE PLAYER_STATBASE_SPEED (PLAYER_STATBASE_ACCEL * 16)
.DEFINE PLAYER_STATBASE_TEAR_RATE_INDEX 16
.DEFINE PLAYER_STATBASE_TEAR_RATE (($3C00 / 15) * 2.5)
.DEFINE PLAYER_STATBASE_TEAR_SPEED $0100 ; 1px/frame (60px/s)
.DEFINE PLAYER_STATBASE_DAMAGE 8
.DEFINE PLAYER_STATBASE_TEAR_LIFETIME 120

; Items
.DEFINE ITEMID_SAD_ONION 0
.DEFINE ITEMID_SPOON_BENDER 1
.DEFINE ITEMID_GROWTH_HORMONES 2
.DEFINE ITEMID_BROTHER_BOBBY 3
.DEFINE ITEMID_WIRE_COAT_HANGER 4
.DEFINE ITEMID_DINNER 5
.DEFINE ITEMID_CHOCOLATE_MILK 6
.DEFINE ITEMID_POLYPHEMUS 7

; Item Flags
.DEFINE ITEMFLAG_ACTIVE $01

; Projectile subtypes
.ENUMID 0
.ENUMID PROJECTILE_TYPE_PLAYER_BASIC

.ENUMID $80
.ENUMID PROJECTILE_TYPE_ENEMY_BASIC

; Projectile flags
.DEFINE PROJECTILE_FLAG_POLYPHEMUS $0001

; VRAM slots
; VRAM is 64KB of 16b words addressed $0000-$7FFF

; sprite OBJ page 0; granularity is (X % $2000) words
; Each 'page' is $1000 words
.DEFINE SPRITE1_BASE_ADDR $6000
; sprite OBJ page 1; should be offset by $1000-$4000 words from page 0
; granularity is (C % $1000) words
.DEFINE SPRITE2_BASE_ADDR $7000
; tile addresses; granularity is (X % $0400) words
.DEFINE BG1_TILE_BASE_ADDR $5800
.DEFINE BG2_TILE_BASE_ADDR $5C00
.DEFINE BG3_TILE_BASE_ADDR $0C00
; character addresses; granularity is (X % $1000) words
.DEFINE BG1_CHARACTER_BASE_ADDR $1000 ; UI
.DEFINE BG2_CHARACTER_BASE_ADDR $2000 ; Background
.DEFINE BG3_CHARACTER_BASE_ADDR $0000 ; Effects

.DEFINE BG2_TILE_ADDR_OFFS_X %0000000000010000
.DEFINE BG2_TILE_ADDR_OFFS_Y %0000001000000000

; Room blocks
.DEFINE BLOCK_HOLE        $00
.DEFINE BLOCK_REGULAR     $01
.DEFINE BLOCK_LOGS        $02
.DEFINE BLOCK_SPIKE       $03
.DEFINE BLOCK_ROCK        $80
.DEFINE BLOCK_ROCK_TINTED $81
.DEFINE BLOCK_POOP        $82
.DEFINE BLOCK_METAL       $83
.DEFINE BLOCK_IMPERVIOUS  $FF

.DEFINE BLOCKMASK_IS_SOLID $80

; Room info
.DEFINE ROOM_TILE_WIDTH 12
.DEFINE ROOM_TILE_HEIGHT 8
.DEFINE ROOM_TILE_COUNT (ROOM_TILE_WIDTH*ROOM_TILE_HEIGHT)
.DEFINE DOOR_DEF_UP $01
.DEFINE DOOR_DEF_LEFT $02
.DEFINE DOOR_DEF_RIGHT $04
.DEFINE DOOR_DEF_DOWN $08
.DEFINE DOOR_DEF_MASK $0F
.DEFINE MAX_ROOM_OBJECTS 32

; Door types
; Note: even = can't enter, odd = can enter
; this way, checking if a door can be entered is as easy as `BIT #1`
; Opening a door should be ORA 1, closing should be AND ~1
.DEFINE DOOR_MASK_IS_CLOSED $80
.DEFINE DOOR_MASK_OPEN_METHOD $70
.DEFINE DOOR_MASK_STATUS $F0
.DEFINE DOOR_MASK_TYPE $0F

.DEFINE DOOR_OPEN   $80
.DEFINE DOOR_CLOSED $00

.DEFINE DOOR_TYPE_NULL     $00
.DEFINE DOOR_TYPE_NORMAL   $01
.DEFINE DOOR_TYPE_TREASURE $02
.DEFINE DOOR_TYPE_SHOP     $03
.DEFINE DOOR_TYPE_BOSS     $04
.DEFINE DOOR_TYPE_ARCADE   $05
.DEFINE DOOR_TYPE_SECRET   $06
.DEFINE DOOR_TYPE_CURSE    $07

.DEFINE DOOR_METHOD_NEVER       $00 ; DEFAULT - door can never open
.DEFINE DOOR_METHOD_KEY         $10
.DEFINE DOOR_METHOD_BOMB        $20
.DEFINE DOOR_METHOD_COIN        $30
.DEFINE DOOR_METHOD_FINISH_ROOM $40

; zeropage buffers for calculating room info
; perhaps used for AI purposes? e.g. storing direction enemies should travel
.DEFINE ROOM_ZPBUF_ADDR (256-ROOM_TILE_COUNT) ; 160/$A0
.DEFINE ROOM_ZPBUFW_ADDR (256-ROOM_TILE_COUNT) ; 64/$40

; maptile flags
.DEFINE MAPTILE_EXPLORED $01
.DEFINE MAPTILE_HAS_PLAYER $02
.DEFINE MAPTILE_COMPLETED $04
; used for generation step; marks tiles in the mapgenAvailableRooms table
.DEFINE MAPTILE_AVAILABLE $80

; Map info
.DEFINE MAP_MAX_WIDTH 16
.DEFINE MAP_MAX_HEIGHT 10
.DEFINE MAP_MAX_SIZE (MAP_MAX_WIDTH*MAP_MAX_HEIGHT)
.DEFINE MAX_MAP_SLOTS 64
.DEFINE MAP_ZPBUF_ADDR (256-MAX_MAP_SLOTS) ; 96/$60

; VQueue info
.DEFINE VQUEUE_MAX_SIZE 128

; room position info
.DEFINE ROOM_CENTER_Y (32 + 2*16 + 4*16)
.DEFINE ROOM_DOOR_RADIUS 6
.DEFINE ROOM_CENTER_X (8*16)
.DEFINE ROOM_LEFT (2*16)
.DEFINE ROOM_RIGHT (14*16)
.DEFINE ROOM_TOP (ROOM_CENTER_Y - 4*16)
.DEFINE ROOM_BOTTOM (ROOM_CENTER_Y + 4*16)

; player position info
.DEFINE PLAYER_HITBOX_LEFT 4
.DEFINE PLAYER_HITBOX_RIGHT 12
.DEFINE PLAYER_HITBOX_TOP 5
.DEFINE PLAYER_HITBOX_BOTTOM 10

; tile collision info
; .DEFINE TILE_HITBOX_MARGIN 2

; sprite table info
.DEFINE SPRITE_TABLE_SIZE 64
.DEFINE SPRITE_TABLE_CELLAR_SIZE 16
.DEFINE SPRITE_TABLE_TOTAL_SIZE (SPRITE_TABLE_SIZE + SPRITE_TABLE_CELLAR_SIZE)

.ENUMID 64
.ENUMID SPRITE_LIST_EMPTY
.ENUMID SPRITE_QUEUE_SIZE

; Entity info
; Number of objects stored per room
.DEFINE ENTITY_STORE_COUNT 24
; Enemies and other objects which may consume multiple sprite slots
; Probably don't need this many slots, but it doesn't hurt to be safe
; I figure:
; 1 Player
; up to 16 enemies
; up to 16 pickups/objects
; up to 15 familiars
; up to 48 projectiles
; plus 31 extras
.DEFINE ENTITY_TOTAL_MAX 127
.DEFINE ENTITY_TOTAL_MAX_INDEX (2 * ENTITY_TOTAL_MAX)
; Character entities which may have health, status effects, custom sprites, etc.
.DEFINE ENTITY_CHARACTER_MAX 24
.DEFINE ENTITY_CHARACTER_MAX_INDEX (2 * ENTITY_CHARACTER_MAX)
; Specific entity indices
.DEFINE ENTITY_INDEX_PLAYER ENTITY_TOTAL_MAX_INDEX
.DEFINE ENTITY_FIRST_CUSTOM_INDEX (ENTITY_TOTAL_MAX_INDEX - 2)

.DEFINE ENTITY_SPAWN_CONTEXT_STANDARD 0
.DEFINE ENTITY_SPAWN_CONTEXT_ROOMSPAWN 1
.DEFINE ENTITY_SPAWN_CONTEXT_DESERIALIZE 2

; ENTITY TYPES
.DEFINE ENTITY_TYPE_PLAYER 1
.DEFINE ENTITY_TYPE_PROJECTILE 2
.DEFINE ENTITY_TYPE_PICKUP 3
.DEFINE ENTITY_TYPE_ITEM_PEDASTAL 128
.DEFINE ENTITY_TYPE_ENEMY_ATTACK_FLY 129
.DEFINE ENTITY_TYPE_ENEMY_ZOMBIE 130
.DEFINE ENTITY_TYPE_ENEMY_BOSS_MONSTRO 131
.DEFINE ENTITY_TYPE_ENEMY_BOSS_DUKE_OF_FLIES 132

.DEFINE SPATIAL_LAYER_COUNT 4

; Entity Mask: Defines types that can collide with given mask
; Objects that can be damaged by player tears
.DEFINE ENTITY_MASK_TEAR $01
; Objects that can be damaged by enemy projectiles
.DEFINE ENTITY_MASK_PROJECTILE $02
; Objects that can be damaged by bombs
.DEFINE ENTITY_MASK_BOMBABLE $04

; Entity Signals: Used to tell an entity to respond to some form of interaction
; Signaled when an entity is killed (or otherwise needs to handle its own removal)
.DEFINE ENTITY_SIGNAL_KILL $01

; ENTITY PICKUP VARIANTS
.ENUMID 1
.ENUMID ENTITY_PICKUP_VARIANT_PENNY
.ENUMID ENTITY_PICKUP_VARIANT_NICKEL
.ENUMID ENTITY_PICKUP_VARIANT_DIME
.ENUMID ENTITY_PICKUP_VARIANT_BOMB
.ENUMID ENTITY_PICKUP_VARIANT_KEY
.ENUMID ENTITY_PICKUP_VARIANT_BATTERY

; ENTITY ITEM PEDASTAL POOL VARIANTS
.DEFINE ENTITY_ITEMPEDASTAL_POOL_ITEMROOM 0
.DEFINE ENTITY_ITEMPEDASTAL_POOL_BOSS 1

; Pathfinding data

.DEFINE PATH_DIR_NULL 0
.DEFINE PATH_DIR_DOWN 1
.DEFINE PATH_DIR_RIGHT 2
.DEFINE PATH_DIR_LEFT 3
.DEFINE PATH_DIR_UP 4
.DEFINE PATH_DIR_NONE 5

.DEFINE PATH_DIR_DEF_COUNT 6

; ROM BANKS

.DEFINE ROMBANK_BASE $00
.DEFINE ROMBANK_MAIN $01
.DEFINE ROMBANK_ROOMDEFS $02
.DEFINE ROMBANK_ENTITYCODE $03
.DEFINE ROMBANK_GROUNDCODE $04

; GROUND DEFS

.DEFINE MAX_GROUND_OPS 512

.DEFINE GROUND_PALETTE_BROWN ($00 << 2)
.DEFINE GROUND_PALETTE_RED ($01 << 2)
.DEFINE GROUND_PALETTE_BLUE ($02 << 2)
.DEFINE GROUND_PALETTE_YELLOW ($03 << 2)

; FACING
.DEFINE FACINGDIR_RIGHT 0
.DEFINE FACINGDIR_DOWN 1
.DEFINE FACINGDIR_LEFT 2
.DEFINE FACINGDIR_UP 3
