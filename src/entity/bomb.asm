.include "base.inc"

.BANK $00 SLOT "ROM"
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
    .SoftSetX 16
    .SoftSetA 16
    rts

_bomb_tile_poop:
    .SoftSetX 16
    .SoftSetA 16
    .ForceSetA 8
    lda #0
    sta [currentRoomTileVariantTableAddress],Y
    lda #BLOCK_REGULAR
    sta [currentRoomTileTypeTableAddress],Y
    .ForceSetA 16
    jsl HandleTileChanged
    ; put splotch
    .ForceSetA 8
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
    .SoftSetX 16
    .SoftSetA 16
    .ForceSetA 8
    lda #BLOCK_REGULAR_VARIANT_RUBBLE
    sta [currentRoomTileVariantTableAddress],Y
    lda #BLOCK_REGULAR
    sta [currentRoomTileTypeTableAddress],Y
    .ForceSetA 16
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

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefinel "true_entity_bomb_tick"
    .DEFINE Y_STORE $10
    .DEFINE TILE $12
    .DEFINE TOP $14
    .DEFINE LEFT $16
    .DEFINE RIGHT $18
    .DEFINE BOTTOM $1A
    .ForceSetA 8
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
            .ChangeDataBank $80
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
            .ForceSetX 16
            .ForceSetA 8
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
        .ForceSetAX 16, 16
        ldx.b TILE
        .REPT 3 INDEX iy
            .REPT 3 INDEX ix
                ; handle entities
                .ForceSetAX 8, 8
                .REPT SPATIAL_LAYER_COUNT INDEX i
                    ldy.w spatial_partition.{i+1},X
                    beql @no_ent_{ix}_{iy} ; no entities found; skip
                    lda.w entity_mask,Y
                    and #ENTITY_MASK_BOMBABLE & $FF
                    beql @skip_ent_{ix}_{iy}_{i}
                        lda.b RIGHT
                        cmp.w entity_box_x1,Y
                        bccl @skip_ent_{ix}_{iy}_{i}
                        lda.b LEFT
                        cmp.w entity_box_x2,Y
                        bcsl @skip_ent_{ix}_{iy}_{i}
                        lda.b BOTTOM
                        cmp.w entity_box_y1,Y
                        bccl @skip_ent_{ix}_{iy}_{i}
                        lda.b TOP
                        cmp.w entity_box_y2,Y
                        bcsl @skip_ent_{ix}_{iy}_{i}
                            ; decrease health
                            .ForceSetA 16
                            lda.w entity_health,Y
                            sec
                            sbc #EXPLOSION_DAMAGE
                            sta.w entity_health,Y
                            ; set signal
                            .ForceSetA 8
                            php
                            lda.w entity_signal,Y
                            plp
                            ora #ENTITY_SIGNAL_DAMAGE | ENTITY_SIGNAL_BOMBED | ENTITY_SIGNAL_DOUBLEDAMAGE
                            bcs @skip_kill_{ix}_{iy}_{i}
                                ora #ENTITY_SIGNAL_KILL
                            @skip_kill_{ix}_{iy}_{i}:
                            sta.w entity_signal,Y
                            ; clear bombable from mask (to prevent double hits)
                            lda.w entity_mask,Y
                            and #$FF ~ ENTITY_MASK_BOMBABLE
                            sta.w entity_mask,Y
                            ; set entity flash
                            lda #ENTITY_FLASH_TIME
                            sta.w loword(entity_damageflash),Y
                            ; apply velocity
                            ldx.b Y_STORE
                            .call "Entity.DirectTargetEntity"
                            .ASSERT (D_FLAG_A == 8) && (D_FLAG_X == 8)
                            lda.b entityTargetAngle
                            clc
                            adc #128
                            tax
                            lda.l SinTable8,X
                            .Convert8To16_SIGNED FALSE, FALSE
                            .ShiftLeft_SIGN 2
                            clc
                            adc.w entity_velocy,Y
                            sta.w entity_velocy,Y
                            .SetA 8
                            lda.l CosTable8,X
                            .Convert8To16_SIGNED FALSE, FALSE
                            .ShiftLeft_SIGN 2
                            clc
                            adc.w entity_velocx,Y
                            sta.w entity_velocx,Y
                            ; load tile into X register again
                            ldx.b TILE
                            .SetA 8
                    @skip_ent_{ix}_{iy}_{i}:
                .ENDR
                @no_ent_{ix}_{iy}:
                .ForceSetAX 16, 16
                ; handle tile
                lda.l GameTileToRoomTileIndexTable,X
                and #$00FF
                tay
                lda [currentRoomTileTypeTableAddress],Y
                and #$00FF
                asl
                tax
                jsr (_ExplosionTileHandlerTable,X)
                .ForceSetAX 16, 16
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
        .ForceSetA 8
        lda.w entity_posx+1,Y
        sta.b $07
        lda.w entity_posy+1,Y
        clc
        adc #4
        sta.b $06
        phb
        .ChangeDataBank $80
        jsl Splat.explode_small
        .ForceSetX 16
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
        .ForceSetAX 16, 16
        ldy.b Y_STORE
        lda.w entity_posx,Y
        pha
        lda.w entity_posy,Y
        pha
        lda #entityvariant(ENTITY_TYPE_EFFECT, ENTITY_EFFECT_EXPLOSION)
        .call "Entity.CreateAndInit"
        .ForceSetAX 16, 16
        pla
        clc
        adc #8*$0100
        sta.w entity_posy,Y
        pla
        clc
        adc #8*$0100
        sta.w entity_posx,Y
        .ForceSetAX 16, 16
        ldy.b Y_STORE
        .call "Entity.Free"
        rtl
    @timer_continue:
; perform movement
    .ForceSetAX 16, 16
    lda.w entity_velocx,Y
    ora.w entity_velocy,Y
    beq @skip_movement
        .SetAX 8, 8
        lda #4
        sta.b $00
        sta.b $01
        .call "Entity.MoveAndCollide"
        .SetAX 16, 16
        lda.w entity_velocx,Y
        .ShiftRight_SIGN 4, FALSE
        bne @continue_friction_x
            sta.w entity_velocx,Y
            jmp @end_friction_x
    @continue_friction_x:
        sta.b $00
        lda.w entity_velocx,Y
        sec
        sbc.b $00
        sta.w entity_velocx,Y
    @end_friction_x:
        lda.w entity_velocy,Y
        .ShiftRight_SIGN 4, FALSE
        bne @continue_friction_y
            sta.w entity_velocy,Y
            jmp @end_friction_y
    @continue_friction_y:
        sta.b $00
        lda.w entity_velocy,Y
        sec
        sbc.b $00
        sta.w entity_velocy,Y
    @end_friction_y:
@skip_movement:
    .SetAX 16, 16
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
    .ForceSetA 8
    lda.w entity_box_x1,Y
    sec
    sbc #4
    sta.w objectData.1.pos_x,X
    clc
    adc #12
    sta.w entity_box_x2,Y
    ; Y position
    lda.w entity_box_y1,Y
    sec
    sbc #6
    sta.w objectData.1.pos_y,X
    clc
    adc #10
    sta.w loword(entity_ysort),Y
    adc #4
    sta.w entity_box_y2,Y
    .ForceSetAX 16, 16
    .SetCurrentObjectS_Inc
    ply
    ; set mask
    .SetAX 8, 8
    lda #ENTITY_MASK_TEAR
    sta.w loword(entity_mask),Y
    lda #0
    sta.w entity_signal,Y
    rtl
    .UNDEFINE Y_STORE
    .UNDEFINE TILE
    .UNDEFINE TOP
    .UNDEFINE LEFT
    .UNDEFINE RIGHT
    .UNDEFINE BOTTOM
.endproc

.ENDS

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Bomb Hooks" FREE

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "entity_bomb_init", "IEntityInit"
    .ForceSetA 8
    lda #120
    sta.w entity_timer,Y
    lda.w entity_box_x1,Y
    sec
    sbc #4
    sta.w entity_box_x1,Y
    lda.w entity_box_y1,Y
    sbc #4
    sta.w entity_box_y1,Y
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "entity_bomb_free", "IEntityFree"
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "entity_bomb_tick"
    .call "true_entity_bomb_tick"
    rts
.endproc

.ENDS
