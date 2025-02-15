.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "PlayerItem" FREE

Item.reset_items:
    sep #$30
    stz.w playerData.playerItemCount
    ldx #0
    -:
        stz.w playerData.playerItemStackNumber,X
        inx
        bne -
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
    ; call pickup code
    rep #$30
    stz.w playerData.tear_timer
    txa
    and #$00FF
    asl
    tax
    lda.l Item.items,X
    tax
    jsr (itemdef_t.on_pickup,X)
    rtl

; simple multiplication routine somewhat optimized for small multiplicands
.MACRO .ADDMULTITEM ARGS itemid, addmethod, addamount
    ldx.w playerData.playerItemStackNumber + itemid
    cpx #0
    beq @@@@@@\.\@end
    clc
@@@@@@\.\@loop:
    ; adc #mult
    .g_instruction adc, addmethod, addamount
    dex
    bne @@@@@@\.\@loop
@@@@@@\.\@end:
.ENDM

; For tear rate: tear is shot when counter reaches $3C00
; $0100 is once per second
; $1800 is 2.5 per second
; $3C00 is once per tick

; +1 index should be small tear up
; +4 index should be large tear up (small onion)
Item.tear_rate_base_table:
    .dw $3C00 / 240.0
    .dw $3C00 / 120.0
    .dw $3C00 / 60.0
    .REPT 256 INDEX i
        .dw $3C00 * sqrt(i + 3.0) * 2.5 / 240.0
    .ENDR

.DEFINE PLAYER_TEAR_RATE_INDEX_MAXIMUM 64
.DEFINE PLAYER_TEAR_RATE_VALUE_MINIMUM ($3C00 / 240.0)
.DEFINE PLAYER_SPEED_MAXIMUM 48
.DEFINE PLAYER_SPEED_MINIMUM 12
Item.check_and_recalculate:
    rep #$20
    lda #PLAYER_FLAG_INVALIDATE_ITEM_CACHE
    trb.w playerData.flags
    bne + ; flag wasn't set, return
        rtl
    +:
    ; reset stats to base
    jsl Player.reset_stats
    rep #$20
    stz.w playerData.tearflags
    sep #$10
; TEAR RATE
    lda #PLAYER_STATBASE_TEAR_RATE_INDEX
    .ADDMULTITEM ITEMID_SAD_ONION, P_IMM, 4
    .ADDMULTITEM ITEMID_WIRE_COAT_HANGER, P_IMM, 4
    .AMIN P_IMM PLAYER_TEAR_RATE_INDEX_MAXIMUM
    asl
    tax
    lda.l Item.tear_rate_base_table,X
    ldx.w playerData.playerItemStackNumber + ITEMID_POLYPHEMUS
    beq +
        lsr
    +:
    .AMAXU P_IMM PLAYER_TEAR_RATE_VALUE_MINIMUM
    sta.w playerData.stat_tear_rate
; DAMAGE
    lda.w playerData.stat_damage
    .ADDMULTITEM ITEMID_GROWTH_HORMONES, P_IMM, 3
    .ADDMULTITEM ITEMID_POLYPHEMUS, P_IMM, 4
    .AMAX P_IMM 1 ; always at least 1 damage
    sta.b $00
    .ADDMULTITEM ITEMID_POLYPHEMUS, P_DIR, $00
    sta.w playerData.stat_damage
; SPEED
    lda.w playerData.stat_accel
    .ADDMULTITEM ITEMID_GROWTH_HORMONES, P_IMM, 4
    .AMAX P_IMM PLAYER_SPEED_MINIMUM
    .AMIN P_IMM PLAYER_SPEED_MAXIMUM
    sta.w playerData.stat_accel
    ; speed = 16 × ACCEL
    asl
    asl
    asl
    asl
    sta.w playerData.stat_speed
; tear flags
    lda #0
    ldx.w playerData.playerItemStackNumber + ITEMID_POLYPHEMUS
    beq +
        ora #PROJECTILE_FLAG_POLYPHEMUS
    +:
    ldx.w playerData.playerItemStackNumber + ITEMID_SPOON_BENDER
    beq +
        ora #PROJECTILE_FLAG_HOMING
    +:
    sta.w playerData.tearflags
    jml Costume.player_recalculate
    ; rtl

_empty_pickup:
    rts

_health_up_pickup:
    jsl Player.health_up
    rts

_pickup_map:
    sep #$20
    lda #$FF
    sta.l numTilesToUpdate
    rts

.DSTRUCT Item.definitions.null INSTANCEOF itemdef_t VALUES
    sprite_index: .db 0
    sprite_palette: .dw 0
    flags: .db 0
    on_pickup: .dl _empty_pickup
    shop_price: .db $15
    name: .ASCSTR "null", 0
    tagline: .ASCSTR "Wait, What?", 0
.ENDST

.DSTRUCT Item.definitions.sad_onion INSTANCEOF itemdef_t VALUES
    sprite_index: .db 0
    sprite_palette: .dw palettes.item_sad_onion
    flags: .db 0
    on_pickup: .dl _empty_pickup
    shop_price: .db $15
    name: .ASCSTR "Sad Onion", 0
    tagline: .ASCSTR "Tears Up", 0
.ENDST

.DSTRUCT Item.definitions.spoon_bender INSTANCEOF itemdef_t VALUES
    sprite_index: .db 1
    sprite_palette: .dw palettes.palette0
    flags: .db 0
    on_pickup: .dl _empty_pickup
    shop_price: .db $15
    name: .ASCSTR "Spoon Bender", 0
    tagline: .ASCSTR "Homing Shots", 0
.ENDST

.DSTRUCT Item.definitions.growth_hormones INSTANCEOF itemdef_t VALUES
    sprite_index: .db 2
    sprite_palette: .dw palettes.item_growth_hormones
    flags: .db 0
    on_pickup: .dl _empty_pickup
    shop_price: .db $15
    name: .ASCSTR "Growth Hormones", 0
    tagline: .ASCSTR "Damage and Speed Up", 0
.ENDST

.DSTRUCT Item.definitions.brother_bobby INSTANCEOF itemdef_t VALUES
    sprite_index: .db 3
    sprite_palette: .dw palettes.palette0
    flags: .db 0
    on_pickup: .dl _empty_pickup
    shop_price: .db $15
    name: .ASCSTR "Brother Bobby", 0
    tagline: .ASCSTR "Best Friend", 0
.ENDST

.DSTRUCT Item.definitions.wire_coat_hanger INSTANCEOF itemdef_t VALUES
    sprite_index: .db 4
    sprite_palette: .dw palettes.palette0
    flags: .db 0
    on_pickup: .dl _empty_pickup
    shop_price: .db $15
    name: .ASCSTR "Wire Coat Hanger", 0
    tagline: .ASCSTR "Tears Up", 0
.ENDST

.DSTRUCT Item.definitions.dinner INSTANCEOF itemdef_t VALUES
    sprite_index: .db 5
    sprite_palette: .dw palettes.palette0
    flags: .db 0
    on_pickup: .dl _health_up_pickup
    shop_price: .db $15
    name: .ASCSTR "Dinner", 0
    tagline: .ASCSTR "Health Up", 0
.ENDST

.DSTRUCT Item.definitions.chocolate_milk INSTANCEOF itemdef_t VALUES
    sprite_index: .db 6
    sprite_palette: .dw palettes.item_chocolate_milk
    flags: .db 0
    on_pickup: .dl _empty_pickup
    shop_price: .db $15
    name: .ASCSTR "Chocolate Milk", 0
    tagline: .ASCSTR "Charge Tears", 0
.ENDST

.DSTRUCT Item.definitions.polyphemus INSTANCEOF itemdef_t VALUES
    sprite_index: .db 7
    sprite_palette: .dw palettes.palette0
    flags: .db 0
    on_pickup: .dl _empty_pickup
    shop_price: .db $15
    name: .ASCSTR "Polyphemus", 0
    tagline: .ASCSTR "Mega Tears", 0
.ENDST

.DSTRUCT Item.definitions.map INSTANCEOF itemdef_t VALUES
    sprite_index: .db 8
    sprite_palette: .dw palettes.palette0
    flags: .db 0
    on_pickup: .dl _pickup_map
    shop_price: .db $15
    name: .ASCSTR "Treasure Map", 0
    tagline: .ASCSTR "Map Revealed", 0
.ENDST

.DSTRUCT Item.definitions.compass INSTANCEOF itemdef_t VALUES
    sprite_index: .db 9
    sprite_palette: .dw palettes.item_compass
    flags: .db 0
    on_pickup: .dl _pickup_map
    shop_price: .db $15
    name: .ASCSTR "Compass", 0
    tagline: .ASCSTR "The End is Near", 0
.ENDST

Item.items:
    .dw Item.definitions.sad_onion
    .dw Item.definitions.spoon_bender
    .dw Item.definitions.growth_hormones
    .dw Item.definitions.brother_bobby
    .dw Item.definitions.wire_coat_hanger
    .dw Item.definitions.dinner
    .dw Item.definitions.chocolate_milk
    .dw Item.definitions.polyphemus
    .dw Item.definitions.map
    .dw Item.definitions.compass
    .REPT 256-7
        .dw Item.definitions.null
    .ENDR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;        ITEM POOL DEFINITIONS         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Item.pool.item_room:
    .db ITEMID_SAD_ONION
    .db ITEMID_CHOCOLATE_MILK
    .db ITEMID_POLYPHEMUS
    .db ITEMID_SPOON_BENDER
    @end:

Item.pool.boss:
    .db ITEMID_GROWTH_HORMONES
    .db ITEMID_WIRE_COAT_HANGER
    .db ITEMID_DINNER
    @end:

Item.pool.shop:
    .db ITEMID_MAP
    .db ITEMID_COMPASS
    @end:

.ENDS