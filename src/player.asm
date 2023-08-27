.include "base.inc"

.DEFINE TempTileX $08
.DEFINE TempTileY $0A
.DEFINE TempTileX2 $0C
.DEFINE TempTileY2 $0E
.DEFINE TempTemp1 $14
.DEFINE TempTemp2 $16

.MACRO .PositionToIndex_A
    xba
    and #$00F0
    lsr
    lsr
    lsr
    lsr
.ENDM

.MACRO .IndexToPosition_A
    asl
    asl
    asl
    asl
    xba
.ENDM

.BANK $01 SLOT "ROM"
.SECTION "Player" FREE

_PlayerNextHealthValueTable:
    .db HEALTH_NULL           ; null
    .db HEALTH_REDHEART_EMPTY ; red empty
    .db HEALTH_REDHEART_EMPTY ; red half
    .db HEALTH_REDHEART_HALF  ; red full
    .db HEALTH_NULL           ; spirit half
    .db HEALTH_SOULHEART_HALF ; spirit full
    .db HEALTH_NULL           ; eternal

_PlayerHealthTileValueTable:
    .dw $0000 ; null
    .dw $2832 ; red empty
    .dw $2831 ; red half
    .dw $2830 ; red full
    .dw $2C33 ; spirit half
    .dw $2C30 ; spirit full
    .dw $0000 ; eternal

; Render heart at slot Y
_PlayerRenderSingleHeart:
    rep #$30 ; 16B AXY
    ; Init vqueue
    lda.w vqueueNumMiniOps
    asl
    asl
    tax
    inc.w vqueueNumMiniOps
    ; first, determine offset
    tya
    and #$0007 ; 8 per line
    sta.b $00
    tya
    and #$00F8 ; x8
    asl      ; x16
    asl      ; x32
    ora.b $00 ; X|Y
    sta.b $00
    clc
    adc #BG1_TILE_BASE_ADDR + 8 + 64
    sta.l vqueueMiniOps.1.vramAddr,X
    ; now, determine character
    lda.w playerData.healthSlots,Y
    and #$00FF
    asl
    phx
    tax
    lda.l _PlayerHealthTileValueTable,X
    plx
    sta.l vqueueMiniOps.1.data,X
    rtl

_PlayerRenderAllHearts:
    sep #$30
    ldy #HEALTHSLOT_COUNT-1
    @loop:
        phy
        php
        jsl _PlayerRenderSingleHeart
        plp
        ply
    dey
    bpl @loop
    rtl

_PlayerTakeHealth:
    ; check health slots
    sep #$30
    ldy #HEALTHSLOT_COUNT-1
    @loop:
        lda.w playerData.healthSlots,Y
        cmp #HEALTH_REDHEART_HALF
        bcs @foundHealth
    dey
    bpl @loop
; player has died; eventually handle
@died:
    rtl
@foundHealth:
; found health slot; Y is slot, A is value
    ; health[Y] = NextHealthValue[A]
    tax
    lda.l _PlayerNextHealthValueTable,X
    sta.w playerData.healthSlots,Y
    ; update UI
    phy
    php
    jsl _PlayerRenderSingleHeart
    plp
    ply
    ; if last slot and new value is empty: kill
    cpy #0
    bne +
        cmp #HEALTH_REDHEART_HALF
        bcc @died
    +
    ; set invuln timer
    rep #$30
    lda #60 ; 1 second
    sta.w playerData.invuln_timer
    rtl

_PlayerHandleDamaged:
    lda.w playerData.invuln_timer
    bne +
        jsl _PlayerTakeHealth
    +:
    rtl

PlayerInit:
    rep #$20 ; 16 bit A
    stz.w joy1held
    stz.w joy1press
    stz.w joy1raw
    lda #24
    sta.w playerData.stat_accel
    lda #128*3
    sta.w playerData.stat_speed
    lda #24
    sta.w playerData.stat_tear_delay
    lda #$0100
    sta.w playerData.stat_tear_speed
    lda #0
    sta.w player_velocx
    sta.w player_velocy
    stz.w player_damageflag
    lda #((32 + 6 * 16 - 8) * 256)
    sta.w player_posx
    lda #((64 + 4 * 16 - 8) * 256)
    sta.w player_posy
    stz.w projectile_count_2x
    ; setup HP
    .REPT HEALTHSLOT_COUNT INDEX i
        stz.w playerData.healthSlots + (i * 2)
    .ENDR
    stz.w playerData.invuln_timer
    sep #$30
    lda #HEALTH_REDHEART_FULL
    sta.w playerData.healthSlots.1
    sta.w playerData.healthSlots.2
    sta.w playerData.healthSlots.3
    jsl _PlayerRenderAllHearts
    rts

PlayerUpdate:
; check hp
    rep #$30 ; 16 bit AXY
    lda.w player_damageflag
    bpl +
        jsl _PlayerHandleDamaged
    +:
    rep #$30
    stz.w player_damageflag
    dec.w playerData.invuln_timer
    bpl +
        stz.w playerData.invuln_timer
    +:

; movement
    rep #$30 ; 16 bit AXY
    lda.w playerData.stat_speed
    sta $00
    ; check (LEFT OR RIGHT) AND (UP OR DOWN)
    ; if so, multiply speed by 3/4; aka (A+A+A) >> 2
    lda.w joy1held
    ; LEFT or RIGHT. 00 = F; 01,10,11 = T
    bit #$0C00
    beq @skip_slow
    bit #$0300
    beq @skip_slow
    lda.w playerData.stat_speed
    asl
    clc
    adc $00
    lsr
    lsr
    sta $00
@skip_slow:

    ldx.w player_velocy
    lda.w joy1held
    bit #JOY_DOWN
    bne @down
    bit #JOY_UP
    bne @up
    txa
    cmp #0
    bpl @slowup ; If speed.y > 0

    ; slowright
    clc
    adc.w playerData.stat_accel
    .AMIN #$00
    jmp @endy
@slowup:
    ; slowleft
    sec
    sbc.w playerData.stat_accel
    .AMAX #$00
    jmp @endy
@down:
    ; right
    txa
    clc
    adc.w playerData.stat_accel
    .AMIN $00
    jmp @endy
@up:
    ; left
    txa
    sec
    sbc.w playerData.stat_accel
    eor #$FFFF
    inc A
    .AMIN $00
    eor #$FFFF
    inc A
@endy:
    sta.w player_velocy
    
    ldx.w player_velocx
    lda.w joy1held
    bit #JOY_RIGHT
    bne @right
    bit #JOY_LEFT
    bne @left
    ; X stop
    txa
    cmp #0
    bpl @slowleft ; If speed.x > 0

    ; slowright
    clc
    adc.w playerData.stat_accel
    .AMIN #$00
    jmp @endx
@slowleft:
    ; slowleft
    sec
    sbc.w playerData.stat_accel
    .AMAX #$00
    jmp @endx
@right:
    ; right
    txa
    clc
    adc.w playerData.stat_accel
    .AMIN $00
    jmp @endx
@left:
    ; left
    txa
    sec
    sbc.w playerData.stat_accel
    eor #$FFFF
    inc A
    .AMIN $00
    eor #$FFFF
    inc A
@endx:
    sta.w player_velocx

.DEFINE TempLimitLeft $00
.DEFINE TempLimitRight $02
.DEFINE TempLimitTop $04
.DEFINE TempLimitBottom $06
    ldx #(ROOM_LEFT - 4)*256
    ldy #(ROOM_RIGHT - 12)*256 - 1
    stx $00 ; left
    sty $02 ; right
    lda.w player_posy
    cmp #(ROOM_CENTER_Y - 8 - ROOM_DOOR_RADIUS)*256
    bmi ++
    cmp #(ROOM_CENTER_Y - 8 + ROOM_DOOR_RADIUS)*256
    bpl ++
    ldx #(ROOM_LEFT - 4 - 16)*256
    ldy #(ROOM_RIGHT - 12 + 16)*256
    sep #$20
    lda [mapDoorWest]
    bpl +
        stx $00 ; left
    +:
    lda [mapDoorEast]
    bpl +
        sty $02 ; right
    +:
    rep #$20
++:

    ldx #(ROOM_TOP - 4)*256
    ldy #(ROOM_BOTTOM - 12)*256
    stx $04 ; top
    sty $06 ; bottom
    lda.w player_posx
    cmp #(ROOM_CENTER_X - 8 - ROOM_DOOR_RADIUS)*256
    bmi ++
    cmp #(ROOM_CENTER_X - 8 + ROOM_DOOR_RADIUS)*256
    bpl ++
    ldx #(ROOM_TOP - 4 - 16)*256
    ldy #(ROOM_BOTTOM - 12 + 16)*256
    sep #$20
    lda [mapDoorNorth]
    bpl +
        stx $04 ; top
    +:
    lda [mapDoorSouth]
    bpl +
        sty $06 ; bottom
    +:
    rep #$20
++:

    lda.w player_posx
    cmp #(ROOM_LEFT - 4)*256
    bcc +
    cmp #(ROOM_RIGHT - 12 + 1)*256
    bcs +
    bra ++
+:
    ldx #(ROOM_CENTER_Y - 8 - ROOM_DOOR_RADIUS)*256
    ldy #(ROOM_CENTER_Y - 8 + ROOM_DOOR_RADIUS - 1)*256
    stx $04 ; top
    sty $06 ; bottom
++:

    lda.w player_posy
    cmp #(ROOM_TOP - 4)*256
    bcc +
    cmp #(ROOM_BOTTOM - 12 + 1)*256
    bcs +
    bra ++
+:
    ldx #(ROOM_CENTER_X - 8 - ROOM_DOOR_RADIUS)*256
    ldy #(ROOM_CENTER_X - 8 + ROOM_DOOR_RADIUS - 1)*256
    stx $00 ; left
    sty $02 ; right
++:

    ; move
    jsr PlayerMoveHorizontal
    jsr PlayerMoveVertical
; handle player shoot
    rep #$30 ; 16b AXY
    lda.w playerData.tear_timer
    cmp.w playerData.stat_tear_delay ; if tear_timer < stat_tear_delay: ++tear_timer
    bcc @tear_not_ready
    ; check inputs
    lda.w joy1held
    bit #(JOY_A|JOY_B|JOY_Y|JOY_X)
    beq @end_tear_code
    jsr PlayerShootTear
    jmp @end_tear_code
@tear_not_ready:
    inc A
    sta.w playerData.tear_timer
@end_tear_code:
    sep #$30 ; 8 bit AXY
    ; update render data
    lda.w playerData.invuln_timer
    bit #$08
    bne @invis_frame
    lda.w player_posx+1
    sta.w objectData.1.pos_x
    sta.w objectData.2.pos_x
    lda.w player_posy+1
    sta.w objectData.2.pos_y
    sec
    sbc #10
    sta.w objectData.1.pos_y
    stz.w objectData.1.tileid
    lda #$02
    sta.w objectData.2.tileid
    lda #%00101000
    sta.w objectData.1.flags
    sta.w objectData.2.flags
    rep #$30 ; 16 bit AXY
    .SetCurrentObjectS
    .IncrementObjectIndex
    .SetCurrentObjectS
    .IncrementObjectIndex
@invis_frame:
    rts

PlayerShootTear:
    rep #$30 ; 16 bit AXY
    jsl projectile_slot_get
    lda.w playerData.flags
    eor #PLAYER_FLAG_EYE
    sta.w playerData.flags
    lda #120
    sta.w projectile_lifetime,X
    stz.w projectile_size,X
    lda #$0000
    sta.w playerData.tear_timer
    lda.w joy1held
    bit #JOY_Y
    bne @tear_left
    bit #JOY_A
    bne @tear_right
    bit #JOY_B
    bne @tear_down
;tear_up:
    lda.w player_velocx
    sta.w projectile_velocx,X
    lda.w player_velocy
    .ShiftRight_SIGN 1, FALSE
    .AMIN #32
    .AMAX #-64
    sec
    sbc.w playerData.stat_tear_speed
    sta.w projectile_velocy,X
    jmp @vertical
@tear_left:
    lda.w player_velocy
    sta.w projectile_velocy,X
    lda.w player_velocx
    .ShiftRight_SIGN 1, FALSE
    .AMIN #32
    .AMAX #-64
    sec
    sbc.w playerData.stat_tear_speed
    sta.w projectile_velocx,X
    jmp @horizontal
@tear_right:
    lda.w player_velocy
    sta.w projectile_velocy,X
    lda.w player_velocx
    .ShiftRight_SIGN 1, FALSE
    .AMAX #-32
    .AMAX #64
    clc
    adc.w playerData.stat_tear_speed
    sta.w projectile_velocx,X
    jmp @horizontal
@tear_down:
    lda.w player_velocx
    sta.w projectile_velocx,X
    lda.w player_velocy
    .ShiftRight_SIGN 1, FALSE
    .AMAX #-32
    .AMAX #64
    clc
    adc.w playerData.stat_tear_speed
    sta.w projectile_velocy,X
    jmp @vertical
@vertical:
    lda.w playerData.flags
    bit #PLAYER_FLAG_EYE
    bne @vertical_skip
    lda.w player_posx
    sta.w projectile_posx,X
    lda.w player_posy
    clc
    adc #256*4
    sta.w projectile_posy,X
    rts
@vertical_skip:
    lda.w player_posx
    clc
    adc #256*8
    sta.w projectile_posx,X
    lda.w player_posy
    clc
    adc #256*4
    sta.w projectile_posy,X
    rts
@horizontal:
    lda.w playerData.flags
    bit #PLAYER_FLAG_EYE
    bne @horizontal_skip
    lda.w player_posx
    clc
    adc #256*4
    sta.w projectile_posx,X
    lda.w player_posy
    sta.w projectile_posy,X
    rts
@horizontal_skip:
    lda.w player_posx
    clc
    adc #256*4
    sta.w projectile_posx,X
    lda.w player_posy
    clc
    adc.w #256*8
    sta.w projectile_posy,X
    rts

PlayerMoveHorizontal:
    .ACCU 16
    .INDEX 16
    lda.w player_velocx
    beq @skipmove
    clc
    adc.w player_posx
    .AMAXU $00
    .AMINU $02
    sta.w player_posx
    lda.w player_velocx
    cmp #0
    bmi PlayerMoveLeft
    jmp PlayerMoveRight
@skipmove:
    rts

PlayerMoveLeft:
    .ACCU 16
    .INDEX 16
; Get Tile X from player left
    lda.w player_posx
    clc
    adc #(PLAYER_HITBOX_LEFT - ROOM_LEFT)*256
    .PositionToIndex_A
    sta TempTileX
; Get Tile Y (top)
    lda.w player_posy
    clc
    adc #(PLAYER_HITBOX_TOP - ROOM_TOP)*256
    .PositionToIndex_A
    sta.b TempTileY
; Get Tile Y (bottom)
    lda.w player_posy
    clc
    adc #(PLAYER_HITBOX_BOTTOM - ROOM_TOP)*256
    .PositionToIndex_A
    sta.b TempTileY2
; Get Tile Index
    .BranchIfTileXYOOB TempTileX, TempTileY, @end
    .TileXYToIndexA TempTileX, TempTileY, TempTemp1
    tay
    .TileXYToIndexA TempTileX, TempTileY2, TempTemp2
    tax
; Determine if tile is solid
    sep #$20
    lda [currentRoomTileTypeTableAddress],Y ; top
    txy
    ora [currentRoomTileTypeTableAddress],y ; bottom
    rep #$20
    bpl @end
; get position that player would be when flush against wall
    lda TempTileX
    .IndexToPosition_A
    clc
    adc #(ROOM_LEFT + 16 - PLAYER_HITBOX_LEFT)*256
; apply position
    .AMAXU player_posx
    sta.w player_posx
@end:
    rts

PlayerMoveRight:
    .ACCU 16
    .INDEX 16
; Get Tile X from player left
    lda.w player_posx
    clc
    adc #(PLAYER_HITBOX_RIGHT - ROOM_LEFT)*256-1
    .PositionToIndex_A
    sta.b TempTileX
; Get Tile Y (top)
    lda.w player_posy
    clc
    adc #(PLAYER_HITBOX_TOP - ROOM_TOP)*256
    .PositionToIndex_A
    sta.b TempTileY
; Get Tile Y (bottom)
    lda.w player_posy
    clc
    adc #(PLAYER_HITBOX_BOTTOM - ROOM_TOP)*256
    .PositionToIndex_A
    sta.b TempTileY2
; Get Tile Index
    .BranchIfTileXYOOB TempTileX, TempTileY, @end
    .TileXYToIndexA TempTileX, TempTileY, TempTemp1
    tay
    .TileXYToIndexA TempTileX, TempTileY2, TempTemp2
    tax
; Determine if tile is solid
    sep #$20
    lda [currentRoomTileTypeTableAddress],Y ; top
    txy
    ora [currentRoomTileTypeTableAddress],y ; bottom
    rep #$20
    bpl @end
; get position that player would be when flush against wall
    lda.b TempTileX
    .IndexToPosition_A
    clc
    adc #(ROOM_LEFT - PLAYER_HITBOX_RIGHT)*256-1
; apply position
    .AMINU player_posx
    sta.w player_posx
@end:
    rts

PlayerMoveVertical:
    .ACCU 16
    .INDEX 16
    lda.w player_velocy
    beq @skipmove
    clc
    adc.w player_posy
    .AMAXU $04
    .AMINU $06
    sta.w player_posy
    lda.w player_velocy
    cmp #0
    bmi PlayerMoveUp
    jmp PlayerMoveDown
@skipmove:
    rts

PlayerMoveUp:
    .ACCU 16
    .INDEX 16
; Get Tile Y from player top
    lda.w player_posy
    clc
    adc #(PLAYER_HITBOX_TOP - ROOM_TOP)*256
    .PositionToIndex_A
    sta.b TempTileY
; Get Tile X (left)
    lda.w player_posx
    clc
    adc #(PLAYER_HITBOX_LEFT - ROOM_LEFT)*256
    .PositionToIndex_A
    sta.b TempTileX
; Get Tile X (right)
    lda.w player_posx
    clc
    adc #(PLAYER_HITBOX_RIGHT - ROOM_LEFT)*256
    .PositionToIndex_A
    sta.b TempTileX2
; Get Tile Index
    .BranchIfTileXYOOB TempTileX, TempTileY, @end
    .TileXYToIndexA TempTileX, TempTileY, TempTemp1
    tay
    .TileXYToIndexA TempTileX2, TempTileY, TempTemp2
    tax
; Determine if tile is solid
    sep #$20
    lda [currentRoomTileTypeTableAddress],Y ; top
    txy
    ora [currentRoomTileTypeTableAddress],y ; bottom
    rep #$20
    bpl @end
; get position that player would be when flush against wall
    lda TempTileY
    .IndexToPosition_A
    clc
    adc #(ROOM_TOP + 16 - PLAYER_HITBOX_TOP)*256
; apply position
    .AMAXU player_posy
    sta.w player_posy
@end:
    rts

PlayerMoveDown:
    .ACCU 16
    .INDEX 16
; Get Tile Y from player bottom
    lda.w player_posy
    clc
    adc #(PLAYER_HITBOX_BOTTOM - ROOM_TOP)*256-1
    .PositionToIndex_A
    sta TempTileY
; Get Tile X (left)
    lda.w player_posx
    clc
    adc #(PLAYER_HITBOX_LEFT - ROOM_LEFT)*256
    .PositionToIndex_A
    sta TempTileX
; Get Tile X (right)
    lda.w player_posx
    clc
    adc #(PLAYER_HITBOX_RIGHT - ROOM_LEFT)*256
    .PositionToIndex_A
    sta TempTileX2
; Get Tile Index
    .BranchIfTileXYOOB TempTileX, TempTileY, @end
    .TileXYToIndexA TempTileX, TempTileY, TempTemp1
    tay
    .TileXYToIndexA TempTileX2, TempTileY, TempTemp2
    tax
; Determine if tile is solid
    sep #$20
    lda [currentRoomTileTypeTableAddress],Y ; top
    txy
    ora [currentRoomTileTypeTableAddress],y ; bottom
    rep #$20
    bpl @end
; get position that player would be when flush against wall
    lda TempTileY
    .IndexToPosition_A
    clc
    adc #(ROOM_TOP - PLAYER_HITBOX_BOTTOM)*256 - 1
; apply position
    .AMINU player_posy
    sta.w player_posy
@end:
    rts

.MACRO .VQueuePushMiniopForIndex ARGS ROOMINDEX
; First, set VRAM address
    lda.w vqueueNumMiniOps
    asl
    asl
    tax
    inc.w vqueueNumMiniOps
    lda ROOMINDEX
    and #$0F
    sta.l vqueueMiniOps.1.vramAddr,X
    lda ROOMINDEX
    and #$F0
    asl
    clc
    adc #BG1_TILE_BASE_ADDR + 32 - MAP_MAX_WIDTH
    clc
    adc.l vqueueMiniOps.1.vramAddr,X
    sta.l vqueueMiniOps.1.vramAddr,X
; Second, set value
    phx
    lda ROOMINDEX
    and #$00FF
    tay
    lda.w mapTileTypeTable,Y
    and #$00FF
    asl
    tax
    lda.l MapTiles,X
    plx
    sta.l vqueueMiniOps.1.data,X
.ENDM

PlayerCheckEnterRoom:
    rep #$30 ; 16b AXY
    lda.w player_posx
    cmp #(ROOM_LEFT - 16)*256
    bcc @left
    cmp #(ROOM_RIGHT)*256
    bcs @right
    lda.w player_posy
    cmp #(ROOM_TOP - 16)*256
    bcc @up
    lda.w player_posy
    cmp #(ROOM_BOTTOM)*256
    bcs @down
    rts
@left:
    .ACCU 16
    lda #(ROOM_RIGHT - PLAYER_HITBOX_RIGHT)*256
    sta.w player_posx
    lda #(ROOM_CENTER_Y - 8)*256
    sta.w player_posy
    lda #BG2_TILE_ADDR_OFFS_X
    eor.w gameRoomBG2Offset
    sta.w gameRoomBG2Offset
    sep #$20 ; 8 bit A
    lda.b loadedRoomIndex
    sta.b TempTemp2
    dec.b loadedRoomIndex
    jsr @initialize
    jmp WaitScrollLeft
@right:
    .ACCU 16
    lda #(ROOM_LEFT - PLAYER_HITBOX_LEFT)*256
    sta.w player_posx
    lda #(ROOM_CENTER_Y - 8)*256
    sta.w player_posy
    lda #BG2_TILE_ADDR_OFFS_X
    eor.w gameRoomBG2Offset
    sta.w gameRoomBG2Offset
    sep #$20 ; 8 bit A
    lda.b loadedRoomIndex
    sta.b TempTemp2
    inc.b loadedRoomIndex
    jsr @initialize
    jmp WaitScrollRight
@up:
    .ACCU 16
    lda #(ROOM_BOTTOM - 12)*256
    sta.w player_posy
    lda #(ROOM_CENTER_X - 8)*256
    sta.w player_posx
    lda #BG2_TILE_ADDR_OFFS_Y
    eor.w gameRoomBG2Offset
    sta.w gameRoomBG2Offset
    sep #$20 ; 8 bit A
    lda.b loadedRoomIndex
    sta.b TempTemp2
    sec
    sbc #MAP_MAX_WIDTH
    sta.b loadedRoomIndex
    jsr @initialize
    jmp WaitScrollUp
@down:
    .ACCU 16
    lda #(ROOM_TOP - 4)*256
    sta.w player_posy
    lda #(ROOM_CENTER_X - 8)*256
    sta.w player_posx
    lda #BG2_TILE_ADDR_OFFS_Y
    eor.w gameRoomBG2Offset
    sta.w gameRoomBG2Offset
    sep #$20 ; 8 bit A
    lda.b loadedRoomIndex
    sta.b TempTemp2
    clc
    adc #MAP_MAX_WIDTH
    sta.b loadedRoomIndex
    jsr @initialize
    jmp WaitScrollDown
@initialize:
; Set player speed to 0
    sep #$30 ; 16 bit A
; Load room
    sep #$30 ; 8 bit AXY
    ldx.b loadedRoomIndex
    lda.l mapTileSlotTable,X
    pha
    jsl LoadRoomSlotIntoLevel
    sep #$30 ; 8 bit AXY
    pla
    rep #$30 ; 16 bit AXY
; Update map using vqueue
; Note: TempTemp2 contains old tile index
    .VQueuePushMiniopForIndex loadedRoomIndex
    lda #$0020
    ora.l vqueueMiniOps.1.data,X
    sta.l vqueueMiniOps.1.data,X
    .VQueuePushMiniopForIndex TempTemp2
    stz.w player_velocx
    stz.w player_velocy
    rts

_MakeWaitScrollSub1:
    .GetObjectPos_X
    rts

_MakeWaitScrollSub2:
    .PutObjectPos_X
    rts

.MACRO .MakeWaitScroll ARGS SREG, SVAR, AMT, NFRAMES, SAMT, TEMP1, SPRVAL
    wai
    jsl ProcessVQueue
    rep #$20 ; 16 bit A
    sep #$10 ; 8 bit XY
    lda #NFRAMES
    sta.b TEMP1
    @loopWait:
    ; First, move objects
        .IF SPRVAL != object_t.pos_x
            sep #$20 ; 8 bit A
        .ENDIF
        rep #$10 ; 16 bit XY
        ldx #0
        cpx.w objectIndex
        beq @loopSpriteEnd
        @loopSprite:
            .IF SPRVAL == object_t.pos_x
                jsr _MakeWaitScrollSub1
                sec
                sbc #(AMT - SAMT)/NFRAMES
                jsr _MakeWaitScrollSub2
            .ELSE
                lda.w objectData+SPRVAL,X
                sec
                sbc #(AMT - SAMT)/NFRAMES
                sta.w objectData+SPRVAL,X
            .ENDIF
            inx
            inx
            inx
            inx
            cpx.w objectIndex
            bne @loopSprite
        @loopSpriteEnd:
        .IF SPRVAL != object_t.pos_x
            rep #$20 ; 16 bit A
        .ENDIF
        sep #$10 ; 8 bit XY
    ; Wait for VBlank
        wai
    ; Scroll
        lda.w SVAR
        clc
        adc #AMT/NFRAMES
        and #$01FF
        sta.w SVAR
        ldx.w SVAR
        stx SREG
        ldx.w SVAR+1
        stx SREG
    ; Upload objects to OAM
        stz OAMADDR
        lda #512+32
        sta DMA0_SIZE
        lda.w #objectData
        sta DMA0_SRCL
        sep #$20 ; 8 bit A
        lda #0
        sta DMA0_SRCH
        ; Absolute address, auto increment, 1 byte at a time
        lda #%00000000
        sta DMA0_CTL
        ; Write to OAM
        lda #$04
        sta DMA0_DEST
        lda #$01
        sta MDMAEN
        rep #$20 ; 16 bit A
    ; loop
        dec TEMP1
        bne @loopWait
    rts
.ENDM

WaitScrollLeft:
    .MakeWaitScroll BG2HOFS, gameRoomScrollX, (-256), 32, (-64), TempTemp1, object_t.pos_x

WaitScrollRight:
    .MakeWaitScroll BG2HOFS, gameRoomScrollX, 256, 32, 64, TempTemp1, object_t.pos_x

WaitScrollUp:
    .MakeWaitScroll BG2VOFS, gameRoomScrollY, (-256), 32, (-128), TempTemp1, object_t.pos_y

WaitScrollDown:
    .MakeWaitScroll BG2VOFS, gameRoomScrollY, 256, 32, 128, TempTemp1, object_t.pos_y

GameTileToRoomTileIndexTable:
    .REPT 16*4
        .db 96
    .ENDR
    .REPT 8 INDEX iy
        .db 96, 96
        .REPT 12 INDEX ix
            .db (iy * 12) + ix
        .ENDR
        .db 96, 96
    .ENDR
    .REPT 16*4
        .db 96
    .ENDR

InitialPathfindingData:
.REPT 16*4
    .db $01 ; down
.ENDR
.REPT 8
    .db $02, $02 ; right
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; empty
    .db $03, $03 ; left
.ENDR
.REPT 16*4
    .db $04 ; up
.ENDR

; PathfindingDirectionX:
;     .db 0
;     .db 0
;     .db 127
;     .db -127
;     .db 0
;     .db 0

; PathfindingDirectionY:
;     .db 0
;     .db 127
;     .db 0
;     .db 0
;     .db -127
;     .db 0

player_initialize_pathfinding_data:
    rep #$30
    phb
    lda #255
    ldx #loword(InitialPathfindingData)
    ldy #loword(pathfind_player_data)
    mvn bankbyte(InitialPathfindingData), bankbyte(pathfind_player_data)
    plb
    rtl

_player_clear_pathfinding_data:
    jsl player_initialize_pathfinding_data
    rts

player_update_pathfinding_data:
    jsr _player_clear_pathfinding_data
    .DEFINE tmp $00
    .DEFINE q_start $02
    .DEFINE q_end $04
    .DEFINE q_count $06
; setup
    phb
    .ChangeDataBank $7E
    rep #$30
    ldx #loword(tempData) | $FF
    stx.b q_start
    stx.b q_end
    stz.b q_count
    sep #$30
; begin
    lda.w player_posx+1
    adc #8
    .DivideStatic 16
    sta.b tmp
    lda.w player_posy+1
    adc #8
    and #$F0
    ora.b tmp
    sta.b (q_end)
    dec.b q_end
    tax
    lda #PATH_DIR_NONE
    sta.w loword(pathfind_player_data),X
    inc.b q_count
    ; loop
    @loop:
        lda.b (q_start)
        tax
        lda.l GameTileToRoomTileIndexTable,X
        tay
        lda (currentRoomTileTypeTableAddress),Y
        bmi @skiptile ; Skip if this tile is solid (can not be entered)
 
        .REPT 4 INDEX i
            .IF i == 0
                .DEFINE i_dir PATH_DIR_RIGHT
                dex
            .ELIF i == 1
                .DEFINE i_dir PATH_DIR_LEFT
                inx
                inx
            .ELIF i == 2
                .DEFINE i_dir PATH_DIR_UP
                txa
                clc
                adc #$0F
                tax
            .ELIF i == 3
                .DEFINE i_dir PATH_DIR_DOWN
                txa
                clc
                adc #$E0
                tax
            .ENDIF
            ; tax
            lda.w loword(pathfind_player_data),X
            bne + ; If found tile is non-zero, skip it
            lda #i_dir
            sta.w loword(pathfind_player_data),X
            txa
            sta.b (q_end)
            dec.b q_end
            inc.b q_count

            +:
            .UNDEFINE i_dir
        .ENDR
    @skiptile:
        dec.b q_start
        dec.b q_count
        bne @loop
    ; end
    plb
    rtl

.ENDS