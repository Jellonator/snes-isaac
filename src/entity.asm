.include "base.inc"

; This bank is entirely relegated to entity functionality
.BANK $02 SLOT "ROM"
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

_e_null:
    rts

.DEFINE _fly_fgxptr.1 entity_char_custom.1
.DEFINE _fly_fgxptr.2 entity_char_custom.2

_e_basic_fly_init:
    .ACCU 16
    .INDEX 16
    ; default info
    tya
    sta.w entity_timer,Y
    lda #10
    sta.w entity_health,Y
    sep #$20
    lda #0
    ; sta.w entitycharacterdata_t.status_effects
    sta.w entity_signal,Y
    sta.w entity_mask,Y
    rep #$20
    ; load sprite
    lda #sprite.enemy.attack_fly.0
    phy
    jsl spriteman_new_sprite_ref
    rep #$30
    ply
    txa
    sta.w _fly_fgxptr.1,Y
    ; load frame 2
    lda #sprite.enemy.attack_fly.1
    phy
    jsl spriteman_new_sprite_ref
    rep #$30
    ply
    txa
    sta.w _fly_fgxptr.2,Y
    ; end
    rts

_e_basic_fly_tick:
    .ACCU 16
    .INDEX 16
; Remove col
    sep #$30 ; 8B AXY
    .EntityRemoveHitbox 2, 2
; check signal
    lda #ENTITY_SIGNAL_KILL
    and.w entity_signal,Y
    beq +
        ; We have perished
        jsl entity_free
        rts
    +:
; move
    ; TO PLAYER
    lda.w entity_posx+1,Y
    lsr
    sta.b $02
    lda.w player.pos.x+1
    lsr
    sec
    sbc.b $02
    bmi +
        adc #15
    +:
    and #$F0
    sta.b $02
    lda.w entity_posy+1,Y
    lsr
    sta.b $03
    lda.w player.pos.y+1
    lsr
    sec
    sbc.b $03
    bmi +
        adc #15
    +:
    lsr
    lsr
    lsr
    lsr
    ora.b $02
    tax
    rep #$20
    lda.l VecNormTableB_X,X
    and #$00FF
    cmp #$80
    php
    lsr
    lsr
    plp
    bcc +
        ora #$FFC0
    +:
    sta.b $06 ; $02: Norm X
    lda.l VecNormTableB_Y,X
    and #$00FF
    cmp #$80
    php
    lsr
    lsr
    plp
    bcc +
        ora #$FFC0
    +:
    sta.b $04 ; $04: Norm Y
    sep #$20
    ; RAND X
    stz.b $01
    ldx.w entity_timer,Y
    lda.l CosTableB,X
    php
    lsr
    lsr
    plp
    bpl +
        dec $01
        ora #$C0
    +:
    sta.b $00
    rep #$20
    lda.w entity_posx,Y
    ; Apply X
    clc
    adc.b $00
    clc
    adc.b $06
    sta.w entity_posx,Y
    sep #$30 ; 8B AXY
    xba
    clc
    adc #15
    sta.w entity_box_x2,Y
    ; RAND Y
    stz.b $01
    ldx.w entity_timer,Y
    lda.l SinTableB,X
    php
    lsr
    lsr
    plp
    bpl +
        dec $01
        ora #$C0
    +:
    sta.b $00
    rep #$20
    lda.w entity_posy,Y
    ; Apply Y
    clc
    adc.b $00
    clc
    adc.b $04
    sta.w entity_posy,Y
    sep #$30 ; 8B AXY
    xba
    clc
    adc #15
    sta.w entity_box_y2,Y
; load & set gfx
    rep #$20
    lda #0
    sep #$20
    ldx.w _fly_fgxptr.1,Y
    lda.w entity_timer,Y
    dec A
    sta.w entity_timer,Y
    and #$08
    beq +
        ldx.w _fly_fgxptr.2,Y
    +:
    lda.w loword(spriteTableValue + spritetab_t.spritemem),X
    phx
    tax
    lda.l SpriteSlotIndexTable,X
    plx
    ldx.w objectIndex
    sta.w objectData.1.tileid,X
    lda.w entity_posx + 1,Y
    sta.w objectData.1.pos_x,X
    lda.w entity_posy + 1,Y
    sta.w objectData.1.pos_y,X
    lda #%00101001
    sta.w objectData.1.flags,X
    ; add to partition
    .EntityAddHitbox 2, 2
    ; set some flags
    lda #ENTITY_MASK_TEAR
    sta.w entity_mask,Y
    lda #0
    sta.w entity_signal,Y
    ; inc object index
    rep #$30
    .SetCurrentObjectS
    .IncrementObjectIndex
    ; end
    rts

_e_basic_fly_free:
    .ACCU 16
    .INDEX 16
    lda #0
    sta.w entity_mask,Y
    lda.w _fly_fgxptr.1,Y
    tax
    phy
    php
    jsl spriteman_unref
    plp
    ply
    lda.w _fly_fgxptr.2,Y
    tax
    jsl spriteman_unref
    rts

; Create an entity of type A
; Returns reference as Y
entity_create:
    rep #$30 ; 16B XY
    sep #$20 ; 8B A
    ; first: find next free slot
    pha
    ldy #ENTITY_TOTAL_MAX_INDEX
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
    ldy.w #ENTITY_TOTAL_MAX_INDEX
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
    ldy.w #ENTITY_TOTAL_MAX_INDEX
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
    phd
    pea $4300
    pld
    .ClearWRam_ZP _base_entity_combined_type_variant, (rawMemorySizeShared-_base_entity_combined_type_variant)
    pld
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
    .ENDST
    .REPT (128 - 0 - 1) INDEX i
        .DSTRUCT @null_pad{i} INSTANCEOF entitytypeinfo_t VALUES
            init_func: .dw _e_null
            tick_func: .dw _e_null
            free_func: .dw _e_null
        .ENDST
    .ENDR
    ; 128 : Attack fly
    .DSTRUCT @attack_fly INSTANCEOF entitytypeinfo_t VALUES
        init_func: .dw _e_basic_fly_init
        tick_func: .dw _e_basic_fly_tick
        free_func: .dw _e_basic_fly_free
    .ENDST
.ENDS
