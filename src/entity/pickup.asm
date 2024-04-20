.include "base.inc"

.BANK $02 SLOT "ROM"
.SECTION "Entity Pickup" SUPERFREE

_variant_sprite_tileflag:
    .dw $0000 ; 0 - null
    .dw $2080 ; 1 - penny
    .dw $2080 ; 2 - nickle
    .dw $2080 ; 3 - dime
    .dw $2084 ; 4 - bomb
    .dw $2082 ; 5 - key

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
    rep #$30
    .SetCurrentObjectS
    ldx.w objectIndex
    inx
    inx
    inx
    inx
    stx.w objectIndex
    ply
    ; collision detection
    .EntityEasySetBox 16 16
    .EntityEasyCheckPlayerCollision_Center @no_player_col, 8, 10
        ; KILL
        jsl entity_free
    @no_player_col:
    rtl

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
