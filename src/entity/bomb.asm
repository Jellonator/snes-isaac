.include "base.inc"

.BANK $02 SLOT "ROM"
.SECTION "Entity Bomb" SUPERFREE

.DEFINE BOMB1 $208A
.DEFINE BOMB2 $208C

.DEFINE EXPLOSION_LEFT -8
.DEFINE EXPLOSION_RIGHT 24
.DEFINE EXPLOSION_TOP -8
.DEFINE EXPLOSION_BOTTOM 24

.DEFINE EXPLOSION_DAMAGE 100

.DEFINE DOOR_OPEN_RADIUS 24

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
    lda #BLOCK_REGULAR_VARIANT_RUBBLE
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
    .DEFINE TOP $14
    .DEFINE LEFT $16
    .DEFINE RIGHT $18
    .DEFINE BOTTOM $1A
    .ACCU 16
    .INDEX 16
    sep #$20
    lda.w entity_timer,Y
    dec A
    sta.w entity_timer,Y
    cmp #0
    bnel @timer_continue
        sty.b Y_STORE
        ; put positions
        lda.w entity_posy+1,Y
        clc
        adc #EXPLOSION_TOP
        sta.b TOP
        lda.w entity_posx+1,Y
        clc
        adc #EXPLOSION_LEFT
        sta.b LEFT
        lda.w entity_posx+1,Y
        clc
        adc #EXPLOSION_RIGHT
        sta.b RIGHT
        lda.w entity_posy+1,Y
        clc
        adc #EXPLOSION_BOTTOM
        sta.b BOTTOM
        ; open doors
        .REPT 4 INDEX i
            lda [MAP_DOOR_MEM_LOC(i)]
            cmp #DOOR_METHOD_FINISH_ROOM | DOOR_CLOSED | DOOR_TYPE_NORMAL
            beq @try_door_{i}
            and #DOOR_MASK_STATUS
            cmp #DOOR_METHOD_BOMB | DOOR_CLOSED
            beq @try_door_{i}
            jmp @skip_door_{i}
        @try_door_{i}:
            .IF i == 0 ; NORTH
                lda.w entity_posy+1,Y
                cmp #ROOM_TOP - 8 + DOOR_OPEN_RADIUS
                bgru @skip_door_{i}
            .ELIF i == 1 ; EAST
                lda.w entity_posx+1,Y
                cmp #ROOM_RIGHT - 8 - DOOR_OPEN_RADIUS
                blsu @skip_door_{i}
            .ELIF i == 2 ; SOUTH
                lda.w entity_posy+1,Y
                cmp #ROOM_BOTTOM - 8 - DOOR_OPEN_RADIUS
                blsu @skip_door_{i}
            .ELIF i == 3 ; WEST
                lda.w entity_posx+1,Y
                cmp #ROOM_LEFT - 8 + DOOR_OPEN_RADIUS
                bgru @skip_door_{i}
            .ENDIF
            .IF i == 0 || i == 2 ; VERTICAL
                lda.w entity_posx+1,Y
                cmp #ROOM_CENTER_X - 8 - DOOR_OPEN_RADIUS
                bleu @skip_door_{i}
                cmp #ROOM_CENTER_X - 8 + DOOR_OPEN_RADIUS
                bgru @skip_door_{i}
            .ELIF i == 1 || i == 3 ; HORIZONTAL
                lda.w entity_posy+1,Y
                cmp #ROOM_CENTER_Y - 8 - DOOR_OPEN_RADIUS
                bleu @skip_door_{i}
                cmp #ROOM_CENTER_Y - 8 + DOOR_OPEN_RADIUS
                bgru @skip_door_{i}
            .ENDIF
            ; open door
            lda [MAP_DOOR_MEM_LOC(i)]
            ora #DOOR_OPEN
            sta [MAP_DOOR_MEM_LOC(i)]
            ; update tile
            phy
            phb
            .ChangeDataBank $00
            .IF i == 0 ; NORTH
                jsl UpdateDoorTileNorth
            .ELIF i == 1 ; EAST
                jsl UpdateDoorTileEast
            .ELIF i == 2 ; SOUTH
                jsl UpdateDoorTileSouth
            .ELIF i == 3 ; WEST
                jsl UpdateDoorTileWest
            .ENDIF
            plb
            rep #$10
            sep #$20
            ply
            @skip_door_{i}:
        .ENDR
        ; get tile
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
        ; check collisions
        rep #$30
        ldx.b TILE
        .REPT 3 INDEX iy
            .REPT 3 INDEX ix
                ; handle entities
                sep #$30
                .REPT SPATIAL_LAYER_COUNT INDEX i
                    ldy.w spatial_partition.{i+1},X
                    beql @no_ent_{ix}_{iy} ; no entities found; skip
                    lda.w entity_mask,Y
                    and #ENTITY_MASK_BOMBABLE & $FF
                    beq @skip_ent_{ix}_{iy}_{i}
                        lda.b RIGHT
                        cmp.w entity_box_x1,Y
                        bcc @skip_ent_{ix}_{iy}_{i}
                        lda.b LEFT
                        cmp.w entity_box_x2,Y
                        bcs @skip_ent_{ix}_{iy}_{i}
                        lda.b BOTTOM
                        cmp.w entity_box_y1,Y
                        bcc @skip_ent_{ix}_{iy}_{i}
                        lda.b TOP
                        cmp.w entity_box_y2,Y
                        bcs @skip_ent_{ix}_{iy}_{i}
                            rep #$20
                            lda.w entity_health,Y
                            sec
                            sbc #EXPLOSION_DAMAGE
                            sta.w entity_health,Y
                            php
                            sep #$20
                            lda.w entity_signal,Y
                            plp
                            ora #ENTITY_SIGNAL_DAMAGE
                            bcs @skip_kill_{ix}_{iy}_{i}
                                ora #ENTITY_SIGNAL_KILL
                            @skip_kill_{ix}_{iy}_{i}:
                            sta.w entity_signal,Y
                            lda.w entity_mask,Y
                            and #$FF ~ ENTITY_MASK_BOMBABLE
                            sta.w entity_mask,Y
                            lda #ENTITY_FLASH_TIME
                            sta.w loword(entity_damageflash),Y
                    @skip_ent_{ix}_{iy}_{i}:
                .ENDR
                @no_ent_{ix}_{iy}:
                rep #$30
                ; handle tile
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
        phb
        .ChangeDataBank $00
        jsl Splat.explode_small
        rep #$10
        ldy.b Y_STORE
        lda.w entity_posx+1,Y
        sec
        sbc #8
        sta.b $07
        lda.w entity_posy+1,Y
        sec
        sbc #4
        sta.b $06
        jsl Splat.explode_big
        plb
        ; create graphic
        rep #$30
        ldy.b Y_STORE
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
        rep #$30
        ldy.b Y_STORE
        jsl entity_free
        rtl
    @timer_continue:
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
    sta.w loword(entity_ysort),Y
    rep #$30
    .SetCurrentObjectS_Inc
    ply
    rtl
    .UNDEFINE Y_STORE
    .UNDEFINE TILE
    .UNDEFINE TOP
    .UNDEFINE LEFT
    .UNDEFINE RIGHT
    .UNDEFINE BOTTOM

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
