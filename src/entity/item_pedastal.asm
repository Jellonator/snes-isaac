.include "base.inc"

.DEFINE _item_gfxptr_pedastal entity_char_custom.1
.DEFINE _item_gfxptr_item entity_char_custom.2
.DEFINE _item_palette entity_char_custom.3

.DEFINE STATE_BASE 0
.DEFINE STATE_PICKUP 1
.DEFINE STATE_EMPTY 2

.BANK $02 SLOT "ROM"
.SECTION "Entity Item Pedastal" SUPERFREE

true_item_pedastal_init:
    .ACCU 16
    .INDEX 16
    ; init state
    sep #$20
    lda #STATE_BASE
    sta.w entity_state,Y
    rep #$20
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
    tax
    lda.w _item_palette,Y
    txy
    jsl Palette.queue_upload
    rtl

true_item_pedastal_tick_base:
    .ACCU 8
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
    sbc #12
    sta.w objectData.1.pos_y,X
    adc #20
    sta.w entity_ysort,Y
    ; flags
    lda #%00100001
    sta.w objectData.2.flags,X
    lda.w _item_palette,Y
    and #$07
    asl
    ora #%00100001
    sta.w objectData.1.flags,X
    ; check player position, and potentially change state
    .EntityEasySetBox 16 12
    .EntityEasyCheckPlayerCollision @no_player_col
        sep #$20
        lda #STATE_PICKUP
        sta.w entity_state,Y
        lda #60
        sta.w entity_timer,Y
@no_player_col:
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
    rtl

true_item_pedastal_tick_pickup:
    .ACCU 8
    .INDEX 16
    ; death timer >:)
    lda.w entity_timer,Y
    dec A
    sta.w entity_timer,Y
    bne +
        ; pickup; switch to empty and add item to player
        phy
        php
        lda entity_variant,Y
        jsl Item.add
        plp
        ply
        lda #STATE_EMPTY
        sta.w entity_state,Y
    +:
    ; tile ID 1
    rep #$30
    lda #0
    sep #$20
    ldx.w _item_gfxptr_item,Y
    lda.w loword(spriteTableValue + spritetab_t.spritemem),X
    tax
    lda.l SpriteSlotIndexTable,X
    ldx.w objectIndex
    sta.w objectData.1.tileid,X
    ; X position
    lda.w player_box_x1
    sta.w objectData.1.pos_x,X
    ; Y position
    lda.w player_box_y1
    sec
    sbc #32
    sta.w objectData.1.pos_y,X
    lda.w _item_palette,Y
    and #$07
    asl
    ora #%00100001
    sta.w objectData.1.flags,X
    ; increment index
    phy
    php
    .SetCurrentObjectS
    ldx.w objectIndex
    inx
    inx
    inx
    inx
    stx.w objectIndex
    ; rtl
    plp
    ply

true_item_pedastal_tick_empty:
    .ACCU 8
    .INDEX 16
    rep #$30
    lda #0
    sep #$20
    ; tile ID 2
    ldx.w _item_gfxptr_pedastal,Y
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
    sta.w objectData.1.pos_y,X
    ; flags
    lda #%00100001
    sta.w objectData.1.flags,X
    .SetCurrentObjectS
    ldx.w objectIndex
    inx
    inx
    inx
    inx
    stx.w objectIndex
    rtl

.ENDS

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Item Pedastal Hooks" FREE

item_pedastal_init:
    .ACCU 16
    .INDEX 16
    pla
    phk
    pha
    jml true_item_pedastal_init

item_pedastal_free:
    .ACCU 16
    .INDEX 16
    ; fallback to give item if in held state
    sep #$20
    lda.w entity_state,Y
    cmp #STATE_PICKUP
    bne +
        phy
        php
        lda entity_variant,Y
        jsl Item.add
        plp
        ply
    +:
    ; clear gfx
    rep #$20
    phy
    php
    lda.w _item_gfxptr_item,Y
    tax
    jsl spriteman_unref
    plp
    ply
    lda.w _item_gfxptr_pedastal,Y
    tax
    jsl spriteman_unref
    rts

item_pedastal_tick:
    .ACCU 16
    .INDEX 16
    pla
    phk
    pha
    sep #$20
    lda.w entity_state,Y
    cmp #STATE_PICKUP
    bne +
        jml true_item_pedastal_tick_pickup
    +:
    cmp #STATE_EMPTY
    bne +
        jml true_item_pedastal_tick_empty
    +:
    jml true_item_pedastal_tick_base

.ENDS