.include "base.inc"

.BANK $02 SLOT "ROM"
.SECTION "Entity Bomb" SUPERFREE

.DEFINE BOMB1 $208A
.DEFINE BOMB2 $208C

_bomb_tile_do_nothing:
    .INDEX 16
    .ACCU 16
    rts

_bomb_tile_poop:
    .INDEX 16
    .ACCU 16
    sep #$20 ; 8 bit A
    lda #0
    sta [currentRoomTileVariantTableAddress],Y
    lda #BLOCK_REGULAR
    sta [currentRoomTileTypeTableAddress],Y
    rep #$20 ; 16 bit A
    jsl HandleTileChanged
    ; put splotch
    sep #$20 ; 8 bit A
    tyx
    lda.l RoomTileToXTable,X
    asl
    asl
    asl
    asl
    clc
    adc #32
    sta.b $07
    lda.l RoomTileToYTable,X
    asl
    asl
    asl
    asl
    clc
    adc #64
    sta.b $06
    phy
    php
    jsl Splat.poop1
    plp
    ply
    rts

_bomb_tile_rock:
    .INDEX 16
    .ACCU 16
    sep #$20 ; 8 bit A
    lda #0
    sta [currentRoomTileVariantTableAddress],Y
    lda #BLOCK_REGULAR
    sta [currentRoomTileTypeTableAddress],Y
    rep #$20 ; 16 bit A
    jsl HandleTileChanged
    ; TODO: check for tinted rock
    rts

_ExplosionTileHandlerTable:
.REPT 256 INDEX i
    .IF i == BLOCK_POOP
        .dw _bomb_tile_poop
    .ELIF i == BLOCK_ROCK
        .dw _bomb_tile_rock
    .ELIF i == BLOCK_ROCK_TINTED
        .dw _bomb_tile_rock
    .ELSE
        .dw _bomb_tile_do_nothing
    .ENDIF
.ENDR

true_entity_bomb_tick:
    .DEFINE Y_STORE $10
    .DEFINE TILE $12
    .ACCU 16
    .INDEX 16
    sep #$20
    lda.w entity_timer,Y
    dec A
    sta.w entity_timer,Y
    cmp #0
    bnel +
        sty.b Y_STORE
        ; check collision
        lda.w entity_posy+1,Y
        sec
        sbc #8
        and #$F0
        sta.b TILE
        lda.w entity_posx+1,Y
        sec
        sbc #8
        .DivideStatic 16
        ora.b TILE
        sta.b TILE
        stz.b TILE+1
        rep #$30
        ldx.b TILE
        .REPT 3 INDEX iy
            .REPT 3 INDEX ix
                lda.l GameTileToRoomTileIndexTable,X
                and #$00FF
                tay
                lda [currentRoomTileTypeTableAddress],Y
                and #$00FF
                asl
                tax
                jsr (_ExplosionTileHandlerTable,X)
                rep #$30
                .IF (ix < 2) && (iy < 2)
                    inc.b TILE
                    ldx.b TILE
                .ELIF (ix == 2) && (iy < 2)
                    lda.b TILE
                    clc
                    adc #16-2
                    sta.b TILE
                    tax
                .ELIF (ix < 2) && (iy == 2)
                    inc.b TILE
                    ldx.b TILE
                .ENDIF
            .ENDR
        .ENDR
        ldy.b Y_STORE
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
    .UNDEFINE Y_STORE
    .UNDEFINE TILE

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
