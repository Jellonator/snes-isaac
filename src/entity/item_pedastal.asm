.include "base.inc"

.DEFINE _item_gfxptr_pedastal loword(entity_char_custom.1)
.DEFINE _item_gfxptr_item loword(entity_char_custom.2)
.DEFINE _item_palette loword(entity_char_custom.3)
.DEFINE _item_anim_timer loword(entity_char_custom.4)
.DEFINE _has_put_text loword(entity_char_custom.5)
.DEFINE _item_state loword(entity_char_custom.6)

; hijack entity_timer for price as it is serialized
.DEFINE _item_price entity_timer
; hijack state for iteminfo (since its serialized)
.DEFINE _item_infostore entity_state

.DEFINE STATE_BASE 0
.DEFINE STATE_PICKUP 1
.DEFINE STATE_EMPTY 2

.DEFINE ITEM_INFOSTORE_ACTIVE $80
.DEFINE ITEM_INFOSTORE_CHARGE $3F

.BANK $02 SLOT "ROM"
.SECTION "Entity Item Pedastal" SUPERFREE

_item_pedastal_get_variant_from_pool:
    .ACCU 16
    .INDEX 16
    lda.w entity_variant,Y
    sta.b $00
    and #$007F
    cmp #ENTITY_ITEMPEDASTAL_POOL_BOSS
    beq @pool_boss
    cmp #ENTITY_ITEMPEDASTAL_POOL_SHOP
    beq @pool_shop
@pool_item_room:
    lda #Item.pool.item_room@end - Item.pool.item_room
    ldx #loword(Item.pool.item_room)
    jmp @begin
@pool_boss:
    lda #Item.pool.boss@end - Item.pool.boss
    ldx #loword(Item.pool.boss)
    jmp @begin
@pool_shop:
    lda #Item.pool.shop@end - Item.pool.shop
    ldx #loword(Item.pool.shop)
    jmp @begin
@begin:
    pha
    phy
    php
    jsl RoomRand_Update16
    sta.l DIVU_DIVIDEND
    plp
    ply
    pla
    sta.l DIVU_DIVISOR
    .REPT 8
        nop
    .ENDR
    txa
    clc
    adc.l DIVU_REMAINDER
    tax
    lda.l bankaddr(Item.pool.item_room),X
    sep #$20
    sta.w entity_variant,Y
    ; maybe set price
    lda.b $00
    and #ENTITY_ITEMPEDASTAL_PRICED
    beq @dont_set_price
        rep #$30
        lda.w entity_variant,Y
        and #$00FF
        asl
        tax
        lda.l Item.items,X
        tax
        sep #$20
        lda.l bankaddr(Item.items) + itemdef_t.shop_price,X
        sta.w _item_price,Y
        jmp @end_set_price
@dont_set_price:
    lda #$00
    sta.w _item_price,Y
@end_set_price:
    ; set infostore
    rep #$20
    lda #$00
    sta.b $00
    lda.w entity_variant,Y
    and #$00FF
    asl
    tax
    lda.l Item.items,X
    tax
    sep #$20
    lda.l bankaddr(Item.items) | itemdef_t.charge_init,X
    sta.b $00
    lda.l bankaddr(Item.items) | itemdef_t.flags,X
    bit #ITEMFLAG_ACTIVE
    beq +
        lda #ITEM_INFOSTORE_ACTIVE
        tsb.b $00
    +:
    lda.b $00
    sta.w _item_infostore,Y
    rts

true_item_pedastal_init:
    .ACCU 16
    .INDEX 16
    lda #0
    sta.w _has_put_text,Y
    lda.b entitySpawnContext
    cmp #ENTITY_SPAWN_CONTEXT_DESERIALIZE
    beq @skip_get_pool
        ; get item from pool if not deserializing
        phy
        php
        jsr _item_pedastal_get_variant_from_pool
        plp
        ply
@skip_get_pool:
    sep #$20
    lda #STATE_BASE
    sta.w _item_state,Y
    jsr _item_pedastal_alloc_gfx
    rtl

_item_pedastal_alloc_gfx:
    rep #$30
    lda.w entity_variant,Y
    and #$00FF
    asl
    tax
    lda.l Item.items,X
    tax
    lda.l $C10000 + itemdef_t.palette_depth,X
    and #$00FF
    sta.b $10
    lda.l $C10000 + itemdef_t.palette_ptr,X
    sta.b $12
    lda.l $C10000 + itemdef_t.sprite_index,X
    and #$00FF
    clc
    adc #sprite.item.0
    sta.b $14
    ; find palette slot for pedastal
    phy
    lda.b $10
    ldy.b $12
    jsl Palette.find_or_upload_opaque
    rep #$30
    ply
    txa
    sta.w _item_palette,Y
    ; load sprite
    .PaletteIndex_X_ToSpriteDef_A
    ora.b $14
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
    rts

_draw_normal:
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
    lda.w _item_anim_timer,Y
    inc A
    sta.w _item_anim_timer,Y
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
    sta.w loword(entity_ysort),Y
    ; flags
    lda #%00100001
    sta.w objectData.2.flags,X
    lda.w _item_palette,Y
    .PaletteIndexToPaletteSpriteA
    ora #%00100001
    sta.w objectData.1.flags,X
    ; increment object index
    rep #$30
    phy
    .SetCurrentObjectS_Inc
    .SetCurrentObjectS_Inc
    ply
    rts

_draw_no_pedastal:
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
    ; X position
    lda.w entity_posx + 1,Y
    sta.w objectData.1.pos_x,X
    ; Y position
    lda.w entity_posy + 1,Y
    sta.w objectData.1.pos_y,X
    clc
    adc #12
    sta.w loword(entity_ysort),Y
    ; flags
    lda.w _item_palette,Y
    .PaletteIndexToPaletteSpriteA
    ora #%00100001
    sta.w objectData.1.flags,X
    ; increment object index
    rep #$30
    phy
    .SetCurrentObjectS_Inc
    ply
    rts

true_item_pedastal_tick_base:
    .ACCU 8
    .INDEX 16
    sty.b $10
    lda _item_price,Y
    beq @no_price
        jsr _draw_no_pedastal
        jmp @end_draw
    @no_price:
        jsr _draw_normal
    @end_draw:
    rep #$30
    ldy.b $10
    sep #$20
    lda.w _item_price,Y
    beq @skip_set_text
    lda.w _has_put_text,Y
    bne @skip_set_text
        lda #1
        sta.w _has_put_text,Y
        ; get address
        rep #$30
        lda.w entity_box_x1,Y
        and #$00FF
        lsr
        lsr
        lsr
        sta.b $00
        lda.w entity_box_y1,Y
        and #$00F8
        clc
        adc #16
        asl
        asl
        clc
        adc.b $00
        clc
        adc #BG1_TILE_BASE_ADDR
        sta.b $00
        ; get ops
        lda.w vqueueNumMiniOps
        asl
        asl
        tax
        inc.w vqueueNumMiniOps
        inc.w vqueueNumMiniOps
        inc.w vqueueNumMiniOps
        ; set vram address
        lda.b $00
        dec A
        sta.l vqueueMiniOps.1.vramAddr,X
        inc A
        sta.l vqueueMiniOps.2.vramAddr,X
        inc A
        sta.l vqueueMiniOps.3.vramAddr,X
        ; set data
        lda.w _item_price,Y
        and #$00F0
        beq +
            lsr
            lsr
            lsr
            lsr
            ora #deft(TILE_TEXT_UINUMBER_BASE,5) | T_HIGHP
        +:
        sta.l vqueueMiniOps.1.data,X
        lda.w _item_price,Y
        and #$000F
        ora #deft(TILE_TEXT_UINUMBER_BASE,5) | T_HIGHP
        sta.l vqueueMiniOps.2.data,X
        lda #deft(TILE_TEXT_UINUMBER_BASE+10,5) | T_HIGHP
        sta.l vqueueMiniOps.3.data,X
@skip_set_text:
    rep #$30
    lda #0
    sep #$20
    ; check player position, and potentially change state
    .EntityEasySetBox 16 12
    lda.w playerData.anim_wait_timer
    bnel @no_player_col
    lda.w playerData.money
    cmp.w _item_price,Y
    bccl @no_player_col
    .EntityEasyCheckPlayerCollision_Box @has_player_col
    jmp @no_player_col
    @has_player_col:
        sep #$20
        lda #STATE_PICKUP
        sta.w _item_state,Y
        lda #60
        sta.w _item_anim_timer,Y
        lda #60
        sta.w playerData.anim_wait_timer
        phy
        php
        lda #22
        jsl Player.set_head_frame
        sep #$30
        lda #30
        jsl Player.set_body_frame
        ; display pickup text
        rep #$30
        lda $02,S
        tay
        lda entity_variant,Y
        and #$00FF
        asl
        tax
        lda.l Item.items,X
        pha
        phb
        .ChangeDataBank bankbyte(Item.items)
        lda $02,S
        clc
        adc #itemdef_t.name
        tax
        jsl Overlay.putline
        rep #$30
        lda $02,S
        clc
        adc #itemdef_t.tagline
        tax
        jsl Overlay.putline
        rep #$30
        plb
        plx
        ; end
        plp
        ply
        rep #$20
        lda.w loword(entity_flags),Y
        ora #ENTITY_FLAGS_DONT_SERIALIZE
        sta.w loword(entity_flags),Y
        ; reduce money
        sep #$28
        lda.w _item_price,Y
        beq @dont_subtract_money
            lda.w playerData.money
            sec
            sbc.w _item_price,Y
            sta.w playerData.money
            jsl Player.update_money_display
        @dont_subtract_money:
        rep #$08
        ; set price to 0
        sep #$20
        lda #0
        sta.w _item_price,Y
@no_player_col:
    rtl

true_item_pedastal_tick_pickup:
    .ACCU 8
    .INDEX 16
    ; death timer >:)
    lda.w _item_anim_timer,Y
    dec A
    sta.w _item_anim_timer,Y
    bne +
        ; pickup; switch to empty and add item to player
        jsr _item_pedastal_pickup
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
    sbc #28
    sta.w objectData.1.pos_y,X
    lda.w _item_palette,Y
    .PaletteIndexToPaletteSpriteA
    ora #%00100001
    sta.w objectData.1.flags,X
    ; increment index
    rep #$30
    phy
    php
    .SetCurrentObjectS_Inc
    ; rtl
    plp
    ply

true_item_pedastal_tick_empty:
    .ACCU 8
    .INDEX 16
    jsr _check_and_erase_text
    rep #$30
    lda #0
    sep #$20
    lda.w _item_price,Y
    bne @skip
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
    rep #$30
    .SetCurrentObjectS_Inc
@skip:
    rtl

_item_pedastal_free_gfx:
    rep #$20
    phy
    lda.w _item_gfxptr_item,Y
    tax
    jsl spriteman_unref
    rep #$30
    ply
    lda.w _item_gfxptr_pedastal,Y
    tax
    phy
    jsl spriteman_unref
    rep #$30
    ply
    ldx.w _item_palette,Y
    jsl Palette.free
    rts

true_item_pedastal_free:
    .ACCU 16
    .INDEX 16
    sty.b $10
    ; fallback to give item if in held state
    sep #$20
    lda.w _item_state,Y
    cmp #STATE_PICKUP
    bne +
        jsr _item_pedastal_pickup
    +:
    ; clear gfx
    jsr _item_pedastal_free_gfx
    sep #$30
    ldy.b $10
    jsr _check_and_erase_text
    rtl

_check_and_erase_text:
    sep #$30
    lda.w _has_put_text,Y
    beq @no_erase_price_text
        lda #0
        sta.w _has_put_text,Y
        ; get address
        rep #$30
        lda.w entity_box_x1,Y
        and #$00FF
        lsr
        lsr
        lsr
        sta.b $00
        lda.w entity_box_y1,Y
        and #$00F8
        clc
        adc #16
        asl
        asl
        clc
        adc.b $00
        clc
        adc #BG1_TILE_BASE_ADDR
        sta.b $00
        ; get ops
        lda.w vqueueNumMiniOps
        asl
        asl
        tax
        inc.w vqueueNumMiniOps
        inc.w vqueueNumMiniOps
        inc.w vqueueNumMiniOps
        ; set vram address
        lda.b $00
        dec A
        sta.l vqueueMiniOps.1.vramAddr,X
        inc A
        sta.l vqueueMiniOps.2.vramAddr,X
        inc A
        sta.l vqueueMiniOps.3.vramAddr,X
        ; set data
        lda #0
        sta.l vqueueMiniOps.1.data,X
        sta.l vqueueMiniOps.2.data,X
        sta.l vqueueMiniOps.3.data,X
@no_erase_price_text:
    rts

_item_pedastal_pickup:
    rep #$10
    sep #$20
    lda.w _item_infostore,Y
    bit #ITEM_INFOSTORE_ACTIVE
    bne @active
    ; add passive item
        phy
        php
        lda.w entity_variant,Y
        jsl Item.add
        plp
        ply
        sep #$20
        lda #STATE_EMPTY
        sta.w _item_state,Y
        rts
; set active item
@active:
    lda.w playerData.current_active_item
    pha
    lda.w playerData.current_active_charge
    pha
    phy
    php
    lda.w entity_variant,Y
    jsl Item.set_active
    plp
    ply
    lda.w _item_infostore,Y
    and #ITEM_INFOSTORE_CHARGE
    sta.w playerData.current_active_charge
    phy
    php
    jsl Item.update_charge_display
    plp
    ply
    ; set charge of own item
    lda #ITEM_INFOSTORE_ACTIVE
    ora $01,S
    sta.w _item_infostore,Y
    ; set variant of own item
    lda $02,S
    bne @prev_not_null
        ; if player's previous item was null, just set to empty
        lda #STATE_EMPTY
        sta.w _item_state,Y
        pla
        pla
        rts
@prev_not_null:
    jsr _item_pedastal_free_gfx
    sep #$20
    lda $02,S
    sta.w entity_variant,Y
    lda #STATE_BASE
    sta.w _item_state,Y
    lda.w loword(entity_flags),Y
    and #$FF ~ ENTITY_FLAGS_DONT_SERIALIZE
    sta.w loword(entity_flags),Y
    jsr _item_pedastal_alloc_gfx
; end
    rep #$20
    pla
    rts

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
    jsl true_item_pedastal_free
    rts

item_pedastal_tick:
    .ACCU 16
    .INDEX 16
    pla
    phk
    pha
    sep #$20
    lda.w _item_state,Y
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
