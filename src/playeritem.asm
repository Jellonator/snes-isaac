.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "PlayerItem" FREE

Item.reset_items:
    sep #$30
    stz.w playerData.playerItemCount
    ldx #0
        stz.w playerData.playerItemStackNumber,X
        inx
        beq +
    +:
    stz.w playerData.playerItemStackNumber+255
    rtl

; Add item in 'A' to player items
Item.add:
    sep #$30
    ; add to list
    ldx.w playerData.playerItemCount
    sta.w playerData.playerItemList
    inc.w playerData.playerItemCount
    ; increment stack count
    tax
    inc.w playerData.playerItemStackNumber,X
    ; set flags
    rep #$20
    lda #PLAYER_FLAG_INVALIDATE_ITEM_CACHE
    tsb.w playerData.flags
    rtl

Item.check_and_recalculate:
    rep #$20
    lda #PLAYER_FLAG_INVALIDATE_ITEM_CACHE
    trb.w playerData.flags
    bne + ; flag wasn't set, return
        rtl
    +:
    ; reset stats to base
    jsl Player.reset_stats
    ; check items
    lda.w playerData.playerItemStackNumber + ITEMID_SAD_ONION
    and #$00FF
    beq +
        lda.w playerData.stat_tear_delay
        sec
        sbc #8
        sta.w playerData.stat_tear_delay
    +:
    rtl

_empty_pickup:
    rtl

.DSTRUCT Item.definitions.null INSTANCEOF itemdef_t VALUES
    sprite_index: .db 0
    sprite_palette: .dw 0
    flags: .db 0
    on_pickup: .dl _empty_pickup
    name: .db "null", 0
    tagline: .db "null", 0
.ENDST

.DSTRUCT Item.definitions.sad_onion INSTANCEOF itemdef_t VALUES
    sprite_index: .db 0
    sprite_palette: .dw palettes.item_sad_onion
    flags: .db 0
    on_pickup: .dl _empty_pickup
    name: .db "Sad Onion", 0
    tagline: .db "Tears Up", 0
.ENDST

.DSTRUCT Item.definitions.spoon_bender INSTANCEOF itemdef_t VALUES
    sprite_index: .db 1
    sprite_palette: .dw 0
    flags: .db 0
    on_pickup: .dl _empty_pickup
    name: .db "null", 0
    tagline: .db "null", 0
.ENDST

.DSTRUCT Item.definitions.growth_hormones INSTANCEOF itemdef_t VALUES
    sprite_index: .db 2
    sprite_palette: .dw 0
    flags: .db 0
    on_pickup: .dl _empty_pickup
    name: .db "null", 0
    tagline: .db "null", 0
.ENDST

.DSTRUCT Item.definitions.brother_bobby INSTANCEOF itemdef_t VALUES
    sprite_index: .db 3
    sprite_palette: .dw 0
    flags: .db 0
    on_pickup: .dl _empty_pickup
    name: .db "null", 0
    tagline: .db "null", 0
.ENDST

.DSTRUCT Item.definitions.wire_coat_hanger INSTANCEOF itemdef_t VALUES
    sprite_index: .db 0
    sprite_palette: .dw 0
    flags: .db 0
    on_pickup: .dl _empty_pickup
    name: .db "null", 0
    tagline: .db "null", 0
.ENDST

.DSTRUCT Item.definitions.dinner INSTANCEOF itemdef_t VALUES
    sprite_index: .db 0
    sprite_palette: .dw 0
    flags: .db 0
    on_pickup: .dl _empty_pickup
    name: .db "null", 0
    tagline: .db "null", 0
.ENDST

Item.items:
    .dw Item.definitions.sad_onion
    .dw Item.definitions.spoon_bender
    .dw Item.definitions.growth_hormones
    .dw Item.definitions.brother_bobby
    .dw Item.definitions.wire_coat_hanger
    .dw Item.definitions.dinner
    .REPT 256-6
        .dw Item.definitions.null
    .ENDR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;        ITEM POOL DEFINITIONS         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Item.pool.item_room:
    .db ITEMID_SAD_ONION
    .db ITEMID_SPOON_BENDER
    @end:

Item.pool.boss:
    .db ITEMID_GROWTH_HORMONES
    .db ITEMID_WIRE_COAT_HANGER
    .db ITEMID_DINNER
    @end:

.ENDS