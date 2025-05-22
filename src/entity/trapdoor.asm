.include "base.inc"

.BANK $02 SLOT "ROM"
.SECTION "Entity Trapdoor" SUPERFREE

true_entity_trapdoor_tick:
    ; rtl
    rep #$30
    phy
    lda #0
    ; tile ID
    lda #$20A4
    ldx.w objectIndex
    sta.w objectData.1.tileid,X
    ; X position
    sep #$20
    lda.w entity_posx + 1,Y
    sta.w objectData.1.pos_x,X
    ; Y position
    lda.w entity_posy + 1,Y
    sta.w objectData.1.pos_y,X
    sta.w loword(entity_ysort),Y
    rep #$30
    .SetCurrentObjectS_Inc
    ply
    sep #$20
    lda.w entity_timer,Y
    beq +
        dec A
        sta.w entity_timer,Y
        rtl
    +:
    ; collision detection
    .EntityEasySetBox 16 16
    .EntityEasyCheckNoPlayerCollision_Center @no_player_col, 8, 10
        ; TODO: handle next floor
        jsl Floor_Next
    @no_player_col:
    rtl

.ENDS

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Trapdoor Hooks" FREE

entity_trapdoor_init:
    .ACCU 16
    .INDEX 16
    sep #$20
    lda #60
    sta.w entity_timer,Y
    rep #$20
    rts

entity_trapdoor_free:
    .ACCU 16
    .INDEX 16
    rts

entity_trapdoor_tick:
    .ACCU 16
    .INDEX 16
    pla
    phk
    pha
    jml true_entity_trapdoor_tick

.ENDS
