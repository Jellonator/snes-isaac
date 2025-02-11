.include "base.inc"

.BANK $02 SLOT "ROM"
.SECTION "Entity Effect" SUPERFREE

.define effect_header_ptr loword(entity_custom.1)
.define effect_frame_ptr loword(entity_custom.2)
.define array_ptr loword(entity_custom.3)
.define effect_tile_ptr loword(entity_custom.4)
.define effect_palette_ptr loword(entity_velocx)
.define effect_palette_value loword(entity_velocy)

.STRUCT entityeffect_header_t SIZE 4
    ; number of tiles to allocate for this effect
    tile_alloc db
    num_frames db
    palette dw
.ENDST
.STRUCT entityeffect_frame_t
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
.EffectTile 1, %01100001, -32, -32
.EffectTile 0, %01100001, -16, -32
.EffectTile 0, %00100001,   0, -32
.EffectTile 1, %00100001,  16, -32
.EffectTile 3, %01100001, -32, -16
.EffectTile 2, %01100001, -16, -16
.EffectTile 2, %00100001,   0, -16
.EffectTile 3, %00100001,  16, -16
.EffectTile 5, %01100001, -32,   0
.EffectTile 4, %01100001, -16,   0
.EffectTile 4, %00100001,   0,   0
.EffectTile 5, %00100001,  16,   0
.EffectTileEnd

EntityEffect_Explosion:
.DSTRUCT INSTANCEOF entityeffect_header_t VALUES
    tile_alloc: .db 6
    num_frames: .db 8
    palette: .dw loword(palettes.effect_explosion)
.ENDST
.EffectFrame spritedata.bomb_explosion + spriteoffs(4, 6*4, 0), 2, 3, 4, _EffectExplosion_Tiles
.EffectFrame spritedata.bomb_explosion + spriteoffs(4, 6*4, 1), 2, 3, 4, _EffectExplosion_Tiles
.EffectFrame spritedata.bomb_explosion + spriteoffs(4, 6*4, 2), 2, 3, 4, _EffectExplosion_Tiles
.EffectFrame spritedata.bomb_explosion + spriteoffs(4, 6*4, 3), 2, 3, 4, _EffectExplosion_Tiles
.EffectFrame spritedata.bomb_explosion + spriteoffs(4, 6*4, 4), 2, 3, 4, _EffectExplosion_Tiles
.EffectFrame spritedata.bomb_explosion + spriteoffs(4, 6*4, 5), 2, 3, 4, _EffectExplosion_Tiles
.EffectFrame spritedata.bomb_explosion + spriteoffs(4, 6*4, 6), 2, 3, 4, _EffectExplosion_Tiles
.EffectFrame spritedata.bomb_explosion + spriteoffs(4, 6*4, 7), 2, 3, 4, _EffectExplosion_Tiles

_EffectNull_Tiles:
.EffectTileEnd

EntityEffect_Null:
.DSTRUCT INSTANCEOF entityeffect_header_t VALUES
    tile_alloc: .db 0
    num_frames: .db 1
    palette: .dw 0
.ENDST
.EffectFrame 0, 0, 0, 1, _EffectNull_Tiles

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
    inc A
    inc A
    sta.w effect_frame_ptr,Y
    ; check available slots. If not enough, switch to null effect
    ldx.w effect_header_ptr,Y
    lda.l bankaddr(EntityEffectTypes) + entityeffect_header_t.num_frames,X
    and #$00FF
    sta.w entity_health,Y
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
        inc A
        inc A
        sta.w effect_frame_ptr,Y
        tax
        lda #1
        sta.w entity_health,Y
    +:
    ; set up timer
    sep #$20
    lda #1
    sta.w entity_timer,Y
    ; allocate sprite slots
    rep #$20
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
    ; set up palette
    rep #$30
    ldx.w effect_header_ptr,Y
    lda.l bankaddr(EntityEffectTypes) + entityeffect_header_t.palette,X
    sta.w effect_palette_value,Y
    beq @skip_palette_upload
        phy
        php
        tay
        jsl Palette.find_or_upload
        plp
        ply
        txa
        sta.w effect_palette_ptr,Y
@skip_palette_upload:
    ; some other setup
    sep #$20
    lda.w entity_posy+1,Y
    sta.w loword(entity_ysort),Y
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
    ; free palette
    lda.w effect_palette_value,Y
    beq @skip_free_palette
        ldx.w effect_palette_ptr,Y
        jsl Palette.free
@skip_free_palette:
    rtl

true_entity_effect_tick:
    .ACCU 16
    .INDEX 16
    .DEFINE STORE_Y $00
    .DEFINE ARRAY $02
    .DEFINE POSX $04
    .DEFINE POSY $06
    .DEFINE TILE $08
    .DEFINE PALETTE $0A
    ldx.w effect_tile_ptr,Y
    stx.b TILE
    sty.b STORE_Y
    lda.w array_ptr,Y
    sta.b ARRAY
    lda.w entity_posx,Y
    sta.b POSX
    lda.w entity_posy,Y
    sta.b POSY
    lda.w effect_palette_ptr,Y
    and #$0F
    sta.b PALETTE
    lda #0
    ; draw
    sep #$20
    @loop:
        ldx.b TILE
        lda.l bankaddr(EntityEffectTypes) + entityeffect_tile_t.tile,X
        bmi @end
        tay
        lda (ARRAY),Y
        tax
        lda.l SpriteSlotIndexTable,X
        ldy.w objectIndex
        sta.w objectData.1.tileid,Y
        ldx.b TILE
        lda.l bankaddr(EntityEffectTypes) + entityeffect_tile_t.offx,X
        clc
        adc.b POSX+1
        sta.w objectData.1.pos_x,Y
        lda.l bankaddr(EntityEffectTypes) + entityeffect_tile_t.offy,X
        clc
        adc.b POSY+1
        sta.w objectData.1.pos_y,Y
        lda.l bankaddr(EntityEffectTypes) + entityeffect_tile_t.flags,X
        ora.b PALETTE
        sta.w objectData.1.flags,Y
        ; increment tile
        inx
        inx
        inx
        inx
        stx.b TILE
        ; increment object
        ; TODO: optimize?
        rep #$20
        .SetCurrentObjectS_Inc
        lda #0
        sep #$20
        jmp @loop
@end:
    ldy.b STORE_Y
    ; decrement frame
    tyx
    sep #$20
    dec.w entity_timer,X
    bne @no_advance_frame
        ; advance frame
        dec.w entity_health,X
        bne @no_kill
            ; kill
            rep #$30
            jsl entity_free
            rtl
    @no_kill:
        rep #$20
        lda.w effect_frame_ptr,Y
        clc
        adc #_sizeof_entityeffect_frame_t
        sta.w effect_frame_ptr,Y
        ; rep #$30
        jsr _load_frame
@no_advance_frame:
    rep #$30
    rtl
    .UNDEFINE STORE_Y
    .UNDEFINE ARRAY
    .UNDEFINE POSX
    .UNDEFINE POSY
    .UNDEFINE TILE
    .UNDEFINE PALETTE

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
    sty.b STORE_Y
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
    lda.l bankaddr(EntityEffectTypes) + entityeffect_frame_t.columns,X
    beq @skip_upload
    sta.b COLUMN_ORIGINAL
    lda.l bankaddr(EntityEffectTypes) + entityeffect_frame_t.rows,X
    beq @skip_upload
    sta.b ROW
    lda.l bankaddr(EntityEffectTypes) + entityeffect_frame_t.sprite+2,X
    pha ; bank (1B)
    rep #$20
    lda.l bankaddr(EntityEffectTypes) + entityeffect_frame_t.sprite,X
    pha ; upper half (2B)
    lda.b COLUMN_ORIGINAL
    .MultiplyStatic (8*4*2)
    sta.b BYTEWIDTH
    clc
    adc $01,S
    pha ; lower half (2B)
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
    ldy.b STORE_Y
    rts
@skip_upload:
    rep #$30
    ldy.b STORE_Y
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
