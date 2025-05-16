.include "base.inc"

; This bank is entirely relegated to entity functionality
.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.ORG 0
.SECTION "Entity"

_e_null:
    rts

; For each of the following:
; * execution bank will be $02
; * Data bank will be $7E
; * Y will be entity index (16B)
; * A,X,Y will be 16B

; Create and initialize an entity of type+variant A
; lower byte is type, upper byte is variant
; Returns reference as Y
entity_create_and_init:
    rep #$10 ; 16B XY
    sep #$20 ; 8B A
    phb
    .ChangeDataBank $7E
    ; first: find next free slot
    pha
    xba
    pha
    xba
    ldy #ENTITY_FIRST_CUSTOM_INDEX
    ; for character entities, start from ENTITY_CHARACTER_MAX instead.
    cmp #0
    bpl +
        ldy #ENTITY_CHARACTER_MAX_INDEX
    +:
    lda.w entity_type,Y
    beq @end
@loop:
    dey
    dey
    lda.w entity_type,Y
    bne @loop
@end:
    ; init entity
    lda #0
    sta.w entity_mask,Y
    sta.w entity_signal,Y
    sta.w loword(entity_damageflash),Y
    sta.w loword(entity_flags),Y
    xba
    pla
    sta.w entity_variant,Y
    pla
    sta.w entity_type,Y
    rep #$20 ; 16B A
    .MultiplyStatic 2
    tax
    phy
    php
    jsr (EntityDef_InitFunc, X)
    plp
    ply
    ; insert into execution order
    lda.l numEntities
    tax
    tya
    sta.w entityExecutionOrder,X
    txa
    inc A
    sta.l numEntities
    ; return
    plb
    rtl

; Create an entity of type+variant A
; lower byte is type, upper byte is variant
; Returns reference as Y
; Make sure to call entity_init afterwards; use this function instead of
; entity_create_and_init if you want to set some variables (e.g. entity_state,
; entity_timer) before running its init function
entity_create:
    rep #$10 ; 16B XY
    sep #$20 ; 8B A
    phb
    .ChangeDataBank $7E
    ; first: find next free slot
    pha
    xba
    pha
    xba
    ldy #ENTITY_FIRST_CUSTOM_INDEX
    ; for character entities, start from ENTITY_CHARACTER_MAX instead.
    cmp #0
    bpl +
        ldy #ENTITY_CHARACTER_MAX_INDEX
    +:
    lda.w entity_type,Y
    beq @end
@loop:
    dey
    dey
    lda.w entity_type,Y
    bne @loop
@end:
    ; init entity
    lda #0
    sta.w entity_mask,Y
    sta.w entity_signal,Y
    sta.w loword(entity_damageflash),Y
    sta.w loword(entity_flags),Y
    xba
    pla
    sta.w entity_variant,Y
    pla
    sta.w entity_type,Y
    ; insert into execution order
    rep #$20 ; 16B A
    lda.l numEntities
    tax
    tya
    sta.w entityExecutionOrder,X
    txa
    inc A
    sta.l numEntities
    ; return
    plb
    rtl

; Initialize entity in Y
; call after entity_create
entity_init:
    rep #$30
    phb
    .ChangeDataBank $7E
    ; init entity
    rep #$20 ; 16B A
    lda.w entity_type,Y
    and #$00FF
    .MultiplyStatic 2
    tax
    phy
    php
    jsr (EntityDef_InitFunc, X)
    plp
    ply
    plb
    rtl

; Free the given entity in reference Y
entity_free:
    rep #$30 ; 16B AXY
    phb
    .ChangeDataBank $7E
    lda.w entity_type,Y
    and.w #$00FF
    .MultiplyStatic 2
    tax
    phy
    php
    jsr (EntityDef_FreeFunc,X)
    plp
    ply
    ; set type to 0
    sep #$20
    lda #0
    sta.w entity_type,Y
    ; rep #$20
    ; remove from execution order
    tya ; A = Y
    ldx #0
    cpx.w numEntities
    beq @endloop
    ; while (i < numEntities) {
    @loop:
        ; if (entity[i] == Y) {
        cmp.w entityExecutionOrder,X
        bne +
            ; --numEntities;
            dec.w numEntities
            ; entity[i] = entity[numEntities];
            ldy.w numEntities
            lda.w entityExecutionOrder,Y
            sta.w entityExecutionOrder,X
            ; assume that no other instances will occur and return
            plb
            rtl
        ; } else {
        +:
            ; i += 1;
            inx
            cpx.w numEntities
            bne @loop
        ; }
        ;   }
    ; }
    @endloop:
    ; return
    plb
    rtl

; Replace this entity slot with a different type.
; This is a bit more efficient than calling `entity_free` followed by
; `entity_create`, with the added benefit that stored values are kept (though
; they might be replaced by the init function).
; Do note that this will never change the entity ID. This means that non-character
; entities may NOT be replaced with character entities, lest you introduce
; hard-to-diagnose bugs.
entity_replace:
    rep #$30
    phb
    .ChangeDataBank $7E
    pha ; store type and variant for later
; call free function
    lda.w entity_type,Y
    and.w #$00FF
    .MultiplyStatic 2
    tax
    phy
    php
    jsr (EntityDef_FreeFunc,X)
    plp
    ply
; call init function
    sep #$20
    lda #0
    sta.w entity_mask,Y
    sta.w entity_signal,Y
    sta.w loword(entity_damageflash),Y
    sta.w loword(entity_flags),Y
    rep #$20 ; 16B A
    pla
    sta.w entity_type,Y
    and #$00FF
    .MultiplyStatic 2
    tax
    phy
    php
    jsr (EntityDef_InitFunc, X)
    plp
    ply
; return
    plb
    rtl

; Change the type and variant of this entity, without freeing or initializing
; this entity. ONLY USE THIS IF YOU KNOW WHAT YOU ARE DOING!!!
; This is mostly only useful for swapping out variants. Though, if you want to
; do that, you should just `sta.w entity_variant,Y` anyways.
entity_change_type:
    sep #$20
    phb
    .ChangeDataBank $7E
    sta.w entity_type,Y
    xba
    sta.w entity_variant,Y
    plb
    rtl

; Free all entities
entity_free_all:
    rep #$30 ; 16B AXY
    phb
    .ChangeDataBank $7E
    ldy.w #ENTITY_FIRST_CUSTOM_INDEX
@loop:
    lda.w entity_type,Y
    and.w #$00FF
    beq @skip_ent ; skip if type == 0
    .MultiplyStatic 2
    tax
    phy
    php
    jsr (EntityDef_FreeFunc,X)
    plp
    ply
    ; set type to 0
    sep #$20
    lda #0
    sta.w entity_type,Y
    rep #$20
@skip_ent:
    dey
    dey
    bne @loop
@end:
    plb
    jsl EntityInfoInitialize
    rtl

; Tick all entities
entity_tick_all:
    phb
    .ChangeDataBank $7E
    jsl SortEntityExecutionOrder
    rep #$30 ; 16B AXY
    ldx.w numEntities
    beq @end
    @loop:
        phx
        lda.w entityExecutionOrder-1,X
        and #$00FF
        tay
        lda.w entity_type,Y
        and #$00FF
        .MultiplyStatic 2
        tax
        php
        jsr (EntityDef_TickFunc,X)
        plp
        plx
        dex
        bne @loop
@end:
    plb
    rtl

; ENTITY DEFINITIONS

_player_tick:
    jsl PlayerRender
    rts

.MACRO ._DefineEntity ARGS index, initf, tickf, freef, spawngroup, flags
    .DEFINE _Array_EntityDef_InitFunc.{index} initf
    .DEFINE _Array_EntityDef_TickFunc.{index} tickf
    .DEFINE _Array_EntityDef_FreeFunc.{index} freef
    .DEFINE _Array_EntityDef_SpawnGroup.{index} spawngroup
    .IFDEFM \6
        .DEFINE _Array_EntityDef_Flags.{index} flags
    .ENDIF
.ENDM

._DefineEntity 0,\
    _e_null,\
    _e_null,\
    _e_null,\
    ENTITY_SPAWNGROUP_NEVER

._DefineEntity ENTITY_TYPE_PLAYER,\
    _e_null,\
    _player_tick,\
    _e_null,\
    ENTITY_SPAWNGROUP_NEVER

._DefineEntity ENTITY_TYPE_PROJECTILE,\
    projectile_entity_init,\
    projectile_entity_tick,\
    projectile_entity_free,\
    ENTITY_SPAWNGROUP_NEVER

._DefineEntity ENTITY_TYPE_PICKUP,\
    entity_pickup_init,\
    entity_pickup_tick,\
    entity_pickup_free,\
    ENTITY_SPAWNGROUP_ONCE,\
    ENTITY_TYPE_FLAG_SERIALIZE

._DefineEntity ENTITY_TYPE_ITEM_PEDASTAL,\
    item_pedastal_init,\
    item_pedastal_tick,\
    item_pedastal_free,\
    ENTITY_SPAWNGROUP_ONCE,\
    ENTITY_TYPE_FLAG_SERIALIZE

._DefineEntity ENTITY_TYPE_TRAPDOOR,\
    entity_trapdoor_init,\
    entity_trapdoor_tick,\
    entity_trapdoor_free,\
    ENTITY_SPAWNGROUP_ONCE,\
    ENTITY_TYPE_FLAG_SERIALIZE

._DefineEntity ENTITY_TYPE_BOMB,\
    entity_bomb_init,\
    entity_bomb_tick,\
    entity_bomb_free,\
    ENTITY_SPAWNGROUP_ONCE,\
    ENTITY_TYPE_FLAG_SERIALIZE

._DefineEntity ENTITY_TYPE_EFFECT,\
    entity_effect_init,\
    entity_effect_tick,\
    entity_effect_free,\
    ENTITY_SPAWNGROUP_ONCE

._DefineEntity ENTITY_TYPE_SHOPKEEPER,\
    entity_shopkeeper_init,\
    entity_shopkeeper_tick,\
    entity_shopkeeper_free,\
    ENTITY_SPAWNGROUP_ONCE,\
    ENTITY_TYPE_FLAG_SERIALIZE

._DefineEntity ENTITY_TYPE_TILE,\
    entity_tile_init,\
    entity_tile_tick,\
    entity_tile_free,\
    ENTITY_SPAWNGROUP_ONCE,\
    ENTITY_TYPE_FLAG_SERIALIZE

._DefineEntity ENTITY_TYPE_ENEMY_ATTACK_FLY,\
    entity_basic_fly_init,\
    entity_basic_fly_tick,\
    entity_basic_fly_free,\
    ENTITY_SPAWNGROUP_ENEMY

._DefineEntity ENTITY_TYPE_ENEMY_ZOMBIE,\
    entity_zombie_init,\
    entity_zombie_tick,\
    entity_zombie_free,\
    ENTITY_SPAWNGROUP_ENEMY

._DefineEntity ENTITY_TYPE_ENEMY_BOSS_MONSTRO,\
    entity_boss_duke_of_flies_init,\
    entity_boss_duke_of_flies_tick,\
    entity_boss_duke_of_flies_free,\
    ENTITY_SPAWNGROUP_ENEMY

._DefineEntity ENTITY_TYPE_ENEMY_BOSS_DUKE_OF_FLIES,\
    entity_boss_monstro_init,\
    entity_boss_monstro_tick,\
    entity_boss_monstro_free,\
    ENTITY_SPAWNGROUP_ENEMY

._DefineEntity ENTITY_TYPE_ENEMY_CUBE,\
    entity_enemy_cube_init,\
    entity_enemy_cube_tick,\
    entity_enemy_cube_free,\
    ENTITY_SPAWNGROUP_ENEMY

EntityDef_InitFunc:
.REPT 256 INDEX index
    .IFDEF _Array_EntityDef_InitFunc.{index}
        .DW _Array_EntityDef_InitFunc.{index}
    .ELSE
        .DW _e_null
    .ENDIF
.ENDR

EntityDef_TickFunc:
.REPT 256 INDEX index
    .IFDEF _Array_EntityDef_TickFunc.{index}
        .DW _Array_EntityDef_TickFunc.{index}
    .ELSE
        .DW _e_null
    .ENDIF
.ENDR

EntityDef_FreeFunc:
.REPT 256 INDEX index
    .IFDEF _Array_EntityDef_FreeFunc.{index}
        .DW _Array_EntityDef_FreeFunc.{index}
    .ELSE
        .DW _e_null
    .ENDIF
.ENDR

EntityDef_SpawnGroup:
.REPT 256 INDEX index
    .IFDEF _Array_EntityDef_SpawnGroup.{index}
        .DB _Array_EntityDef_SpawnGroup.{index}
    .ELSE
        .DB 0
    .ENDIF
.ENDR

EntityDef_Flags:
.REPT 256 INDEX index
    .IFDEF _Array_EntityDef_Flags.{index}
        .DB _Array_EntityDef_Flags.{index}
    .ELSE
        .DB 0
    .ENDIF
.ENDR

.ENDS

; Extra code/data that doesn't necessarily need to be in main entity bank
.BANK $04 SLOT "ROM"
.ORG 0
.SECTION "EntityExtCode"

SortEntityExecutionOrder:
    sep #$30
    lda.w numEntities
    cmp #2
    bcc @noSort
; sorting logic
    ldy #1
    ; do {
@outerloop:
    ; e = entity[i]
    lda.w entityExecutionOrder,Y
    ; sta.b $01
    ; v = entity_y2[e]
    tax
    ; xba
    lda.w loword(entity_ysort),X
    sta.b $02
    ; j = i - 1;
    sty.b $00
    dec.b $00
    ; while (j >= 0 && && entity_y2[entity[j]] >= v) {
    @innerloop:
        ldx.b $00
        cpx #$FF
        beq @endinnerloop
        ; X = entity[j]
        lda.w entityExecutionOrder,X
        tax
        ; A = entity_y2[X]
        lda.w loword(entity_ysort),X
        cmp.b $02
        bcc @endinnerloop
        beq @endinnerloop
        ; swap entity[j+1], entity[j];
        ; txa
        ldx.b $00
        lda.w entityExecutionOrder+0,X
        xba
        lda.w entityExecutionOrder+1,X
        sta.w entityExecutionOrder+0,X
        xba
        sta.w entityExecutionOrder+1,X
        ; j -= 1;
        dec.b $00
        bra @innerloop
    ; }
    @endinnerloop:
    ; entity[j+1] = entity[i];
    ; lda.b $01
    ; ldx.b $00
    ; sta.w entityExecutionOrder+1,X
    ; i += 1;
    iny
    ; } while (i < COUNT);
    cpy.w numEntities
    bcc @outerloop
; end
@noSort:
    rtl

EntityInfoInitialize:
    rep #$20
    ; save player info
    lda.w player_posx
    pha
    lda.w player_posy
    pha
    ; clear
    sep #$20
    phd
    pea $4300
    pld
    .ClearWRam_ZP entity_data_begin, (entity_data_end-entity_data_begin)
    pld
    ; set player type
    sep #$20
    lda #ENTITY_TYPE_PLAYER
    sta.w player_type
    ; load player info
    rep #$20
    pla
    sta.w player_posy
    pla
    sta.w player_posx
    ; reset entity execution order
    lda #1
    sta.l numEntities
    lda #ENTITY_INDEX_PLAYER
    sta.w entityExecutionOrder
    ; clear entity spawn context
    lda #ENTITY_SPAWN_CONTEXT_STANDARD
    sta.b entitySpawnContext
    rtl

SpatialPartitionClear:
    phd
    pea $4300
    pld
    .ClearWRam_ZP spatial_partition, _sizeof_spatial_partition
    pld
    rtl

; COMMON ENTITY FUNCTIONS

Entity.Enemy.TickContactDamage:
    sep #$20
    lda.w player_box_x1
    clc
    adc #8 ; ACC = player center x
    cmp.w entity_box_x1,Y
    bmi @no_player_col
    cmp.w entity_box_x2,Y
    bpl @no_player_col
    lda.w player_box_y1
    clc
    adc #8
    cmp.w entity_box_y1,Y
    bmi @no_player_col
    cmp.w entity_box_y2,Y
    bpl @no_player_col
    rep #$20
    dec.w player_damageflag
@no_player_col:
    rtl

; Set target direction based on pathfinding table.
; This will generally allow this entity to pathfind towards the player.
Entity.Enemy.PathfindTargetPlayer:
; first: check pathfind data
    sep #$30
    lda.w entity_box_x1,Y
    clc
    adc.w entity_box_x2,Y
    ror
    .DivideStatic 16
    sta.b $00
    lda.w loword(entity_ysort),Y
    and #$F0
    ora.b $00
    tax
    lda.w pathfind_player_data,X
    cmp #PATH_DIR_NONE
    bne @follow_path
    ; 'PATH_DIR_NONE' indicates that player is on same tile, so move toward player directly
        jmp Entity.Enemy.DirectTargetPlayer
@follow_path:
    tax
    sta.b entityTargetFound
    lda.l Path_Angle,X
    sta.b entityTargetAngle
    rtl

; Set target direction to face directly towards the player.
; Credit for method of calculating the angle:
; https://codebase64.org/doku.php?id=base:8bit_atan2_8-bit_angle
; A couple of modifications were made for accuracy
Entity.Enemy.DirectTargetPlayer:
; get dx
    sep #$30
    stz.b $00
    lda.w entity_box_x1,Y
    clc
    adc.w entity_box_x2,Y
    ror
    sbc #8
    sbc.w player_box_x1
    bcs +
        eor #$FF
    +:
    tax
    rol.b $00
; get dy
    lda.w loword(entity_ysort),Y
    sbc.w loword(entity_ysort) + ENTITY_INDEX_PLAYER
    bcs +
        eor #$FF
    +:
    sta.b $01
    rol.b $00
; calculate log(dx) - log(dy)
    lda.l Log2Mult32Table8,X
    ldx.b $01
    sbc.l Log2Mult32Table8,X
    bcc +
        eor #$FF
    +:
    tax
    rol.b $00
; calculate atan
    lda.l AtanLogTable8,X
    ldx.b $00
    eor.l AtanOctantAdjustTable8,X
    sta.b entityTargetAngle
    lda #1
    sta.b entityTargetFound
    rtl

; Move this entity according to its velocity, and collide with blocks.
; This function operates in two phases: horizontal movement, followed by vertical movement.
; $00 - width
; $01 - height
.DEFINE WIDTH $00
.DEFINE HEIGHT $01
.DEFINE ENTITYID (tempDP)
.DEFINE TILES_X (tempDP+$02)
.DEFINE TILES_Y (tempDP+$04)
Entity.MoveAndCollide:
    sep #$30
    sty.b ENTITYID
; get number of tiles (height_tiles) to check when moving in X direction
    lda.w entity_box_y1,Y
    and #$0F
    clc
    adc.b HEIGHT
    dec A
    .DivideStatic 16
    sta.b TILES_Y
; begin check properly
    rep #$20
    lda.w entity_velocx,Y
    beq @end_horizontal_movement
    bmi @left_movement
;right_movement:
    .ACCU 16
    ; add x movement
    clc
    adc.w entity_posx,Y
    sta.w entity_posx,Y
    ; get right tile index
    sep #$20
    xba
    clc
    adc.b WIDTH
    .DivideStatic 16
    ldx.w entity_box_y1,Y
    ora.l NibbleTop8,X
    tax
    lda.l GameTileToRoomTileIndexTable,X
    tay
    ; test if any right-bordering tiles are 
    clc ; none of the loop instructions, except 'adc', should change this
    @loop_right:
        lda [currentRoomTileTypeTableAddress],Y
        bmi @found_tile_right
        beq @found_tile_right
        dec.b TILES_Y
        bmi @end_horizontal_movement
        tya
        adc #12
        tay
        bra @loop_right
    @found_tile_right:
        ldy.b ENTITYID
        lda.l NibbleFlip8,X
        and #$F0
        sec
        sbc.b WIDTH
        sta.w entity_box_x1,Y
        bra @end_horizontal_movement
@left_movement:
    .ACCU 16
    ; add x movement
    clc
    adc.w entity_posx,Y
    sta.w entity_posx,Y
    ; get left tile index
    sep #$20
    xba
    .DivideStatic 16
    ldx.w entity_box_y1,Y
    ora.l NibbleTop8,X
    tax
    lda.l GameTileToRoomTileIndexTable,X
    tay
    ; test if any right-bordering tiles are 
    clc ; none of the loop instructions, except 'adc', should change this
    @loop_left:
        lda [currentRoomTileTypeTableAddress],Y
        bmi @found_tile_left
        beq @found_tile_left
        dec.b TILES_Y
        bmi @end_horizontal_movement
        tya
        adc #12
        tay
        bra @loop_left
    @found_tile_left:
        ldy.b ENTITYID
        lda.l NibbleFlip8,X
        and #$F0
        adc #16
        sta.w entity_box_x1,Y
        ; bra @end_horizontal_movement
@end_horizontal_movement:
    ldy.b ENTITYID
; get number of tiles (width_tiles) to check when moving in Y direction
    sep #$30
    lda.w entity_box_x1,Y
    and #$0F
    clc
    adc.b WIDTH
    dec A
    .DivideStatic 16
    sta.b TILES_X
; now, perform vertical movement
    rep #$20
    lda.w entity_velocy,Y
    beq @end_vertical_movement
    bmi @up_movement
;down_movement:
    .ACCU 16
    ; add x movement
    clc
    adc.w entity_posy,Y
    sta.w entity_posy,Y
    ; get bottom tile index
    sep #$20
    xba
    clc
    adc.b HEIGHT
    and #$F0
    ldx.w entity_box_x1,Y
    ora.l Div16,X
    tax
    lda.l GameTileToRoomTileIndexTable,X
    tay
    ; test if any right-bordering tiles are 
    clc ; none of the loop instructions, except 'adc', should change this
    @loop_down:
        lda [currentRoomTileTypeTableAddress],Y
        bmi @found_tile_down
        beq @found_tile_down
        dec.b TILES_X
        bmi @end_vertical_movement
        iny
        bra @loop_down
    @found_tile_down:
        ldy.b ENTITYID
        txa
        and #$F0
        sec
        sbc.b HEIGHT
        sta.w entity_box_y1,Y
        bra @end_vertical_movement
@up_movement:
    .ACCU 16
    ; add x movement
    clc
    adc.w entity_posy,Y
    sta.w entity_posy,Y
    ; get top tile index
    sep #$20
    xba
    and #$F0
    ldx.w entity_box_x1,Y
    ora.l Div16,X
    tax
    lda.l GameTileToRoomTileIndexTable,X
    tay
    ; test if any right-bordering tiles are 
    clc ; none of the loop instructions, except 'adc', should change this
    @loop_up:
        lda [currentRoomTileTypeTableAddress],Y
        bmi @found_tile_up
        beq @found_tile_up
        dec.b TILES_X
        bmi @end_vertical_movement
        iny
        bra @loop_up
    @found_tile_up:
        ldy.b ENTITYID
        txa
        and #$F0
        adc #16
        sta.w entity_box_y1,Y
        ; bra @end_vertical_movement
@end_vertical_movement:
    ldy.b ENTITYID
    rtl
.UNDEFINE WIDTH
.UNDEFINE HEIGHT
.UNDEFINE ENTITYID
.UNDEFINE TILES_X
.UNDEFINE TILES_Y

; $00 - width
; $01 - height
Entity.KeepInBounds:
    sep #$30
    lda.w entity_posx,Y
    cmp #ROOM_LEFT
    bcs @skip_left
        lda #ROOM_LEFT
        sta.w entity_posx,Y
        jmp @skip_right
    @skip_left:
    clc
    adc.b $00
    cmp #ROOM_RIGHT
    bcc @skip_right
        lda #ROOM_RIGHT
        sec
        sbc.b $00
        sta.w entity_posx,Y
    @skip_right:
    lda.w entity_posy,Y
    cmp #ROOM_TOP
    bcs @skip_top
        lda #ROOM_TOP
        sta.w entity_posy,Y
        jmp @skip_bottom
    @skip_top:
    clc
    adc.b $01
    cmp #ROOM_BOTTOM
    bcc @skip_bottom
        lda #ROOM_BOTTOM
        sec
        sbc.b $01
        sta.w entity_posy,Y
    @skip_bottom:
    rtl

; Get the collision at the given position, if available
; $00: Mask
; $01: X
; $02: Y
; Return: Y as entity ID
GetEntityCollisionAt:
    .INDEX 8
    .ACCU 8
    lda.b $02
    and #$F0
    sta.b $03
    lda.b $01
    lsr
    lsr
    lsr
    lsr
    ora.b $03
    tax
    .REPT SPATIAL_LAYER_COUNT INDEX i
        ; get tile at X
        ldy.w spatial_partition.{i+1},X
        bne +
            ; no more tiles; exit early
            ldy #0
            rtl
        +:
        ; check mask
        lda.w entity_mask,Y
        and.b $00
        beq + ; skip if not match
            ; check position
            lda.b $01
            cmp.w entity_box_x1,Y
            bcc +
            cmp.w entity_box_x2,Y
            bcs +
            lda.b $02
            cmp.w entity_box_y1,Y
            bcc +
            cmp.w entity_box_y2,Y
            bcs +
            rtl
        +:
    .ENDR
    ldy #0
    rtl

; place entity shadow for entity at index Y
; assumes 16 bit index, 8 bit accumulator
; Parameters:
;   offs x [db] $05
;   offs y [db] $04
EntityPutShadow:
    .INDEX 16
    .ACCU 8
    ldx.w objectIndexShadow
    cpx.w objectIndex
    bcc @skipShadow
    @inner:
        dex
        dex
        dex
        dex
        stx.w objectIndexShadow
        lda.w entity_posy+1,Y
        clc
        adc $04,S
        sta.w objectData.1.pos_y,X
        lda.w entity_posx+1,Y
        clc
        adc $05,S
        sta.w objectData.1.pos_x,X
        lda #$A0
        sta.w objectData.1.tileid,X
        lda #%00011000
        sta.w objectData.1.flags,X
    @skipShadow:
    rtl

; place medium-sized entity shadow for entity at index Y
; assumes 16 bit index, 8 bit accumulator
; Parameters:
;   offs x [db] $05
;   offs y [db] $04
EntityPutMediumShadow:
    rep #$30
    lda.w objectIndexShadow
    sec
    sbc #8
    cmp.w objectIndex
    bcc @skipShadow
        sep #$20
        tax
        stx.w objectIndexShadow
        lda.w entity_posy+1,Y
        clc
        adc $04,S
        sta.w objectData.1.pos_y,X
        sta.w objectData.2.pos_y,X
        lda.w entity_posx+1,Y
        clc
        adc $05,S
        clc
        sta.w objectData.1.pos_x,X
        adc #16
        sta.w objectData.2.pos_x,X
        lda #$A2
        sta.w objectData.1.tileid,X
        sta.w objectData.2.tileid,X
        lda #%00011000
        sta.w objectData.1.flags,X
        lda #%01011000
        sta.w objectData.2.flags,X
        ; now, need to make sprites big
        rep #$20
        ; phy
        txa
        ;
        lsr
        lsr
        tax
        and #$03
        sta.b $00 ; $00 = subindex
        ;
        txa
        lsr
        lsr
        tax ; X = INDEX
        ;
        lda #%1010
        .REPT 4
            dec.b $00
            bmi +
            asl
            asl
        .ENDR
        +:
        ; ...
        ora.w objectDataExt,X
        ; A |= 0b010101 << $00
        sta.w objectDataExt,X
        ; end
        ; ply
        rtl
    @skipShadow:
    rtl

; place big entity shadow for entity at index Y
; assumes 16 bit index, 8 bit accumulator
; Parameters:
;   offs x [db] $05
;   offs y [db] $04
EntityPutBigShadow:
    rep #$30
    lda.w objectIndexShadow
    sec
    sbc #12
    cmp.w objectIndex
    bcc @skipShadow
        sep #$20
        tax
        stx.w objectIndexShadow
        lda.w entity_posy+1,Y
        clc
        adc $04,S
        .REPT 3 INDEX i
            sta.w objectData.{i+1}.pos_y,X
        .ENDR
        lda.w entity_posx+1,Y
        clc
        adc $05,S
        clc
        .REPT 3 INDEX i
            .IF i > 0
                adc #16
            .ENDIF
            sta.w objectData.{i+1}.pos_x,X
        .ENDR
        lda #$A2
        sta.w objectData.1.tileid,X
        sta.w objectData.3.tileid,X
        inc A
        inc A
        sta.w objectData.2.tileid,X
        lda #%00011000
        sta.w objectData.1.flags,X
        sta.w objectData.2.flags,X
        lda #%01011000
        sta.w objectData.3.flags,X
        ; now, need to make sprites big
        rep #$20
        ; phy
        txa
        ;
        lsr
        lsr
        tax
        and #$03
        sta.b $00 ; $00 = subindex
        ;
        txa
        lsr
        lsr
        tax ; X = INDEX
        ;
        lda #%101010
        .REPT 4
            dec.b $00
            bmi +
            asl
            asl
        .ENDR
        +:
        ; ...
        ora.w objectDataExt,X
        ; A |= 0b010101 << $00
        sta.w objectDataExt,X
        ; end
        ; ply
        rtl
    @skipShadow:
    rtl

EntityPutSplatter:
    rep #$10
    sep #$20
    lda.w loword(entity_ysort),Y
    sta.b $06
    lda #GROUND_PALETTE_RED
    sta.b $04
    .REPT 8 INDEX i
        sep #$20
        lda.w entity_box_x1,Y
        .IF i == 0 || i == 7
            clc
            adc #6 + ((i # 3) - 1)
            sta $07
            lda #4
            sta $05
        .ELIF i == 1 || i == 6
            clc
            adc #3 + ((i # 3) - 1)
            sta $07
            lda #10
            sta $05
        .ELIF i == 2 || i == 5
            clc
            adc #1 + ((i # 3) - 1)
            sta $07
            lda #14
            sta $05
        .ELIF i == 3 || i == 4
            clc
            adc #0 + ((i # 3) - 1)
            sta $07
            lda #16
            sta $05
        .ENDIF
        phy
        jsl GroundAddOp
        ply
        inc.b $06
    .ENDR
    rep #$30
    rtl

entity_clear_hitboxes:
    phd
    pea $4300
    pld
    .ClearWRam_ZP spatial_partition, 256*SPATIAL_LAYER_COUNT
    pld
    rtl

entity_refresh_hitboxes:
    ; clear data
    .DEFINE ENTITY_INDEX $00
    .DEFINE ENTITY_ID $0C
    .DEFINE WIDTH $02
    .DEFINE HEIGHT $04
    .DEFINE INDEX $06
    .DEFINE WIDTH_STORE $08
    .DEFINE INC_Y $0A
    .DEFINE TMP $0E
    ; put hitboxes
    sep #$30
    lda.l numEntities
    sta.b ENTITY_INDEX
    beql @end
    @loop:
        ldx.b ENTITY_INDEX
        ldy.w entityExecutionOrder-1,X
        lda.w entity_mask,Y
        beql @skip_entity
        sty.b ENTITY_ID
        ; WIDTH
        ldx.w entity_box_x1,Y
        lda.l Div16,X
        sta.b TMP
        ldx.w entity_box_x2,Y
        dex
        lda.l Div16,X
        sec
        sbc.b TMP
        inc A
        sta.b WIDTH_STORE
        ; INC_Y
        lda #16
        sbc.b WIDTH_STORE ; we assume carry flag is still set
        sta.b INC_Y
        ; HEIGHT
        ldx.w entity_box_y1,Y
        lda.l Div16,X
        sta.b TMP
        ldx.w entity_box_y2,Y
        dex
        lda.l Div16,X
        sec
        sbc.b TMP
        inc A
        sta.b HEIGHT
        ; INDEX
        ldx.w entity_box_x1,Y
        lda.l Div16,X
        sta.b INDEX
        lda.w entity_box_y1,Y
        and #$F0
        ora.b INDEX
        tax
        ; PUT
        @loop_y:
            lda.b WIDTH_STORE
            sta.b WIDTH
            @loop_x:
                lda.b ENTITY_ID
                .InsertHitboxLite_X
                inx
                dec.b WIDTH
                bne @loop_x
            txa
            clc
            adc.b INC_Y
            tax
            dec.b HEIGHT
            bne @loop_y
    @skip_entity:
        dec.b ENTITY_INDEX
        bnel @loop
@end:
    rtl
    .UNDEFINE ENTITY_INDEX
    .UNDEFINE ENTITY_ID
    .UNDEFINE WIDTH
    .UNDEFINE HEIGHT
    .UNDEFINE INDEX
    .UNDEFINE WIDTH_STORE
    .UNDEFINE INC_Y
    .UNDEFINE TMP

.ENDS
