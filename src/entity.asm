.include "base.inc"

; This bank is entirely relegated to entity functionality
.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity" FREE

; For each of the following:
; * execution bank will be $02
; * Data bank will be $7E
; * Y will be entity index (16B)
; * A,X,Y will be 16B

; Insert entity into spatial partition slot
; Inputs:
;   A: The entity ID
;   X: The spatial slot
; Clobbers: Y
InsertHitbox:
    .REPT SPATIAL_LAYER_COUNT INDEX i
        ldy.w spatial_partition.{i+1},X
        bne +
        sta.w spatial_partition.{i+1},X
        rts
        +:
    .ENDR
    rts

; Remove entity from spatial partition slot
; Inputs:
;   A: The entity ID
;   X: The spatial slot
; Clobbers: A
EraseHitbox:
    .EraseHitboxLite
    rts

_e_null:
    rts

; Create an entity of type A
; Returns reference as Y
entity_create:
    rep #$30 ; 16B XY
    sep #$20 ; 8B A
    ; first: find next free slot
    pha
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
    xba
    pla
    sta.w entity_type,Y
    rep #$20 ; 16B A
    .MultiplyStatic 8
    tax
    phy
    jsr (EntityDefinitions + entitytypeinfo_t.init_func,X)
    ply
    ; return
    rtl

; Free the given entity in reference Y
entity_free:
    rep #$30 ; 16B AXY
    phb
    .ChangeDataBank $7E
    lda.w entity_type,Y
    and.w #$00FF
    .MultiplyStatic 8
    tax
    phy
    jsr (EntityDefinitions + entitytypeinfo_t.free_func,X)
    ply
    ; set type to 0
    sep #$20
    lda #0
    sta.w entity_type,Y
    rep #$20
    ; return
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
    .MultiplyStatic 8
    tax
    phy
    jsr (EntityDefinitions + entitytypeinfo_t.free_func,X)
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
    rep #$30 ; 16B AXY
    phb
    .ChangeDataBank $7E
    ldy.w #ENTITY_FIRST_CUSTOM_INDEX
@loop:
    lda.w entity_type,Y
    and.w #$00FF
    beq @skip_ent ; skip if type == 0
    phy
    .MultiplyStatic 8
    tax
    php
    jsr (EntityDefinitions + entitytypeinfo_t.tick_func,X)
    plp
    ply
@skip_ent:
    dey
    dey
    bne @loop
@end:
    plb
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
    .ClearWRam_ZP _base_entity_combined_type_variant, (rawMemorySizeShared-_base_entity_combined_type_variant)
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
    rtl

SpatialPartitionClear:
    phd
    pea $4300
    pld
    .ClearWRam_ZP spatial_partition, _sizeof_spatial_partition
    pld
    rtl

EntityDefinitions:
    ; 0: Null
    .DSTRUCT @null INSTANCEOF entitytypeinfo_t VALUES
        init_func: .dw _e_null
        tick_func: .dw _e_null
        free_func: .dw _e_null
        spawngroup: .db ENTITY_SPAWNGROUP_NEVER
    .ENDST
    .DSTRUCT @player INSTANCEOF entitytypeinfo_t VALUES
        init_func: .dw _e_null
        tick_func: .dw _e_null
        free_func: .dw _e_null
        spawngroup: .db ENTITY_SPAWNGROUP_NEVER
    .ENDST
    .REPT (128 - 1 - 1) INDEX i
        .DSTRUCT @null_pad{i+1} INSTANCEOF entitytypeinfo_t VALUES
            init_func: .dw _e_null
            tick_func: .dw _e_null
            free_func: .dw _e_null
            spawngroup: .db ENTITY_SPAWNGROUP_NEVER
        .ENDST
    .ENDR
    ; 128 : Attack fly
    .DSTRUCT @enemy_attack_fly INSTANCEOF entitytypeinfo_t VALUES
        init_func: .dw entity_basic_fly_init
        tick_func: .dw entity_basic_fly_tick
        free_func: .dw entity_basic_fly_free
        spawngroup: .db ENTITY_SPAWNGROUP_ENEMY
    .ENDST
    ; 129 : zombie
    .DSTRUCT @enemy_zombie INSTANCEOF entitytypeinfo_t VALUES
        init_func: .dw entity_zombie_init
        tick_func: .dw entity_zombie_tick
        free_func: .dw entity_zombie_free
        spawngroup: .db ENTITY_SPAWNGROUP_ENEMY
    .ENDST

.ENDS
