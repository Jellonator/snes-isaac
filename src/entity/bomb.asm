.include "base.inc"

.BANK $02 SLOT "ROM"
.SECTION "Entity Bomb" SUPERFREE

.DEFINE BOMB1 $208A
.DEFINE BOMB2 $208C

true_entity_bomb_tick:
    .ACCU 16
    .INDEX 16
    sep #$20
    lda.w entity_timer,Y
    dec A
    sta.w entity_timer,Y
    cmp #0
    bne +
        ; check collision

        ; create splat
        sep #$20
        lda.w entity_posx+1,Y
        sta.b $07
        lda.w entity_posy+1,Y
        clc
        adc #4
        sta.b $06
        phy
        php
        phb
        phy
        .ChangeDataBank $00
        jsl Splat.circle
        rep #$10
        ply
        lda.w entity_posx+1,Y
        sec
        sbc #8
        sta.b $07
        lda.w entity_posy+1,Y
        sec
        sbc #4
        sta.b $06
        jsl Splat.big_circle
        plb
        plp
        ply
        ; create graphic
        phy
        php
        rep #$30
        lda.w entity_posx,Y
        pha
        lda.w entity_posy,Y
        pha
        lda #entityvariant(ENTITY_TYPE_EFFECT, ENTITY_EFFECT_EXPLOSION)
        jsl entity_create
        rep #$30
        pla
        clc
        adc #8*$0100
        sta.w entity_posy,Y
        pla
        clc
        adc #8*$0100
        sta.w entity_posx,Y
        plp
        ply
        jsl entity_free
        rtl
    +:
    ;
    rep #$30
    phy
    ; tile ID
    lda.w entity_timer,Y
    and #$0004
    beq @frame2
        lda #BOMB1
        jmp @frame_end
    @frame2:
        lda #BOMB2
    @frame_end:
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
    rtl

.ENDS

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Bomb Hooks" FREE

entity_bomb_init:
    .ACCU 16
    .INDEX 16
    sep #$20
    lda #120
    sta.w entity_timer,Y
    rep #$30
    rts

entity_bomb_free:
    .ACCU 16
    .INDEX 16
    rts

entity_bomb_tick:
    .ACCU 16
    .INDEX 16
    pla
    phk
    pha
    jml true_entity_bomb_tick

.ENDS
