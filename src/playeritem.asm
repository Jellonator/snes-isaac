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
    sta.w playerData.playerItemList,X
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

; Remove item 'A' from player items
Item.remove:
    sep #$30
    ; search and remove from list
    ldx #PLAYER_MAX_ITEM_COUNT-1
    @loop:
        cmp.w playerData.playerItemList,X
        beq @found
        dex
        cpx #$FF
        bne @loop
    @fail:
        rtl
    @found:
        xba
    @loop_copy:
        lda.w playerData.playerItemList+1,X
        sta.w playerData.playerItemList,X
        inx
        cpx #PLAYER_MAX_ITEM_COUNT
        bne @loop_copy
        xba
    ; decrement stack count
    tax
    dec.w playerData.playerItemStackNumber,X
    dec.w playerData.playerItemCount
    ; set flags
    rep #$20
    lda #PLAYER_FLAG_INVALIDATE_ITEM_CACHE
    tsb.w playerData.flags
    rtl

; Set player's active item to A
; This function does NOT modify charge.
; The caller is responsible for:
;    - setting correct charge
;    - swapping/creating item pedastals
Item.set_active:
    sep #$30
    cmp.w playerData.current_active_item
    ; bne +
    ;     rtl
    ; +:
    sta.w playerData.current_active_item
    ; get pointer to item
Item.update_active_palette:
    rep #$30
    lda.w playerData.current_active_item
    and #$00FF
    asl
    tax
    lda.l Item.items,X
    tax
    ; set up copy sprite
    ; Don't copy here; sprite changes depending on active status
    ; Battery charge handler will upload sprite instead.
    ; upload palette
    rep #$30
    pea 24
    pea PALETTE_UI.0 + $0400 | bankbyte(palettes.palette0.w)
    lda.l bankaddr(Item.items) | itemdef_t.palette_ptr,X
    clc
    adc #8
    pha
    jsl CopyPaletteVQueue
    rep #$30
    pla
    pla
    pla
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
    ; respawn familiars
    jsl Familiars.RefreshFamiliars
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

_use_empty:
_pickup_empty:
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
    sprite_index: .db $FF
    palette_ptr: .dw loword(palettes.ui_light)
    palette_depth: .db 4
    flags: .db 0
    on_pickup: .dw _pickup_empty
    on_use: .dw _use_empty
    shop_price: .db $15
    name: .ASCSTR "null", 0
    tagline: .ASCSTR "Wait, What?", 0
.ENDST

.DSTRUCT Item.definitions.sad_onion INSTANCEOF itemdef_t VALUES
    sprite_index: .db 0
    palette_ptr: .dw palettes.item_sad_onion
    palette_depth: .db 12
    flags: .db 0
    on_pickup: .dw _pickup_empty
    on_use: .dw _use_empty
    shop_price: .db $15
    name: .ASCSTR "Sad Onion", 0
    tagline: .ASCSTR "Tears Up", 0
.ENDST

.DSTRUCT Item.definitions.spoon_bender INSTANCEOF itemdef_t VALUES
    sprite_index: .db 1
    palette_ptr: .dw palettes.item_spoon_bender
    palette_depth: .db 8
    flags: .db 0
    on_pickup: .dw _pickup_empty
    on_use: .dw _use_empty
    shop_price: .db $15
    name: .ASCSTR "Spoon Bender", 0
    tagline: .ASCSTR "Homing Shots", 0
.ENDST

.DSTRUCT Item.definitions.growth_hormones INSTANCEOF itemdef_t VALUES
    sprite_index: .db 2
    palette_ptr: .dw palettes.item_growth_hormones
    palette_depth: .db 8
    flags: .db 0
    on_pickup: .dw _pickup_empty
    on_use: .dw _use_empty
    shop_price: .db $15
    name: .ASCSTR "Growth Hormones", 0
    tagline: .ASCSTR "Damage and Speed Up", 0
.ENDST

.DSTRUCT Item.definitions.brother_bobby INSTANCEOF itemdef_t VALUES
    sprite_index: .db 3
    palette_ptr: .dw palettes.item_brother_bobby
    palette_depth: .db 8
    flags: .db 0
    on_pickup: .dw _pickup_empty
    on_use: .dw _use_empty
    shop_price: .db $15
    name: .ASCSTR "Brother Bobby", 0
    tagline: .ASCSTR "Best Friend", 0
.ENDST

.DSTRUCT Item.definitions.wire_coat_hanger INSTANCEOF itemdef_t VALUES
    sprite_index: .db 4
    palette_ptr: .dw palettes.palette0
    palette_depth: .db 4
    flags: .db 0
    on_pickup: .dw _pickup_empty
    on_use: .dw _use_empty
    shop_price: .db $15
    name: .ASCSTR "Wire Coat Hanger", 0
    tagline: .ASCSTR "Tears Up", 0
.ENDST

.DSTRUCT Item.definitions.dinner INSTANCEOF itemdef_t VALUES
    sprite_index: .db 5
    palette_ptr: .dw palettes.item_dinner
    palette_depth: .db 12
    flags: .db 0
    on_pickup: .dw _health_up_pickup
    on_use: .dw _use_empty
    shop_price: .db $15
    name: .ASCSTR "Dinner", 0
    tagline: .ASCSTR "Health Up", 0
.ENDST

.DSTRUCT Item.definitions.chocolate_milk INSTANCEOF itemdef_t VALUES
    sprite_index: .db 6
    palette_ptr: .dw palettes.item_chocolate_milk
    palette_depth: .db 8
    flags: .db 0
    on_pickup: .dw _pickup_empty
    on_use: .dw _use_empty
    shop_price: .db $15
    name: .ASCSTR "Chocolate Milk", 0
    tagline: .ASCSTR "Charge Tears", 0
.ENDST

.DSTRUCT Item.definitions.polyphemus INSTANCEOF itemdef_t VALUES
    sprite_index: .db 7
    palette_ptr: .dw palettes.item_polyphemus
    palette_depth: .db 12
    flags: .db 0
    on_pickup: .dw _pickup_empty
    on_use: .dw _use_empty
    shop_price: .db $15
    name: .ASCSTR "Polyphemus", 0
    tagline: .ASCSTR "Mega Tears", 0
.ENDST

.DSTRUCT Item.definitions.map INSTANCEOF itemdef_t VALUES
    sprite_index: .db 8
    palette_ptr: .dw palettes.item_map
    palette_depth: .db 8
    flags: .db 0
    on_pickup: .dw _pickup_map
    on_use: .dw _use_empty
    shop_price: .db $15
    name: .ASCSTR "Treasure Map", 0
    tagline: .ASCSTR "Map Revealed", 0
.ENDST

.DSTRUCT Item.definitions.compass INSTANCEOF itemdef_t VALUES
    sprite_index: .db 9
    palette_ptr: .dw palettes.item_compass
    palette_depth: .db 16
    flags: .db 0
    on_pickup: .dw _pickup_map
    on_use: .dw _use_empty
    shop_price: .db $15
    name: .ASCSTR "Compass", 0
    tagline: .ASCSTR "The End is Near", 0
.ENDST

.DSTRUCT Item.definitions.deck_of_cards INSTANCEOF itemdef_t VALUES
    sprite_index: .db 10
    palette_ptr: .dw palettes.item_deck_of_cards
    palette_depth: .db 8
    flags: .db ITEMFLAG_ACTIVE
    on_pickup: .dw _pickup_empty
    on_use: .dw _use_deck_of_cards
    shop_price: .db $10
    charge_max: .db 6
    charge_use: .db 6
    charge_init: .db 6
    name: .ASCSTR "Deck of Cards", 0
    tagline: .ASCSTR "May You Find What You Seek", 0
.ENDST

.DSTRUCT Item.definitions.brimstone INSTANCEOF itemdef_t VALUES
    sprite_index: .db 11
    palette_ptr: .dw palettes.item_brimstone
    palette_depth: .db 8
    flags: .db ITEMFLAG_COST_TWO_HEARTS
    on_pickup: .dw _pickup_empty
    on_use: .dw _use_empty
    shop_price: .db $30
    name: .ASCSTR "Brimstone", 0
    tagline: .ASCSTR "Bloody Laser Blast", 0
.ENDST

Item.items:
    .dw Item.definitions.null
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
    .dw Item.definitions.deck_of_cards
    .dw Item.definitions.brimstone
    .REPT 256-11
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
    .db ITEMID_DECK_OF_CARDS
    .db ITEMID_BROTHER_BOBBY
    @end:

Item.pool.boss:
    .db ITEMID_GROWTH_HORMONES
    .db ITEMID_WIRE_COAT_HANGER
    .db ITEMID_DINNER
    @end:

Item.pool.shop:
    .db ITEMID_MAP
    .db ITEMID_COMPASS
    .db ITEMID_DECK_OF_CARDS
    @end:

Item.pool.devil:
    .db ITEMID_BRIMSTONE
    .db ITEMID_BROTHER_BOBBY
    @end:

Item.try_use_active:
    rep #$30
    lda.w playerData.current_active_item
    and #$00FF
    bne @has_item
        rtl
@has_item:
    asl
    tax
    lda.l Item.items,X
    tax
    stx.b $00
    sep #$20
    lda.l bankaddr(Item.items) | itemdef_t.charge_use,X
    sta.b $02
    lda.w playerData.current_active_charge
    cmp.b $02
    bcs @has_enough_charge
        rtl
@has_enough_charge:
    sec
    sbc.b $02
    sta.w playerData.current_active_charge
    jsr (itemdef_t.on_use,X)
    rtl

; Returns A=1 if active item does not have full charge
Item.can_add_charge:
    rep #$30
    lda.w playerData.current_active_item
    and #$00FF
    bne @has_item
        lda #0
        rtl
@has_item:
    asl
    tax
    lda.l Item.items,X
    tax
    stx.b $00
    sep #$20
    lda.l bankaddr(Item.items) | itemdef_t.charge_max,X
    sta.b $02
    lda.w playerData.current_active_charge
    cmp.b $02
    bcs @has_full_charge
        lda #1
        rtl
@has_full_charge:
    lda #0
    rtl

; Add `A` charge to current active item
Item.add_charge_amount:
    rep #$30
    sta.b $04
    lda.w playerData.current_active_item
    and #$00FF
    bne @has_item
        sep #$20
        lda #0
        rtl
@has_item:
    asl
    tax
    lda.l Item.items,X
    tax
    stx.b $00
    sep #$20
    lda.l bankaddr(Item.items) | itemdef_t.charge_max,X
    sta.b $02
    lda.w playerData.current_active_charge
    clc
    adc.b $04
    .AMINU P_DIR $02
    sta.w playerData.current_active_charge
    jsl UI.update_charge_display
    rtl

; Add single `charge_use` charge to current active item
Item.add_charge_battery:
    rep #$30
    lda.w playerData.current_active_item
    and #$00FF
    bne @has_item
        lda #0
        rtl
@has_item:
    asl
    tax
    lda.l Item.items,X
    tax
    stx.b $00
    sep #$20
    lda.l bankaddr(Item.items) | itemdef_t.charge_max,X
    sta.b $02
    lda.l bankaddr(Item.items) | itemdef_t.charge_use,X
    sta.b $04
    lda.w playerData.current_active_charge
    clc
    adc.b $04
    .AMINU P_DIR $02
    sta.w playerData.current_active_charge
    jsl UI.update_charge_display
    rtl

_use_deck_of_cards:
    jsl RoomRand_Update8
    .ACCU 16
    sta.l DIVU_DIVIDEND
    sep #$30
    lda #(CONSUMABLEID_TAROT_LAST - CONSUMABLEID_TAROT_FIRST) + 1
    sta.l DIVU_DIVISOR
    .REPT 8
        nop
    .ENDR
    lda.l DIVU_REMAINDER
    clc
    adc #CONSUMABLEID_TAROT_FIRST
    jsl Consumable.pickup
    jsl UI.update_charge_display
    rts

.ENDS