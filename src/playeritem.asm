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
    rep #$30
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
    pea $4400 | bankbyte(palettes.palette0.w)
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
    jsl Item.update_charge_display
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
    jsl Item.update_charge_display
    rtl

Item.update_charge_display:
    .DEFINE ITEMPTR $00
    .DEFINE MAX_CHARGE $02
    .DEFINE USAGE_CHARGE $04
    .DEFINE PLAYER_CHARGE $06
    .DEFINE TILE $08
    .DEFINE SLOTS $0A
    .DEFINE TILEI_LAST $0C
    .DEFINE IS_FULL $0E
    .DEFINE TMP_CHARGE $10
    .DEFINE TMP_PLAYER_CHARGE $12
    ; get item info
    rep #$30
    lda.w playerData.current_active_item
    and #$00FF
    asl
    tax
    lda.l Item.items,X
    tax
    stx.b ITEMPTR
    lda.l bankaddr(Item.items) | itemdef_t.charge_max,X
    and #$00FF
    sta.b MAX_CHARGE
    lda.l bankaddr(Item.items) | itemdef_t.charge_use,X
    and #$00FF
    sta.b USAGE_CHARGE
    ; get and increment miniop address
    lda.w vqueueNumMiniOps
    pha
    clc
    adc #32
    sta.w vqueueNumMiniOps
    pla
    asl
    asl
    tax
    ; clear and set addresses
    .REPT 8 INDEX iy
        .REPT 4 INDEX ix
            lda #BG1_TILE_BASE_ADDR + ix+2 + (iy+5)*32
            sta.l vqueueMiniOps.{iy*4 + ix + 1}.vramAddr,X
            lda #0
            sta.l vqueueMiniOps.{iy*4 + ix + 1}.data,X
        .ENDR
    .ENDR
    ; get player charge
    lda.w playerData.current_active_charge
    and #$00FF
    sta.b PLAYER_CHARGE
    ; iterate charges
    .REPT 4 INDEX ix
        ; determine charge amounts for this specific battery slot
        lda.b MAX_CHARGE
        beql @end_write
        bmil @end_write
        lda.b PLAYER_CHARGE
        .AMINU P_DIR USAGE_CHARGE
        sta.b TMP_PLAYER_CHARGE
        lda.b MAX_CHARGE
        .AMINU P_DIR USAGE_CHARGE
        sta.b TMP_CHARGE
        inc A
        lsr
        dec A
        sta.b TILEI_LAST
        lda.b TMP_PLAYER_CHARGE
        ldy #0
        cmp.b USAGE_CHARGE
        bcc +
            ldy #1
        +:
        sty.b IS_FULL
        .REPT 8 INDEX iy
            .IF iy == 0
                lda #%00000100
            .ELSE
                lda #%00000000
            .ENDIF
            sta.b TILE
            ; check if last tile
            lda.b TILEI_LAST
            cmp #iy
            blsul @end_slot_{ix}
            bne @not_last_slot_{ix}_{iy}
                lda #%00000010
                tsb.b TILE
            @not_last_slot_{ix}_{iy}:
            ; check FULL flag
            lda.b IS_FULL
            beq @not_full_{ix}_{iy}
                lda #%00011000
                tsb.b TILE
                jmp @was_full_{ix}_{iy}
            @not_full_{ix}_{iy}:
                ; determine C if not full
                lda.b TMP_PLAYER_CHARGE
                .AMINU P_IMM 2
                asl
                asl
                asl
                tsb.b TILE
            @was_full_{ix}_{iy}:
            ; determine M
            lda.b TMP_CHARGE
            .AMINU P_IMM 2
            asl
            asl
            asl
            asl
            asl
            tsb.b TILE
            phx
            ldx.b TILE
            lda.l BatteryTileMap,X
            plx
            sta.l vqueueMiniOps.{iy*4 + ix + 1}.data,X
            ; subtract
            dec.b TMP_PLAYER_CHARGE
            dec.b TMP_PLAYER_CHARGE
            bpl +
                stz.b TMP_PLAYER_CHARGE
            +:
            dec.b TMP_CHARGE
            dec.b TMP_CHARGE
            bpl +
                stz.b TMP_CHARGE
            +:
        .ENDR
        @end_slot_{ix}:
        lda.b MAX_CHARGE
        sec
        sbc.b USAGE_CHARGE
        bpl +
            lda #0
        +:
        sta.b MAX_CHARGE
        lda.b PLAYER_CHARGE
        sec
        sbc.b USAGE_CHARGE
        bpl +
            lda #0
        +:
        sta.b PLAYER_CHARGE
    .ENDR
@end_write:
; and now, upload item sprite depending on if we have enough charge
    rep #$30
    ldx.b ITEMPTR
    pea BG1_CHARACTER_BASE_ADDR + $0EE0
    pea 2
    stz.b IS_FULL
    sep #$20
    lda.w playerData.current_active_charge
    cmp.b USAGE_CHARGE
    bcc +
        inc.b IS_FULL
    +:
    lda #$7F
    pha
    rep #$20
    lda.l bankaddr(Item.items) | itemdef_t.sprite_index,X
    and #$00FF
    .MultiplyStatic 32*4
    ldy.b IS_FULL
    beq @not_charge
    @has_charge:
        clc
        adc #loword(spritedata.items_active)
        sta.b $02
        lda #bankbyte(spritedata.items_active)
        sta.b $04
        jmp @end_charge
    @not_charge:
        clc
        adc #loword(spritedata.items)
        sta.b $02
        lda #bankbyte(spritedata.items)
        sta.b $04
    @end_charge:
    .CopyROMToVQueueBin P_DIR, $02, 128
    ldx.w vqueueBinOffset
    phx
    ldy #4
    lda #3
    jsl SpritePaletteOpaqueify_7F
    .REPT 2 INDEX i
        jsl CopySpriteVQueue
        .IF i == 0
            rep #$20
            lda $01,S
            clc
            adc #spritesize(4, 2)
            sta $01,S
            lda $06,S
            clc
            adc #$0100
            sta $06,S
        .ENDIF
    .ENDR
    rep #$20
    pla
    pla
    pla
    sep #$20
    pla
    rtl

; Battery tile map.
; Indexed by: 0MMCCFL0
; MM - max (for this tile) (0, 1, 2)
; CC - charge (0, 1, 2, FULL)
; F  - first
; L  - last
; invalid tiles are shown as coins for easy debugging
BatteryTileMap:
    ; 0 / 0
    .dw $11, $11, $11, $11
    ; 1 / 0 (invalid)
    .dw 1, 1, 1, 1
    ; 2 / 0 (invalid)
    .dw 1, 1, 1, 1
    ; FULL / 0
    .dw 1, 1, 1, 1
    ; 0 / 1
    .dw 1
    .dw deft($54, 6) ; last
    .dw 1
    .dw deft($44, 6) ; single
    ; 1 / 1
    .dw 1
    .dw deft($56, 6) ; last
    .dw 1
    .dw deft($46, 6) ; single
    ; 2 / 1 (invalid)
    .dw 1, 1, 1, 1
    ; FULL / 1
    .dw 1
    .dw deft($57, 6) ; last
    .dw 1
    .dw deft($47, 6) ; single
    ; 0 / 2
    .dw deft($24, 6) ; mid
    .dw deft($34, 6) ; last
    .dw deft($14, 6) ; first
    .dw deft($04, 6) ; single
    ; 1 / 2
    .dw deft($25, 6) ; mid
    .dw deft($35, 6) ; last
    .dw deft($15, 6) ; first
    .dw deft($05, 6) ; single
    ; 2 / 2
    .dw deft($26, 6) ; mid
    .dw deft($36, 6) ; last
    .dw deft($16, 6) ; first
    .dw deft($06, 6) ; single
    ; FULL / 2
    .dw deft($27, 6) ; mid
    .dw deft($37, 6) ; last
    .dw deft($17, 6) ; first
    .dw deft($07, 6) ; single


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
    jsl Item.update_charge_display
    rts

.ENDS