; PROJECTILE SUBTYPES
.ENUMID 0
.ENUMID PROJECTILE_TYPE_PLAYER_BASIC

.ENUMID $80
.ENUMID PROJECTILE_TYPE_ENEMY_BASIC

; PROJECTILE FLAGS
.DEFINE PROJECTILE_FLAG_POLYPHEMUS $0001

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
.DEFINE ENTITY_SPAWN_CONTEXT_STANDARD 0    ; standard - e.g., entity is being created by another entity
.DEFINE ENTITY_SPAWN_CONTEXT_ROOMSPAWN 1   ; entity is spawned by room
.DEFINE ENTITY_SPAWN_CONTEXT_DESERIALIZE 2 ; entity is deserialized from stored data

; ENTITY TYPES
.DEFINE ENTITY_TYPE_PLAYER 1
.DEFINE ENTITY_TYPE_PROJECTILE 2
.DEFINE ENTITY_TYPE_PICKUP 3
.DEFINE ENTITY_TYPE_TRAPDOOR 4
.DEFINE ENTITY_TYPE_BOMB 5
.DEFINE ENTITY_TYPE_EFFECT 6
.DEFINE ENTITY_TYPE_ITEM_PEDASTAL 128
.DEFINE ENTITY_TYPE_ENEMY_ATTACK_FLY 129
.DEFINE ENTITY_TYPE_ENEMY_ZOMBIE 130
.DEFINE ENTITY_TYPE_ENEMY_BOSS_MONSTRO 131
.DEFINE ENTITY_TYPE_ENEMY_BOSS_DUKE_OF_FLIES 132

; ENTITY MASK
; Defines types that can collide with given mask

; Objects that can be damaged by player tears
.DEFINE ENTITY_MASK_TEAR $01
; Objects that can be damaged by enemy projectiles
.DEFINE ENTITY_MASK_PROJECTILE $02
; Objects that can be damaged by bombs
.DEFINE ENTITY_MASK_BOMBABLE $04

; Default mask for enemies
.DEFINE ENTITY_MASKSET_ENEMY (ENTITY_MASK_TEAR | ENTITY_MASK_BOMBABLE)
; Default mask for the player
.DEFINE ENTITY_MASKSET_PLAYER (ENTITY_MASK_PROJECTILE | ENTITY_MASK_BOMBABLE)

; ENTITY SIGNALS
; Used to tell an entity to respond to some form of interaction

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
.ENUMID ENTITY_PICKUP_VARIANT_HEART_FULL
.ENUMID ENTITY_PICKUP_VARIANT_HEART_SOUL

; ENTITY ITEM PEDASTAL POOL VARIANTS
.DEFINE ENTITY_ITEMPEDASTAL_POOL_ITEMROOM 0
.DEFINE ENTITY_ITEMPEDASTAL_POOL_BOSS 1

; ENTITY EFFECT VARIANTS
.DEFINE ENTITY_EFFECT_NULL 0
.DEFINE ENTITY_EFFECT_EXPLOSION 1

; ENTITY SPRITE DEFINITION
.STRUCT entityspriteinfo_t SIZE 4
    sprite_addr dw
    sprite_bank db
    nframes db
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

; COLLISION

; Try to insert A into spatial partition at X
; ACCU should be 8b
.MACRO .InsertHitboxLite
    .REPT SPATIAL_LAYER_COUNT INDEX i
        ldy.w spatial_partition.{i+1},X
        bne +++++
        sta.w spatial_partition.{i+1},X
        bra @@@@@\.\@
        +++++:
    .ENDR
    @@@@@\.\@:
.ENDM

; Try to remove A from spatial partition at X
; ACCU should be 8b
.MACRO .EraseHitboxLite
    .REPT SPATIAL_LAYER_COUNT INDEX i
        cmp.w spatial_partition.{i+1},X
        beq @@@@@\.\@{i}
    .ENDR
    bra @@@@@\.\@end
    .REPT SPATIAL_LAYER_COUNT INDEX i
        @@@@@\.\@{i}:
        .IF (i != (SPATIAL_LAYER_COUNT-1))
            lda.w spatial_partition.{i+2},X
            sta.w spatial_partition.{i+1},X
            ; beq @@@@@\.\@end
        .ELSE
            stz.w spatial_partition.{i+1},X
        .ENDIF
    .ENDR
    @@@@@\.\@end:
.ENDM

; Remove hitbox of entity Y from spatial partition at its position
; Inserts into grid of NUM_X×NUM_Y
.MACRO .EntityRemoveHitbox ARGS NUM_X, NUM_Y
    lda.w entity_posy+1,Y
    and #$F0
    sta.b $00
    lda.w entity_posx+1,Y
    lsr
    lsr
    lsr
    lsr
    ora.b $00
    sta.b $00
    .REPT NUM_Y INDEX iy
        tax
        .REPT NUM_X INDEX ix
            .IF ix > 0
                inx
            .ENDIF
            tya
            jsr EraseHitbox
        .ENDR
        .IF iy < (NUM_Y-1)
            lda.b $00
            clc
            adc #16
            sta.b $00
        .ENDIF
    .ENDR
.ENDM

; Insert hitbox of entity Y into spatial partition at its position
; Inserts into grid of NUM_X×NUM_Y
.MACRO .EntityAddHitbox ARGS NUM_X, NUM_Y
    sty.b $01
    lda.w entity_posy+1,Y
    and #$F0
    sta.b $00
    lda.w entity_posx+1,Y
    lsr
    lsr
    lsr
    lsr
    ora.b $00
    sta.b $00
    .REPT NUM_Y INDEX iy
        tax
        lda.b $01
        .REPT NUM_X INDEX ix
            .IF ix > 0
                inx
            .ENDIF
            jsr InsertHitbox
        .ENDR
        .IF iy < (NUM_Y-1)
            lda.b $00
            clc
            adc #16
            sta.b $00
        .ENDIF
    .ENDR
    ldy.b $01
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