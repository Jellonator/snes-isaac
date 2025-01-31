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
        ; add money
        ; TODO: add other handling
        sep #$08 ; enable decimal
        rep #$20 ; 16b A
        lda.w playerData.money
        clc
        adc #$01
        sta.w playerData.money
        rep #$08 ; disable decimal
        phy
        php
        jsl Player.update_money_display
        plp
        ply
        ; KILL
        jsl entity_free
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
