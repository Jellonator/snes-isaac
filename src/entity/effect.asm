.include "base.inc"

.BANK $02 SLOT "ROM"
.SECTION "Entity Effect" SUPERFREE

.define effect_header_ptr entity_custom.1
.define effect_frame_ptr entity_custom.2
.define array_ptr entity_custom.3
.define effect_tile_ptr entity_custom.4

.STRUCT entityeffect_header_t SIZE 2
    ; number of tiles to allocate for this effect
    tile_alloc db
    num_frames db
.ENDST
.STRUCT entityeffect_frame_t SIZE 8
    sprite dl
    columns db
    rows db
    frames db
    tiles dw
.ENDST
.STRUCT entityeffect_tile_t SIZE 4
    tile db
    flags db
    offx db
    offy db
.ENDST

.MACRO .EffectTile ARGS tile, flags, ox, oy
    .DSTRUCT INSTANCEOF entityeffect_tile_t VALUES
        tile: .db tile
        flags: .db flags
        offx: .db ox
        offy: .db oy
    .ENDST
.ENDM

.MACRO .EffectTileEnd
    .DSTRUCT INSTANCEOF entityeffect_tile_t VALUES
        tile: .db $FF
        flags: .db $FF
        offx: .db $FF
        offy: .db $FF
    .ENDST
.ENDM

.MACRO .EffectFrame
    .DSTRUCT INSTANCEOF entityeffect_frame_t VALUES
        sprite: .dl \1
        columns: .db \2
        rows: .db \3
        frames: .db \4
        tiles: .dw \5
    .ENDST
.ENDM

_EffectExplosion_Tiles:
.EffectTile  0, %00000001, -32, -32
.EffectTile  1, %00000001, -16, -32
.EffectTile  2, %00000001,   0, -32
.EffectTile  3, %00000001,  16, -32
.EffectTile  4, %00000001, -32, -16
.EffectTile  5, %00000001, -16, -16
.EffectTile  6, %00000001,   0, -16
.EffectTile  7, %00000001,  16, -16
.EffectTile  8, %00000001, -32,   0
.EffectTile  9, %00000001, -16,   0
.EffectTile 10, %00000001,   0,   0
.EffectTile 11, %00000001,  16,   0
.EffectTileEnd

EntityEffect_Explosion:
.DSTRUCT INSTANCEOF entityeffect_header_t VALUES
    tile_alloc: .db 12
    num_frames: .db 8
.ENDST

.EffectFrame spritedata.bomb_explosion + spriteoffs(4, 12*4, 0), 4, 3, 4, _EffectExplosion_Tiles
.EffectFrame spritedata.bomb_explosion + spriteoffs(4, 12*4, 1), 4, 3, 4, _EffectExplosion_Tiles
.EffectFrame spritedata.bomb_explosion + spriteoffs(4, 12*4, 2), 4, 3, 4, _EffectExplosion_Tiles
.EffectFrame spritedata.bomb_explosion + spriteoffs(4, 12*4, 3), 4, 3, 4, _EffectExplosion_Tiles
.EffectFrame spritedata.bomb_explosion + spriteoffs(4, 12*4, 4), 4, 3, 4, _EffectExplosion_Tiles
.EffectFrame spritedata.bomb_explosion + spriteoffs(4, 12*4, 5), 4, 3, 4, _EffectExplosion_Tiles
.EffectFrame spritedata.bomb_explosion + spriteoffs(4, 12*4, 6), 4, 3, 4, _EffectExplosion_Tiles
.EffectFrame spritedata.bomb_explosion + spriteoffs(4, 12*4, 7), 4, 3, 4, _EffectExplosion_Tiles

_EffectNull_Tiles:
.EffectTileEnd

EntityEffect_Null:
.DSTRUCT INSTANCEOF entityeffect_header_t VALUES
    tile_alloc: .db 0
    num_frames: .db 1
.ENDST
.EffectFrame 0, 1, 1, 1, _EffectNull_Tiles

EntityEffectTypes:
    .dw EntityEffect_Null
    .dw EntityEffect_Explosion

true_entity_effect_init:
    .ACCU 16
    .INDEX 16
    ; Get type ref
    lda.w entity_variant,Y
    and #$00FF
    asl
    tax
    lda.l EntityEffectTypes,X
    sta.w effect_header_ptr,Y
    inc A
    inc A
    sta.w effect_frame_ptr,Y
    ; check available slots. If not enough, switch to null effect
    ldx.w effect_header_ptr,Y
    sep #$20
    lda.l bankaddr(EntityEffectTypes) + entityeffect_header_t.tile_alloc,X
    cmp.w spiteTableAvailableSlots
    bcc +
    beq +
        rep #$20
        lda #EntityEffect_Null
        sta.w effect_header_ptr,Y
        inc A
        inc A
        sta.w effect_frame_ptr,Y
        tax
    +:
    rep #$20
    ; set up timer
    lda #0
    sta.w private_base_entity_combined_state_timer,Y
    ; allocate sprite slots
    phy
    lda.l bankaddr(EntityEffectTypes) + entityeffect_header_t.tile_alloc,X
    and #$00FF
    sta.b $00
    beq @end
    tya
    .MultiplyStatic (ENTITY_DATA_ARRAY_SIZE/2)
    clc
    adc #entity_array_data
    sta.w array_ptr,Y
    sta.b $02
    sep #$30
@loop:
    .spriteman_get_raw_slot_lite ; already in bank $7E
    txa
    sta.b ($02)
    rep #$20
    inc.b $02
    sep #$20
    dec.b $00
    bne @loop
@end:
    rep #$30
    ply
    ; load sprite
    jsr _load_frame
    ; end
    rtl

true_entity_effect_free:
    .ACCU 16
    .INDEX 16
    ldx.w effect_header_ptr,Y
    lda.l bankaddr(EntityEffectTypes) + entityeffect_header_t.tile_alloc,X
    and #$00FF
    sta.b $00
    beq @end
    lda.w array_ptr,Y
    sta.b $02
    sep #$30
@loop:
    lda ($02)
    tax
    .spriteman_free_raw_slot_lite
    rep #$20
    inc.b $02
    sep #$20
    dec.b $00
    bne @loop
@end:
    rep #$30
    rtl

true_entity_effect_tick:
    .ACCU 16
    .INDEX 16
    rtl

; Load sprite data in frame stored in `effect_frame_ptr`
_load_frame:
    .ACCU 16
    .INDEX 16
    .DEFINE COLUMN $00
    .DEFINE ROW $02
    .DEFINE ARRAY $04
    .DEFINE STORE_Y $06
    .DEFINE COLUMN_ORIGINAL $08
    .DEFINE BYTEWIDTH $0A
    ; get tile count
    ; ldx.w effect_header_ptr,Y
    ; lda.l entityeffect_header_t.tile_alloc,X
    ; and #$00FF
    ; sta.b $00
    ; set timer
    ldx.w effect_frame_ptr,Y
    sep #$20
    lda.l bankaddr(EntityEffectTypes) + entityeffect_frame_t.frames,X
    sta.w entity_timer,Y
    ; set tile pointer, for later rendering
    rep #$20
    lda.l bankaddr(EntityEffectTypes) + entityeffect_frame_t.tiles,X
    sta.w effect_tile_ptr,Y
    stz.b COLUMN_ORIGINAL
    stz.b ROW
    lda.w array_ptr,Y
    sta.b ARRAY
    ; push initial address
    sep #$20
    lda.l bankaddr(EntityEffectTypes) + entityeffect_frame_t.sprite+2,X
    pha ; bank (1B)
    lda.l bankaddr(EntityEffectTypes) + entityeffect_frame_t.columns,X
    sta.b COLUMN_ORIGINAL
    lda.l bankaddr(EntityEffectTypes) + entityeffect_frame_t.rows,X
    sta.b ROW
    rep #$20
    lda.l bankaddr(EntityEffectTypes) + entityeffect_frame_t.sprite,X
    pha ; upper half (2B)
    lda.b COLUMN_ORIGINAL
    .MultiplyStatic (8*4*2)
    sta.b BYTEWIDTH
    clc
    adc $01,S
    pha ; lower half (2B)
    sty.b $06 ; $06 = Y
    @loop_y:
        lda.b COLUMN_ORIGINAL
        sta.b COLUMN
        @loop_x:
            lda.b (ARRAY)
            and #$00FF
            tax
            jsl spriteman_write_sprite_to_raw_slot
            rep #$30
            clc
            lda $01,S
            adc #8*4*2
            sta $01,S
            lda $03,S
            adc #8*4*2
            sta $03,S
            inc.b ARRAY ; ++array
            dec.b COLUMN ; --column
            bne @loop_x
        lda $01,S
        adc.b BYTEWIDTH
        sta $01,S
        lda $03,S
        adc.b BYTEWIDTH
        sta $03,S
        dec.b ROW
        bne @loop_y
    sep #$20
    pla
    rep #$30
    pla
    pla
    ldy.b $06
    rts
    .UNDEFINE COLUMN
    .UNDEFINE ROW
    .UNDEFINE ARRAY
    .UNDEFINE STORE_Y
    .UNDEFINE COLUMN_ORIGINAL
    .UNDEFINE BYTEWIDTH

.ENDS

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Effect Hooks" FREE

entity_effect_init:
    .ACCU 16
    .INDEX 16
    pla
    phk
    pha
    jml true_entity_effect_init

entity_effect_free:
    .ACCU 16
    .INDEX 16
    pla
    phk
    pha
    jml true_entity_effect_free

entity_effect_tick:
    .ACCU 16
    .INDEX 16
    pla
    phk
    pha
    jml true_entity_effect_tick

.ENDS
