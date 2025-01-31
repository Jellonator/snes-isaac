.include "base.inc"

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
    clc
    adc #$01
    sta.w playerData.bombs
    rep #$08 ; disable decimal
    jsl Player.update_bomb_display
    plp
    ply
    ; KILL
    jsl entity_free
    rts

_handle_key:
    rep #$30 ; 16b A
    phy
    php
    sep #$08 ; enable decimal
    lda.w playerData.keys
    clc
    adc #$01
    sta.w playerData.keys
    rep #$08 ; disable decimal
    jsl Player.update_key_display
    plp
    ply
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
        jsl entity_free
        rts
    +:
    plp
    ply
    rts

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

true_entity_pickup_tick:
    ; rtl
    rep #$30
    phy
    lda #0
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
    sta.w objectData.1.pos_y,X
    sta.w entity_ysort,Y
    rep #$30
    .SetCurrentObjectS_Inc
    ply
    ; collision detection
    .EntityEasySetBox 16 16
    .EntityEasyCheckPlayerCollision_Center @no_player_col, 8, 10
        rep #$30
        lda.w entity_variant,Y
        and #$00FF
        asl
        tax
        jsr (_variant_handlers,X)
    @no_player_col:
    rtl

PickupSpawnTable:
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
.ENDS

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Pickup Hooks" FREE

entity_pickup_init:
    .ACCU 16
    .INDEX 16
    rts

entity_pickup_free:
    .ACCU 16
    .INDEX 16
    rts

entity_pickup_tick:
    .ACCU 16
    .INDEX 16
    pla
    phk
    pha
    jml true_entity_pickup_tick

.ENDS
