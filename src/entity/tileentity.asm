.include "base.inc"

.BANK $02 SLOT "ROM"
.SECTION "Entity Tile" SUPERFREE

.define _entity_spriteptr loword(entity_custom.1)
.define _entity_hits loword(entity_custom.2)
.define _entity_paletteptr loword(entity_custom.3)

true_entity_tile_tick:
    .ACCU 16
    .INDEX 16
    sty.b $00
    lda #0
    sep #$20
    ; tile ID 2
    ldx.w _entity_spriteptr,Y
    lda.w loword(spriteTableValue + spritetab_t.spritemem),X
    tax
    lda.l SpriteSlotIndexTable,X
    ldx.w objectIndex
    sta.w objectData.1.tileid,X
    ; X position
    lda.w entity_posx + 1,Y
    sta.w objectData.1.pos_x,X
    ; Y position
    lda.w entity_posy + 1,Y
    sec
    sbc #4
    sta.w objectData.1.pos_y,X
    ; flags
    lda.w _entity_paletteptr,Y
    .PaletteIndexToPaletteSpriteA
    ora #%00100001
    sta.b $02
    lda.w loword(entity_damageflash),Y
    beq +
        dec A
        sta.w loword(entity_damageflash),Y
        lda #%00101111
        sta.b $02
    +:
    lda.b $02
    sta.w objectData.1.flags,X
    rep #$30
    .SetCurrentObjectS_Inc
    ; set box and mask
    ldy.b $00
    .EntityEasySetBox 16 14
    sep #$20
    lda #ENTITY_MASK_TEAR | ENTITY_MASK_BOMBABLE
    sta.w entity_mask,Y
    ; check signal
    lda.w entity_signal,Y
    bit #ENTITY_SIGNAL_BOMBED
    bne @destroy
    bit #ENTITY_SIGNAL_DAMAGE
    beq @not_damaged
        lda.w _entity_hits,Y
        dec A
        beq @destroy
        sta.w _entity_hits,Y
        jmp @not_damaged
    @destroy:
        jsl entity_free
        rtl
    @not_damaged:
    lda #0
    sta.w entity_signal,Y
    lda.w entity_box_y1,Y
    clc
    adc #8
    sta.w loword(entity_ysort),Y
    ; damage entities in hitbox
    sep #$30
    lda.w entity_box_y1,Y
    and #$F0
    sta.b $02
    ldx.w entity_box_x1,Y
    lda.l Div16,X
    ora.b $02
    sta.b $02
    tax
    .REPT SPATIAL_LAYER_COUNT INDEX i
        .IF i > 0
            ldx.b $02
        .ENDIF
        ldy.w spatial_partition.{i+1},X
        beql @no_col
        lda.w entity_mask,Y
        bit #ENTITY_MASK_BURNABLE
        beq +
        ; check position
        ldx.b $00
        lda.w entity_box_x1,Y
        clc
        adc.w entity_box_x2,Y
        ror
        cmp.w entity_box_x1,X
        bcc +
        cmp.w entity_box_x2,X
        bcs +
        lda.w entity_box_y1,Y
        clc
        adc.w entity_box_y2,Y
        ror
        cmp.w entity_box_y1,X
        bcc +
        cmp.w entity_box_y2,X
        bcs +
            ; burn them
            rep #$20
            lda.w entity_health,Y
            dec A
            sta.w entity_health,Y
            sep #$20
            php
            lda.w entity_signal,Y
            ora #ENTITY_SIGNAL_DAMAGE
            plp
            bpl ++
                ora #ENTITY_SIGNAL_KILL
            ++:
            sta.w entity_signal,Y
        +:
    .ENDR
@no_col:
    rtl

.ENDS

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Tile Hooks" FREE

entity_tile_init:
    .ACCU 16
    .INDEX 16
    lda #$7FFF
    sta.w entity_health,Y
    lda #3
    sta.w _entity_hits,Y
    ; upload palette
    phy
    ldy #loword(palettes.tilesprite_fire_normal)
    lda #8
    jsl Palette.find_or_upload_transparent
    rep #$30
    ply
    txa
    sta.w _entity_paletteptr,Y
    .PaletteIndex_X_ToSpriteDef_A
    ; upload sprite
    ora #sprite.tilesprite_fire
    phy
    jsl Spriteman.NewSpriteRef
    rep #$30
    ply
    txa
    sta.w _entity_spriteptr,Y
    rts

entity_tile_free:
    .ACCU 16
    .INDEX 16
    phy
    lda.w _entity_spriteptr,Y
    tax
    jsl Spriteman.UnrefSprite
    rep #$30
    ply
    ldx.w _entity_paletteptr,Y
    jsl Palette.free
    rts

entity_tile_tick:
    .ACCU 16
    .INDEX 16
    pla
    phk
    pha
    jml true_entity_tile_tick

.ENDS
