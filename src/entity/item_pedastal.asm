.include "base.inc"

.DEFINE _item_gfxptr_pedastal loword(entity_char_custom.1)
.DEFINE _item_gfxptr_item loword(entity_char_custom.2)
.DEFINE _item_palette loword(entity_char_custom.3)
.DEFINE _item_anim_timer loword(entity_char_custom.4)

; hijack entity_timer for price as it is serialized
.DEFINE _item_price entity_timer
; hijack velocx for has-uploaded-text flag
.DEFINE _has_put_text entity_velocx
; hijack velocy for state
.DEFINE _item_state entity_velocy

.DEFINE STATE_BASE 0
.DEFINE STATE_PICKUP 1
.DEFINE STATE_EMPTY 2

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
    lda.l $010000 * bankbyte(Item.pool.item_room),X
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
        rts
@dont_set_price:
    lda #$00
    sta.w _item_price,Y
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
    rep #$30
    lda #0
    ; load sprite for item
    lda.w entity_variant,Y
    and #$00FF
    asl
    tax
    lda.l Item.items,X
    tax
    lda.l $C10000 + itemdef_t.sprite_index,X
    and #$00FF
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
    jsl Palette.alloc_opaque
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
    lda.l $C10000 + itemdef_t.sprite_palette,X
    tax
    lda.w _item_palette,Y
    txy
    jsl Palette.queue_upload
    rtl

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
    and #$0F
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
    and #$07
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
            ora #deft($70,5) | T_HIGHP
        +:
        sta.l vqueueMiniOps.1.data,X
        lda.w _item_price,Y
        and #$000F
        ora #deft($70,5) | T_HIGHP
        sta.l vqueueMiniOps.2.data,X
        lda #deft($7A,5) | T_HIGHP
        sta.l vqueueMiniOps.3.data,X
@skip_set_text:
    rep #$30
    lda #0
    sep #$20
    ; check player position, and potentially change state
    .EntityEasySetBox 16 12
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
        phy
        php
        lda entity_variant,Y
        jsl Item.add
        plp
        ply
        lda #STATE_EMPTY
        sta.w _item_state,Y
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
    and #$07
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

true_item_pedastal_free:
    .ACCU 16
    .INDEX 16
    sty.b $10
    ; fallback to give item if in held state
    sep #$20
    lda.w _item_state,Y
    cmp #STATE_PICKUP
    bne +
        phy
        php
        lda.w entity_variant,Y
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
    lda.w _item_palette
    jsl Palette.free
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
