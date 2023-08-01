.include "base.inc"

; This bank is entirely relegated to entity functionality
.BANK $02 SLOT "ROM"
.SECTION "Entity" FREE

; For each of the following:
; * execution bank will be $02
; * Data bank will be $7E
; * Y will be entity index (16B)
; * A,X,Y will be 16B

; Input: Y as current entity index
; Output: X as index into entity_data
; Clobbers: A
.MACRO .EntityIndexYToExtX
    tya
    .MultiplyStatic 32
    tax
.ENDM

; Input: Y as current entity index
; Output: DP as pointer into entity_data
; Clobbers: A
.MACRO .EntityIndexYToDP
    tya
    .MultiplyStatic 32
    clc
    adc #entity_data
    phd
    tcd
.ENDM

; Undoes .EntityIndexYToDP
.MACRO .END_EntityIndexYToDP
    pld
.ENDM

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
    lda.w entity_posy,Y
    and #$F0
    sta.b $00
    lda.w entity_posx,Y
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
    lda.w entity_posy,Y
    and #$F0
    sta.b $00
    lda.w entity_posx,Y
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

.DEFINE _fly_xl (entitycharacterdata_t.ext + $00)
.DEFINE _fly_yl (entitycharacterdata_t.ext + $02)
.DEFINE _fly_fgxptr (entitycharacterdata_t.ext + $04)

_e_basic_fly_init:
    .ACCU 16
    .INDEX 16
    .EntityIndexYToDP
    ; default info
    lda #10
    sta.b entitycharacterdata_t.health
    stz.b entitycharacterdata_t.status_effects
    sep #$20
    lda #0
    sta.w entity_signal,Y
    sta.w entity_mask,Y
    lda #16
    sta.w entity_boxw,Y
    sta.w entity_boxh,Y
    rep #$20
    ; load sprite
    lda #sprite.enemy.attack_fly.0
    jsl spriteman_new_sprite_ref
    rep #$30
    txa
    sta.b _fly_fgxptr
    ; load frame 2
    lda #sprite.enemy.attack_fly.1
    jsl spriteman_new_sprite_ref
    rep #$30
    txa
    sta.b _fly_fgxptr+2
    ; end
    .END_EntityIndexYToDP
    rts

_e_basic_fly_tick:
    .ACCU 16
    .INDEX 16
    .EntityIndexYToDP
; Remove col
    sep #$30 ; 8B AXY
    .EntityRemoveHitbox 2, 2
; move
    ; TO PLAYER
    lda.w entity_posx,Y
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
    lda.w entity_posy,Y
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
    lda.w entity_posx,Y
    xba
    lda.b _fly_xl
    rep #$20
    ; Apply X
    clc
    adc.b $00
    clc
    adc.b $06
    sep #$20
    sta.b _fly_xl
    xba
    sta.w entity_posx,Y
    ; RAND Y
    sep #$30 ; 8B AXY
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
    lda.w entity_posy,Y
    xba
    lda.b _fly_yl
    rep #$20
    ; Apply Y
    clc
    adc.b $00
    clc
    adc.b $04
    sep #$20
    sta.b _fly_yl
    xba
    sta.w entity_posy,Y
; load & set gfx
    rep #$20
    lda #0
    sep #$20
    ldx.b _fly_fgxptr
    lda.w entity_timer,Y
    dec A
    sta.w entity_timer,Y
    and #$08
    beq +
    ldx.b _fly_fgxptr+2
    +:
    lda.w loword(spriteTableValue + spritetab_t.spritemem),X
    phx
    tax
    lda.l SpriteSlotIndexTable,X
    plx
    ldx.w objectIndex
    sta.w objectData.1.tileid,X
    lda.w entity_posx,Y
    sta.w objectData.1.pos_x,X
    lda.w entity_posy,Y
    sta.w objectData.1.pos_y,X
    lda #%00101001
    sta.w objectData.1.flags,X
    .END_EntityIndexYToDP
    ; add to partition
    .EntityAddHitbox 2, 2
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
    .EntityIndexYToExtX
    lda.w entity_data + _fly_fgxptr,X
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
    ldy #ENTITY_TOTAL_MAX
    ; for character entities, start from ENTITY_CHARACTER_MAX instead.
    cmp #0
    bpl +
    ldy #ENTITY_CHARACTER_MAX
    +:
    lda.w entity_type,Y
    beq @end
@loop:
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
    ldy.w #ENTITY_TOTAL_MAX
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
    ldy.w #ENTITY_TOTAL_MAX
@loop:
    ; stz.w entity_mask,X
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
    bne @loop
@end:
    ; clear entity partition
    ; jsl SpatialPartitionClear
    ; Add entities to partition
;     sep #$20
;     ldy.w #ENTITY_TOTAL_MAX
; @loop_part:
;     lda.w entity_mask,Y
;     and #$00FF
;     beq @skip_part ; skip if mask == 0
;     lda.w entity_type,Y
;     and #$00FF
;     beq @skip_part ; skip if type == 0

;     lda.w entity_boxw,Y
;     lsr
;     lsr
;     lsr
;     lsr
;     sta.b $00
;     lda.w entity_boxh,Y
;     lsr
;     lsr
;     lsr
;     lsr
;     sta.b $01

;     dec.b $01

    ; .MultiplyStatic 8
    ; tax
    ; phy
    ; jsr (EntityDefinitions + entitytypeinfo_t.tick_func,X)
    ; ply
; @skip_part:
;     dey
;     bne @loop_part
; @end_part:
; end
    plb
    rtl

EntityInfoInitialize:
    phd
    pea $4300
    pld
    .ClearWRam_ZP _base_entity_type, (rawMemorySizeShared-entity_type)
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
