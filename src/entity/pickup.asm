.include "base.inc"

; steal state and timer, since they are serialized
.define pickup_price entity_state
.define consumable_type entity_timer
.define has_put_text loword(entity_custom.1)
.define pickup_prevention_timer loword(entity_custom.2)
.define anim_timer loword(entity_custom.3)

.BANK $02 SLOT "ROM"
.SECTION "Entity Pickup" SUPERFREE

_variant_sprite_tileflag:
    .dw $0000 ; 0 - null
    .dw $2080 ; 1 - penny
    .dw $2082 ; 2 - nickle
    .dw $2084 ; 3 - dime
    .dw $2088 ; 4 - bomb
    .dw $208E ; 5 - key
    .dw $00A8 ; 6 - battery
    .dw $20AA ; 7 - heart
    .dw $20AC ; 8 - soul heart
    .dw $20A6 ; 9 - consumable (TODO: unique sprites for pills)

_variant_handlers:
    .dw _handle_null       ; 0 - null
    .dw _handle_penny      ; 1 - penny
    .dw _handle_nickle     ; 2 - nickle
    .dw _handle_dime       ; 3 - dime
    .dw _handle_bomb       ; 4 - bomb
    .dw _handle_key        ; 5 - key
    .dw _handle_null       ; 6 - TODO: battery
    .dw _handle_heart      ; 7 - heart
    .dw _handle_soul_heart ; 8 - soul heart
    .dw _handle_consumable ; 9 - consumable

.DEFINE SPAWN_ANIM_FRAMES 14

_spawn_anim_y:
    .db -4, -4, -4, -4, -3, -3, -3, -2, -1, 0, -1, -2, -1, 0

; Note: prices are in DECIMAL MODE
PickupVariantPrices:
    .db $01 ; 0 - null
    .db $01 ; 1 - penny
    .db $05 ; 2 - nickle
    .db $10 ; 3 - dime
    .db $05 ; 4 - bomb
    .db $05 ; 5 - key
    .db $05 ; 6 - battery
    .db $03 ; 7 - heart
    .db $05 ; 8 - soul heart
    .db $05 ; 9 - tarot card

PickupRandomizerTables:
    .dw PickupTable_Shop
    .dw PickupTable_Any
    .dw PickupTable_Coin
    .dw PickupTable_Heart

PickupTable_Shop:
    .ChanceTableBegin 256
    .ChanceTableDW  40, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_BOMB)
    .ChanceTableDW  40, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_KEY)
    .ChanceTableDW  40, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_FULL)
    .ChanceTableDW  40, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_SOUL)
    .ChanceTableDW  40, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_BATTERY)
    .ChanceTableDW  40, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_CONSUMABLE)
    .ChanceTableRestDW  entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_FULL)
    .ChanceTableEnd

PickupTable_Coin:
    .ChanceTableBegin 256
    .ChanceTableDW   5, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_DIME)
    .ChanceTableDW  25, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_NICKEL)
    .ChanceTableRestDW  entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_PENNY)
    .ChanceTableEnd

PickupTable_Heart:
    .ChanceTableBegin 256
    .ChanceTableDW  50, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_SOUL)
    .ChanceTableRestDW  entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_FULL)
    .ChanceTableEnd

PickupTable_Any:
    .ChanceTableBegin 256
    .ChanceTableDW  48, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_PENNY)
    .ChanceTableDW   3, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_NICKEL)
    .ChanceTableDW   1, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_DIME)
    .ChanceTableDW  50, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_BOMB)
    .ChanceTableDW  50, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_KEY)
    .ChanceTableDW  38, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_FULL)
    .ChanceTableDW   5, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_SOUL)
    .ChanceTableDW  10, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_BATTERY)
    .ChanceTableDW  15, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_CONSUMABLE)
    .ChanceTableRestDW  entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_PENNY)
    .ChanceTableEnd

PickupTable_RoomReward:
    .ChanceTableBegin 256
    .ChanceTableDW  48, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_PENNY)
    .ChanceTableDW   3, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_NICKEL)
    .ChanceTableDW   1, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_DIME)
    .ChanceTableDW  50, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_BOMB)
    .ChanceTableDW  50, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_KEY)
    .ChanceTableDW  38, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_FULL)
    .ChanceTableDW   5, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_SOUL)
    .ChanceTableDW  10, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_BATTERY)
    .ChanceTableRestDW 0
    .ChanceTableEnd

_subtract_money:
    phy
    php
    sep #$28
    lda.w pickup_price,Y
    beq @skip
    lda.w playerData.money
    sec
    sbc.w pickup_price,Y
    sta.w playerData.money
    jsl Player.update_money_display
@skip:
    plp
    ply
    rts

_handle_null:
    rts

_handle_penny:
    rep #$30 ; 16b A
    phy
    php
    sep #$08 ; enable decimal
    lda.w playerData.money
    clc
    adc #$01
    sec
    sbc.w pickup_price,Y
    cmp #$99
    bcc +
        lda #$99
    +:
    sta.w playerData.money
    rep #$08 ; disable decimal
    jsl Player.update_money_display
    plp
    ply
    ; KILL
    jsl entity_free
    rts

_handle_nickle:
    rep #$30 ; 16b A
    phy
    php
    sep #$08 ; enable decimal
    lda.w playerData.money
    clc
    adc #$05
    sec
    sbc.w pickup_price,Y
    cmp #$99
    bcc +
        lda #$99
    +:
    sta.w playerData.money
    rep #$08 ; disable decimal
    jsl Player.update_money_display
    plp
    ply
    ; KILL
    jsl entity_free
    rts

_handle_dime:
    rep #$30 ; 16b A
    phy
    php
    sep #$08 ; enable decimal
    lda.w playerData.money
    clc
    adc #$10
    sec
    sbc.w pickup_price,Y
    cmp #$99
    bcc +
        lda #$99
    +:
    sta.w playerData.money
    rep #$08 ; disable decimal
    jsl Player.update_money_display
    plp
    ply
    ; KILL
    jsl entity_free
    rts

_handle_bomb:
    rep #$30 ; 16b A
    phy
    php
    sep #$08 ; enable decimal
    lda.w playerData.bombs
    cmp #$99
    beq @skip_add_bombs
    clc
    adc #$01
@skip_add_bombs:
    sta.w playerData.bombs
    rep #$08 ; disable decimal
    jsl Player.update_bomb_display
    plp
    ply
    jsr _subtract_money
    ; KILL
    jsl entity_free
    rts

_handle_key:
    rep #$30 ; 16b A
    phy
    php
    sep #$08 ; enable decimal
    lda.w playerData.keys
    cmp #$99
    beq @skip_add_keys
    clc
    adc #$01
    sta.w playerData.keys
@skip_add_keys:
    rep #$08 ; disable decimal
    jsl Player.update_key_display
    plp
    ply
    jsr _subtract_money
    ; KILL
    jsl entity_free
    rts

_handle_heart:
    rep #$30
    phy
    php
    sep #$30
    lda #2
    jsl Player.Heal
    cmp #2
    beq +
        ; healed some amount, remove heart
        plp
        ply
        jsr _subtract_money
        jsl entity_free
        rts
    +:
    plp
    ply
    rts

_handle_soul_heart:
    rep #$30
    phy
    php
    sep #$30
    lda #2
    jsl Player.AddSoulHearts
    cmp #2
    beq +
        ; healed some amount, remove heart
        plp
        ply
        jsr _subtract_money
        jsl entity_free
        rts
    +:
    plp
    ply
    rts

_handle_consumable:
    jsr _subtract_money
    sep #$30
    phy
    php
    lda.w consumable_type,Y
    jsl Consumable.pickup
    plp
    ply
    jsl entity_free
    rts

true_entity_pickup_tick:
    rep #$30
    phy
    ldx.w anim_timer,Y
    cpx #SPAWN_ANIM_FRAMES-1
    bcs +
        inx
        txa
        sta.w anim_timer,Y
    +:
    lda.l _spawn_anim_y,X
    sta.b $00
    ; tile ID
    lda.w entity_variant,Y
    and #$00FF
    asl
    tax
    lda.l _variant_sprite_tileflag,X
    ldx.w objectIndex
    sta.w objectData.1.tileid,X
    ; X position
    sep #$20
    lda.w entity_posx + 1,Y
    sta.w objectData.1.pos_x,X
    ; Y position
    lda.w entity_posy + 1,Y
    clc
    adc.b $00
    sta.w objectData.1.pos_y,X
    sta.w loword(entity_ysort),Y
    rep #$30
    .SetCurrentObjectS_Inc
    ply
    ; collision detection
    .EntityEasySetBox 16 16
    lda.w playerData.money
    cmp.w pickup_price,Y
    bcc @skip_pickup
    lda.w pickup_prevention_timer,Y
    beq +
        dec a
        sta.w pickup_prevention_timer,Y
        jmp @skip_pickup
    +:
    .EntityEasyCheckPlayerCollision_Center @skip_pickup, 8, 10
        rep #$30
        lda.w entity_variant,Y
        and #$00FF
        asl
        tax
        jsr (_variant_handlers,X)
    @skip_pickup:
    ; maybe put text
    sep #$30
    lda.w pickup_price,Y
    beq @no_put_price_text
    lda.w has_put_text,Y
    bne @no_put_price_text
        inc A
        sta.w has_put_text,Y
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
        lda.w pickup_price,Y
        and #$00F0
        beq +
            lsr
            lsr
            lsr
            lsr
            ora #deft($70,5) | T_HIGHP
        +:
        sta.l vqueueMiniOps.1.data,X
        lda.w pickup_price,Y
        and #$000F
        ora #deft($70,5) | T_HIGHP
        sta.l vqueueMiniOps.2.data,X
        lda #deft($7A,5) | T_HIGHP
        sta.l vqueueMiniOps.3.data,X
@no_put_price_text:
    rtl

true_entity_pickup_init_spawn:
    .ACCU 16
    .INDEX 16
    sep #$20
    lda #0
    sta.w pickup_price,Y
    sta.w has_put_text,Y
    sta.b $04
    lda.w entity_variant,Y
    cmp #ENTITY_PICKUP_RANDOM_SHOP
    bne +
        inc.b $04
    +:
    lda.w entity_variant,Y
    bpl @no_randomize
        ; get table
        rep #$30
        and #$7F
        asl
        tax
        lda.l PickupRandomizerTables,X
        sta.b $00
        ; get RNG
        jsl RoomRand_Update8
        .ACCU 16
        and #$00FF
        ; get variant
        asl
        clc
        adc.b $00
        tax
        lda.l bankaddr(PickupRandomizerTables),X
        sep #$20
        xba
        sta.w entity_variant,Y
@no_randomize:
    lda #0
    xba
    lda.b $04
    beq @no_set_price
        lda.w entity_variant,Y
        tax
        lda.l PickupVariantPrices,X
        sta.w pickup_price,Y
@no_set_price:
    ; choose consumable type if this is a consumable
    lda.w entity_variant,Y
    cmp #ENTITY_PICKUP_VARIANT_CONSUMABLE
    bne @dont_set_consumable_type
        jsl RoomRand_Update8
        .ACCU 16
        sta.l DIVU_DIVIDEND
        sep #$30
        lda #CONSUMABLE_COUNT-1
        sta.l DIVU_DIVISOR
        .REPT 8
            nop
        .ENDR
        lda.l DIVU_REMAINDER
        inc A
        sta.w consumable_type,Y
@dont_set_consumable_type:
    rep #$30
    lda #30
    sta.w pickup_prevention_timer,Y
    lda #SPAWN_ANIM_FRAMES-1
    ldx.b entitySpawnContext
    cpx #ENTITY_SPAWN_CONTEXT_STANDARD
    bne +
        lda #0
    +:
    sta.w anim_timer,Y
    rtl

true_entity_pickup_init:
    .ACCU 16
    .INDEX 16
    lda.b entitySpawnContext
    cmp #ENTITY_SPAWN_CONTEXT_DESERIALIZE
    beq @deserialized
        jsl true_entity_pickup_init_spawn
@deserialized:
    sep #$20
    lda #0
    sta.w has_put_text,Y
    rep #$30
    lda #30
    sta.w pickup_prevention_timer,Y
    lda #SPAWN_ANIM_FRAMES-1
    ldx.b entitySpawnContext
    cpx #ENTITY_SPAWN_CONTEXT_STANDARD
    bne +
        lda #0
    +:
    sta.w anim_timer,Y
    rtl

true_entity_pickup_free:
    .ACCU 16
    .INDEX 16
    ; maybe erase text
    sep #$30
    lda.w has_put_text,Y
    beq @no_erase_price_text
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
    rtl

.ENDS

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Pickup Hooks" FREE

entity_pickup_init:
    jsl true_entity_pickup_init
    rts

entity_pickup_free:
    jsl true_entity_pickup_free
    rts

entity_pickup_tick:
    .ACCU 16
    .INDEX 16
    pla
    phk
    pha
    jml true_entity_pickup_tick

.ENDS
