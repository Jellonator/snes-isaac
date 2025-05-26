; PROJECTILE SUBTYPES
.ENUMID 0
.ENUMID PROJECTILE_TYPE_PLAYER_BASIC

.ENUMID $80
.ENUMID PROJECTILE_TYPE_ENEMY_BASIC

; PROJECTILE FLAGS
.DEFINE PROJECTILE_FLAG_POLYPHEMUS $0001
.DEFINE PROJECTILE_FLAG_HOMING     $0002

; ENTITY TABLE LIMIT DEFINITIONS

; Loaded entity limit
; Enemies and other objects which may consume multiple sprite slots
; Probably don't need this many slots, but it doesn't hurt to be safe
; I figure:
; 1 Player
; up to 16 enemies
; up to 16 pickups/objects
; up to 15 familiars
; up to 48 projectiles
; plus 24 extras
.DEFINE ENTITY_TOTAL_MAX 120
.DEFINE ENTITY_TOTAL_MAX_INDEX (2 * ENTITY_TOTAL_MAX)
; Character entities which may have health, status effects, custom sprites, etc.
.DEFINE ENTITY_CHARACTER_MAX 24
.DEFINE ENTITY_CHARACTER_MAX_INDEX (2 * ENTITY_CHARACTER_MAX)
; Specific entity indices
.DEFINE ENTITY_INDEX_PLAYER ENTITY_TOTAL_MAX_INDEX
.DEFINE ENTITY_FIRST_CUSTOM_INDEX (ENTITY_TOTAL_MAX_INDEX - 2)
; Extraneous array data - bytes per entity
.DEFINE ENTITY_DATA_ARRAY_SIZE 64

; Maximum number of serialized entities
.DEFINE ENTITY_STORE_COUNT 24

; Spawn contexts
; standard, used in most contexts.
.DEFINE ENTITY_CONTEXT_STANDARD 0
; used during 'init' when entity is created by loading room definition
.DEFINE ENTITY_CONTEXT_INIT_ROOMLOAD 1
; used during 'init' when entity is deserialized
.DEFINE ENTITY_CONTEXT_INIT_DESERIALIZE 2
; used during 'tick' or 'free' while room is transitioning. We perform one single
; tick during the transition so that we can update the sprite table.
; This indicates that we can not make changes to to BG1.
.DEFINE ENTITY_CONTEXT_TRANSITION 3
; used for spawning familiars, the standard way
.DEFINE ENTITY_CONTEXT_FAMILIAR 4

; ENTITY TYPES
.DEFINE ENTITY_TYPE_PLAYER 1
.DEFINE ENTITY_TYPE_PROJECTILE 2
.DEFINE ENTITY_TYPE_PICKUP 3
.DEFINE ENTITY_TYPE_TRAPDOOR 4
.DEFINE ENTITY_TYPE_BOMB 5
.DEFINE ENTITY_TYPE_EFFECT 6
.DEFINE ENTITY_TYPE_SHOPKEEPER 7
.DEFINE ENTITY_TYPE_TILE 8
.DEFINE ENTITY_TYPE_FAMILIAR 9
.DEFINE ENTITY_TYPE_ITEM_PEDASTAL 128
.DEFINE ENTITY_TYPE_ENEMY_ATTACK_FLY 129
.DEFINE ENTITY_TYPE_ENEMY_ZOMBIE 130
.DEFINE ENTITY_TYPE_ENEMY_BOSS_MONSTRO 131
.DEFINE ENTITY_TYPE_ENEMY_BOSS_DUKE_OF_FLIES 132
.DEFINE ENTITY_TYPE_ENEMY_CUBE 133

; ENTITY MASK
; Defines types that can collide with given mask

; Objects that can be damaged by player tears
.DEFINE ENTITY_MASK_TEAR $01
; Objects that can be damaged by enemy projectiles
.DEFINE ENTITY_MASK_PROJECTILE $02
; Objects that can be damaged by bombs
.DEFINE ENTITY_MASK_BOMBABLE $04
; Objects that can be damaged by tiles
.DEFINE ENTITY_MASK_BURNABLE $08

; Default mask for enemies
.DEFINE ENTITY_MASKSET_ENEMY (ENTITY_MASK_TEAR | ENTITY_MASK_BOMBABLE | ENTITY_MASK_BURNABLE)
; Default mask for the player
.DEFINE ENTITY_MASKSET_PLAYER (ENTITY_MASK_PROJECTILE | ENTITY_MASK_BOMBABLE | ENTITY_MASK_BURNABLE)

; ENTITY SIGNALS
; Used to tell an entity to respond to some form of interaction

; Signaled when an entity is killed (or otherwise needs to handle its own removal)
.DEFINE ENTITY_SIGNAL_KILL $01
; Signaled when an entity is damaged
.DEFINE ENTITY_SIGNAL_DAMAGE $02
; Signaled when entity is bombed
.DEFINE ENTITY_SIGNAL_BOMBED $04
; Signaled when player should take double damage
.DEFINE ENTITY_SIGNAL_DOUBLEDAMAGE $08

; ENTITY PICKUP VARIANTS
.ENUMID 1
.ENUMID ENTITY_PICKUP_VARIANT_PENNY
.ENUMID ENTITY_PICKUP_VARIANT_NICKEL
.ENUMID ENTITY_PICKUP_VARIANT_DIME
.ENUMID ENTITY_PICKUP_VARIANT_BOMB
.ENUMID ENTITY_PICKUP_VARIANT_KEY
.ENUMID ENTITY_PICKUP_VARIANT_BATTERY
.ENUMID ENTITY_PICKUP_VARIANT_HEART_FULL
.ENUMID ENTITY_PICKUP_VARIANT_HEART_SOUL
.ENUMID ENTITY_PICKUP_VARIANT_CONSUMABLE

.DEFINE ENTITY_PICKUP_RANDOM_SHOP $80
.DEFINE ENTITY_PICKUP_RANDOM_ANY $81
.DEFINE ENTITY_PICKUP_RANDOM_COIN $82
.DEFINE ENTITY_PICKUP_RANDOM_HEART $83

; ENTITY ITEM PEDASTAL POOL VARIANTS
.DEFINE ENTITY_ITEMPEDASTAL_POOL_ITEMROOM 0
.DEFINE ENTITY_ITEMPEDASTAL_POOL_BOSS 1
.DEFINE ENTITY_ITEMPEDASTAL_POOL_SHOP 2
.DEFINE ENTITY_ITEMPEDASTAL_POOL_DEVIL 3
.DEFINE ENTITY_ITEMPEDASTAL_POOLFLAG $3F
.DEFINE ENTITY_ITEMPEDASTAL_COSTFLAG $C0
.DEFINE ENTITY_ITEMPEDASTAL_PRICED $80
.DEFINE ENTITY_ITEMPEDASTAL_HEARTCOST $40

; ENTITY EFFECT VARIANTS
.DEFINE ENTITY_EFFECT_NULL 0
.DEFINE ENTITY_EFFECT_EXPLOSION 1

; TILE ENTITY VARIANTS
.DEFINE ENTITYTILE_VARIANT_FIRE_NORMAL 0

; ENTITY ZOMBIE VARIANTS
.DEFINE ENTITY_ZOMBIE_BASE 0
.DEFINE ENTITY_ZOMBIE_HEADLESS 1

; ENTITY FAMILIAR VARIANTS
.ENUMID 0
.ENUMID ENTITY_FAMILIAR_BROTHER_BOBBY
.ENUMID ENTITY_FAMILIAR_SISTER_MAGGY

; ENTITY SPRITE DEFINITION
.STRUCT entityspriteinfo_t SIZE 4
    sprite_addr dw
    sprite_bank db
    ntiles db
.ENDST

; ENTITY SPAWNGROUPS
; used to decide which entities to spawn

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

; Custom entity data
.STRUCT entitycustomdata_t
    for_entity dsw ENTITY_TOTAL_MAX
.ENDST

; Custom entity data, but only for character objects
.STRUCT entitycharactercustomdata_t
    for_entity dsw ENTITY_CHARACTER_MAX
.ENDST

; Status effect data, but only for character objects
.STRUCT entitycharacterstatuseffectdata_t
    for_entity dsw ENTITY_CHARACTER_MAX
.ENDST

; ENTITY COLLISION DATA

; Represents 16x16 spatial partition
; Each layer allows one object to occupy a given slot
.STRUCT spatialpartitionlayer_t
    tiles ds 256
.ENDST

; Number of objects that may be collided with per 16x16 square
.DEFINE SPATIAL_LAYER_COUNT 4

; Returns entity+variant value, for use with entity_create
.FUNCTION entityvariant(e, v) (e | (v * $0100))

; Other standard entity definitions
.DEFINE ENTITY_FLASH_TIME 4

; ENTITY FLAGS
; Indicates that entity should not be serialized
.DEFINE ENTITY_FLAGS_DONT_SERIALIZE $0001
; Indicates that this entity blocks other entities from entering this tile
.DEFINE ENTITY_FLAGS_BLOCKING $0002

; COLLISION

; Try to insert A into spatial partition at X
; ACCU should be 8b
.MACRO .InsertHitboxLite_X
    .REPT SPATIAL_LAYER_COUNT INDEX i
        ldy.w spatial_partition.{i+1},X
        bne +++++
        sta.w spatial_partition.{i+1},X
        jmp @@@@@\.\@
        +++++:
    .ENDR
    @@@@@\.\@:
.ENDM

; Try to insert A into spatial partition at Y
; ACCU should be 8b
.MACRO .InsertHitboxLite_Y
    .REPT SPATIAL_LAYER_COUNT INDEX i
        ldx.w spatial_partition.{i+1},Y
        bne +++++
        sta.w spatial_partition.{i+1},Y
        jmp @@@@@\.\@
        +++++:
    .ENDR
    @@@@@\.\@:
.ENDM

; Set entity box bounds with given width and height
.MACRO .EntityEasySetBox ARGS width, height
    sep #$20

    lda.w entity_box_x1,Y
    clc
    adc #width
    sta.w entity_box_x2,Y

    lda.w entity_box_y1,Y
    clc
    adc #height
    sta.w entity_box_y2,Y
.ENDM

; Check for collision of entity Y with player, based on box boundaries
; If colliding, jump to 'addr'
.MACRO .EntityEasyCheckPlayerCollision_Box ARGS addr
    sep #$20

    lda.w entity_box_x1,Y
    cmp.w player_box_x2
    bpl +++++

    lda.w entity_box_x2,Y
    cmp.w player_box_x1
    bmi +++++

    lda.w entity_box_y1,Y
    cmp.w player_box_y2
    bpl +++++

    lda.w entity_box_y2,Y
    cmp.w player_box_y1
    bmi +++++

    jmp addr
+++++:
.ENDM

; Check for collision of entity Y with player, based on box boundaries
; If NOT colliding, jump to 'addr'
.MACRO .EntityEasyCheckNoPlayerCollision_Box ARGS addr
    sep #$20

    lda.w entity_box_x1,Y
    cmp.w player_box_x2
    bpl addr

    lda.w entity_box_x2,Y
    cmp.w player_box_x1
    bmi addr

    lda.w entity_box_y1,Y
    cmp.w player_box_y2
    bpl addr

    lda.w entity_box_y2,Y
    cmp.w player_box_y1
    bmi addr
.ENDM

; Check for collision of entity Y with player, based on box boundaries,
; offset by provided boundaries
; If colliding, jump to 'addr'
.MACRO .EntityEasyCheckPlayerCollision_Rect ARGS addr, left, right, top, bottom
    sep #$20

    lda.w entity_box_x1,Y
    clc
    adc #left
    cmp.w player_box_x2
    bpl +++++

    lda.w entity_box_x2,Y
    clc
    adc #right
    cmp.w player_box_x1
    bmi +++++

    lda.w entity_box_y1,Y
    clc
    adc #top
    cmp.w player_box_y2
    bpl +++++

    lda.w entity_box_y2,Y
    clc
    adc #bottom
    cmp.w player_box_y1
    bmi +++++

    jmp addr
+++++:
.ENDM

; Check for collision of entity Y with player, based on box boundaries,
; offset by provided boundaries
; If not colliding, jump to 'addr'
.MACRO .EntityEasyCheckNoPlayerCollision_Rect ARGS addr, left, right, top, bottom
    sep #$20

    lda.w entity_box_x1,Y
    clc
    adc #left
    cmp.w player_box_x2
    bpl addr

    lda.w entity_box_x2,Y
    clc
    adc #right
    cmp.w player_box_x1
    bmi addr

    lda.w entity_box_y1,Y
    clc
    adc #top
    cmp.w player_box_y2
    bpl addr

    lda.w entity_box_y2,Y
    clc
    adc #bottom
    cmp.w player_box_y1
    bmi addr
.ENDM

; Check for collision of entity Y with player, based on box boundaries,
; offset by provided offset
; If colliding, jump to 'addr'
.MACRO .EntityEasyCheckPlayerCollision_Center ARGS addr, offx, offy
    sep #$20

    lda.w entity_box_x1,Y
    clc
    adc #offx
    cmp.w player_box_x2
    bpl +++++
    cmp.w player_box_x1
    bmi +++++

    lda.w entity_box_y1,Y
    clc
    adc #offy
    cmp.w player_box_y2
    bpl +++++
    cmp.w player_box_y1
    bmi +++++

    jmp addr
+++++:
.ENDM

; Check for collision of entity Y with player, based on box boundaries,
; offset by provided offset
; If not colliding, jump to 'addr'
.MACRO .EntityEasyCheckNoPlayerCollision_Center ARGS addr, offx, offy
    sep #$20

    lda.w entity_box_x1,Y
    clc
    adc #offx
    cmp.w player_box_x2
    bpl addr
    cmp.w player_box_x1
    bmi addr

    lda.w entity_box_y1,Y
    clc
    adc #offy
    cmp.w player_box_y2
    bpl addr
    cmp.w player_box_y1
    bmi addr
.ENDM