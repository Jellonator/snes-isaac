.include "base.inc"

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Item Pedastal" FREE

.DEFINE _item_gfxptr_pedastal entity_char_custom.1
.DEFINE _item_gfxptr_item entity_char_custom.2
.DEFINE _item_palette entity_char_custom.3

item_pedastal_init:
    .ACCU 16
    .INDEX 16
    ; load sprite for item
    lda.w entity_variant,Y
    and #$00FF
    asl
    asl
    clc
    adc #sprite.item.0
    phy
    jsl spriteman_new_sprite_ref
    rep #$30
    ply
    txa
    sta.w _item_gfxptr_item,Y
    ; load sprite for pedastal
    lda #sprite.item_pedastal
    phy
    jsl spriteman_new_sprite_ref
    rep #$30
    ply
    txa
    sta.w _item_gfxptr_pedastal,Y
    ; find palette slot for pedastal
    phy
    jsl Palette.find_available_opaque
    rep #$30
    ply
    txa
    sta.w _item_palette,Y
    ; upload palette
    lda.w entity_variant,Y
    and #$00FF
    asl
    tax
    lda.l Item.items,X
    tax
    lda.l $010000 + itemdef_t.sprite_palette,X
    lda.w _item_palette,Y
    jsl Palette.queue_upload
    rts

item_pedastal_free:
    .ACCU 16
    .INDEX 16
    lda.w _item_gfxptr_item,Y
    tax
    jsl spriteman_unref
    rts

item_pedastal_tick:
    .ACCU 16
    .INDEX 16
    rep #$30
    lda #0
    sep #$20
    ; tile ID 1
    ldx.w _item_gfxptr_item,Y
    lda.w loword(spriteTableValue + spritetab_t.spritemem),X
    tax
    lda.l SpriteSlotIndexTable,X
    ldx.w objectIndex
    sta.w objectData.1.tileid,X
    ; tile ID 2
    ldx.w _item_gfxptr_pedastal,Y
    lda.w loword(spriteTableValue + spritetab_t.spritemem),X
    tax
    lda.l SpriteSlotIndexTable,X
    ldx.w objectIndex
    sta.w objectData.2.tileid,X
    ; X position
    lda.w entity_posx + 1,Y
    sta.w objectData.1.pos_x,X
    sta.w objectData.2.pos_x,X
    ; Y position
    lda.w entity_posy + 1,Y
    sta.w objectData.2.pos_y,X
    lda.w entity_timer,Y
    inc A
    sta.w entity_timer,Y
    lsr
    lsr
    lsr
    lsr
    lsr
    and #$03
    cmp #3
    bne +
        lda #1
    +:
    clc
    adc.w entity_posy + 1,Y
    sec
    sbc #8
    sta.w objectData.1.pos_y,X
    adc #20
    sta.w entity_ysort,Y
    ; flags
    lda #%00100001
    sta.w objectData.1.flags,X
    sta.w objectData.2.flags,X
    ; increment object index
    .SetCurrentObjectS
    ldx.w objectIndex
    inx
    inx
    inx
    inx
    stx.w objectIndex
    .SetCurrentObjectS
    ldx.w objectIndex
    inx
    inx
    inx
    inx
    stx.w objectIndex
    rts

.ENDS