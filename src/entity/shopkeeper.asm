.include "base.inc"

.define _palette entity_velocx

.BANK $02 SLOT "ROM"
.SECTION "Entity Shopkeeper" SUPERFREE

true_entity_shopkeeper_tick:
    .ACCU 16
    .INDEX 16
    lda #0
    ; check signal
    sep #$30 ; 8B AXY
    lda #ENTITY_SIGNAL_KILL
    and.w entity_signal,Y
    beq +
        ; set shopkeeper flag
        lda.l devil_deal_flags
        ora #DEVILFLAG_BOMBED_SHOPKEEPER
        sta.l devil_deal_flags
        jsl entity_free
        rtl
    +:
; draw
    rep #$10
    .REPT 4 INDEX i
        ldx.w loword(entity_custom.{i+1}),Y
        lda.w loword(spriteTableValue + spritetab_t.spritemem),X
        tax
        lda.l SpriteSlotIndexTable,X
        ldx.w objectIndex
        sta.w objectData.{i+1}.tileid,X
    .ENDR
    lda.w entity_box_x1,Y
    sec
    sbc #8
    sta.w objectData.1.pos_x,X
    sta.w objectData.3.pos_x,X
    clc
    adc #16
    sta.w objectData.2.pos_x,X
    sta.w objectData.4.pos_x,X
    lda.w entity_box_y1,Y
    sec
    sbc #8
    sta.w objectData.1.pos_y,X
    sta.w objectData.2.pos_y,X
    clc
    adc #16
    sta.w objectData.3.pos_y,X
    sta.w objectData.4.pos_y,X
    lda.w _palette,Y
    .PaletteIndexToPaletteSpriteA
    ora #%00100001
    sta.w objectData.1.flags,X
    sta.w objectData.2.flags,X
    sta.w objectData.3.flags,X
    sta.w objectData.4.flags,X
    rep #$30
    phy
    .SetCurrentObjectS_Inc
    .SetCurrentObjectS_Inc
    .SetCurrentObjectS_Inc
    .SetCurrentObjectS_Inc
    ply
; set public entity info
    .EntityEasySetBox 16 16
    lda #ENTITY_MASK_BOMBABLE
    sta.w entity_mask,Y
    lda #0
    sta.w entity_signal,Y
    lda.w entity_box_y1,Y
    clc
    adc #16
    sta.w loword(entity_ysort),Y
    rtl

true_entity_shopkeeper_init:
    .ACCU 16
    .INDEX 16
    ; set hp
    rep #$30
    lda #1
    sta.w entity_health,Y
    ; load palette
    phy
    ldy #loword(palettes.shopkeeper)
    lda #8
    jsl Palette.find_or_upload_opaque
    rep #$30
    ply
    txa
    sta.w _palette,Y
    .PaletteIndex_X_ToSpriteDef_A
    sta.b $10
    ; load sprite
    .REPT 4 INDEX i
        phy
        lda #sprite.shopkeepers.{i}
        ora.b $10
        jsl Spriteman.NewSpriteRef
        rep #$30
        ply
        txa
        sta.w loword(entity_custom.{i+1}),Y
    .ENDR
    rtl

.ENDS

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Shopkeeper Hooks" FREE

entity_shopkeeper_init:
    .ACCU 16
    .INDEX 16
    jsl true_entity_shopkeeper_init
    rts

entity_shopkeeper_free:
    .ACCU 16
    .INDEX 16
    ; free sprite
    .REPT 4 INDEX i
        phy
        ldx.w loword(entity_custom.{i+1}),Y
        jsl Spriteman.UnrefSprite
        rep #$30
        ply
    .ENDR
    ; free palette
    ldx.w _palette,Y
    jsl Palette.free
    rts

entity_shopkeeper_tick:
    .ACCU 16
    .INDEX 16
    pla
    phk
    pha
    jml true_entity_shopkeeper_tick

.ENDS
