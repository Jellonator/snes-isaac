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

PlayerInit:
    rep #$20 ; 16 bit A
    stz.w joy1held
    stz.w joy1press
    stz.w joy1raw
    lda #24
    sta.w player.stat_accel
    lda #128*3
    sta.w player.stat_speed
    lda #24
    sta.w player.stat_tear_delay
    lda #$0100
    sta.w player.stat_tear_speed
    lda #0
    sta.w player.speed.x
    lda #0
    sta.w player.speed.y
    lda #((32 + 6 * 16 - 8) * 256)
    sta.w player.pos.x
    lda #((64 + 4 * 16 - 8) * 256)
    sta.w player.pos.y
    stz.w tear_bytes_used
    rts

PlayerUpdate:
    rep #$30 ; 16 bit AXY

    lda.w player.stat_speed
    sta $00
    ; check (LEFT OR RIGHT) AND (UP OR DOWN)
    ; if so, multiply speed by 3/4; aka (A+A+A) >> 2
    lda.w joy1held
    ; LEFT or RIGHT. 00 = F; 01,10,11 = T
    bit #$0C00
    beq @skip_slow
    bit #$0300
    beq @skip_slow
    lda.w player.stat_speed
    asl
    clc
    adc $00
    lsr
    lsr
    sta $00
@skip_slow:

    ldx.w player.speed.y
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
    adc.w player.stat_accel
    AMINI $00
    jmp @endy
@slowup:
    ; slowleft
    sec
    sbc.w player.stat_accel
    AMAXI $00
    jmp @endy
@down:
    ; right
    txa
    clc
    adc.w player.stat_accel
    AMIN $00
    jmp @endy
@up:
    ; left
    txa
    sec
    sbc.w player.stat_accel
    eor #$FFFF
    inc A
    AMIN $00
    eor #$FFFF
    inc A
@endy:
    sta.w player.speed.y
    
    ldx.w player.speed.x
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
    adc.w player.stat_accel
    AMINI $00
    jmp @endx
@slowleft:
    ; slowleft
    sec
    sbc.w player.stat_accel
    AMAXI $00
    jmp @endx
@right:
    ; right
    txa
    clc
    adc.w player.stat_accel
    AMIN $00
    jmp @endx
@left:
    ; left
    txa
    sec
    sbc.w player.stat_accel
    eor #$FFFF
    inc A
    AMIN $00
    eor #$FFFF
    inc A
@endx:
    sta.w player.speed.x

.DEFINE TempLimitLeft $00
.DEFINE TempLimitRight $02
.DEFINE TempLimitTop $04
.DEFINE TempLimitBottom $06
    ldx #(ROOM_LEFT - 4)*256
    ldy #(ROOM_RIGHT - 12)*256
    stx $00 ; left
    sty $02 ; right
    lda player.pos.y
    cmp #(ROOM_CENTER_Y - 8 - ROOM_DOOR_RADIUS)*256
    bmi +
    cmp #(ROOM_CENTER_Y - 8 + ROOM_DOOR_RADIUS)*256
    bpl +
    ldx #(ROOM_LEFT - 4 - 16)*256
    ldy #(ROOM_RIGHT - 12 + 16)*256
    stx $00 ; left
    sty $02 ; right
+:

    ldx #(ROOM_TOP - 4)*256
    ldy #(ROOM_BOTTOM - 12)*256
    stx $04 ; top
    sty $06 ; bottom
    lda player.pos.x
    cmp #(ROOM_CENTER_X - 8 - ROOM_DOOR_RADIUS)*256
    bmi +
    cmp #(ROOM_CENTER_X - 8 + ROOM_DOOR_RADIUS)*256
    bpl +
    ldx #(ROOM_TOP - 4 - 16)*256
    ldy #(ROOM_BOTTOM - 12 + 16)*256
    stx $04 ; top
    sty $06 ; bottom
+:

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

    lda player.pos.y
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
    lda.w player.tear_timer
    cmp.w player.stat_tear_delay ; if tear_timer < stat_tear_delay: ++tear_timer
    bcc @tear_not_ready
    ; check inputs
    lda.w joy1held
    bit #(JOY_A|JOY_B|JOY_Y|JOY_X)
    beq @end_tear_code
    jsr PlayerShootTear
    jmp @end_tear_code
@tear_not_ready:
    inc A
    sta.w player.tear_timer
@end_tear_code:
    sep #$30 ; 8 bit AXY
    ; update render data
    lda.w player.pos.x+1
    sta.w objectData.1.pos_x
    sta.w objectData.2.pos_x
    lda.w player.pos.y+1
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
    rts

PlayerShootTear:
    rep #$30 ; 16 bit AXY
    jsr GetTearSlot
    lda.w player.flags
    eor #PLAYER_FLAG_EYE
    sta.w player.flags
    lda #90
    sta.w tear_array.1.lifetime,X
    stz.w tear_array.1.size,X
    lda #$0000
    sta.w player.tear_timer
    lda.w joy1held
    bit #JOY_Y
    bne @tear_left
    bit #JOY_A
    bne @tear_right
    bit #JOY_B
    bne @tear_down
;tear_up:
    lda.w player.speed.x
    sta.w tear_array.1.speed.x,X
    lda.w player.speed.y
    AMINI 64
    AMAXI -128
    sec
    sbc.w player.stat_tear_speed
    sta.w tear_array.1.speed.y,X
    jmp @vertical
@tear_left:
    lda.w player.speed.y
    sta.w tear_array.1.speed.y,X
    lda.w player.speed.x
    AMINI 64
    AMAXI -128
    sec
    sbc.w player.stat_tear_speed
    sta.w tear_array.1.speed.x,X
    jmp @horizontal
@tear_right:
    lda.w player.speed.y
    sta.w tear_array.1.speed.y,X
    lda.w player.speed.x
    AMAXI -64
    AMAXI 128
    clc
    adc.w player.stat_tear_speed
    sta.w tear_array.1.speed.x,X
    jmp @horizontal
@tear_down:
    lda.w player.speed.x
    sta.w tear_array.1.speed.x,X
    lda.w player.speed.y
    AMAXI -64
    AMAXI 128
    clc
    adc.w player.stat_tear_speed
    sta.w tear_array.1.speed.y,X
    jmp @vertical
@vertical:
    lda.w player.flags
    bit #PLAYER_FLAG_EYE
    bne @vertical_skip
    lda.w player.pos.x
    sta.w tear_array.1.pos.x,X
    lda.w player.pos.y
    clc
    adc #256*4
    sta.w tear_array.1.pos.y,X
    rts
@vertical_skip:
    lda.w player.pos.x
    clc
    adc #256*8
    sta.w tear_array.1.pos.x,X
    lda.w player.pos.y
    clc
    adc #256*4
    sta.w tear_array.1.pos.y,X
    rts
@horizontal:
    lda.w player.flags
    bit #PLAYER_FLAG_EYE
    bne @horizontal_skip
    lda.w player.pos.x
    clc
    adc #256*4
    sta.w tear_array.1.pos.x,X
    lda.w player.pos.y
    sta.w tear_array.1.pos.y,X
    rts
@horizontal_skip:
    lda.w player.pos.x
    clc
    adc #256*4
    sta.w tear_array.1.pos.x,X
    lda.w player.pos.y
    clc
    adc.w #256*8
    sta.w tear_array.1.pos.y,X
    rts

_UpdateTearPost:
    ; send to OAM
    sep #$20 ; 8A, 16XY
    ldy.w objectIndex
    lda.w tear_array.1.pos.x+1,X
    sta.w objectData.1.pos_x,Y
    lda.w tear_array.1.pos.y+1,X
    sec
    sbc $00
    sta.w objectData.1.pos_y,Y
    lda #$21
    sta.w objectData.1.tileid,Y
    lda #%00101010
    sta.w objectData.1.flags,Y
    rts

_UpdateTearTile:
    .ACCU 16
    .INDEX 16
    cmp #BLOCK_POOP
    bne +
; handle poop
    sep #$20 ; 8 bit A
    lda [currentRoomTileVariantTableAddress],Y
    cmp #2
    beq @removeTile
    inc A
    sta [currentRoomTileVariantTableAddress],Y
    rep #$20 ; 16 bit A
    jsr HandleTileChanged
    rts
@removeTile:
    sep #$20 ; 8 bit A
    lda #0
    sta [currentRoomTileVariantTableAddress],Y
    sta [currentRoomTileTypeTableAddress],Y
    rep #$20 ; 16 bit A
    jsr HandleTileChanged
    rts
+:
    rts

UpdateTears:
    rep #$30 ; 16 bit AXY
    ldx #$0000
    cpx.w tear_bytes_used
    bne @iter
    rts
@iter_remove:
    jsr RemoveTearSlot
    ; No ++X, but do check that this is the end of the array
    cpx.w tear_bytes_used ; X < tear_bytes_used
    bcc @iter
    jmp @end
@iter:
; Handle lifetime
    lda.w tear_array.1.lifetime,X
    dec A
    cmp #0 ; if lifetime == 0, then remove
    beq @iter_remove
    sta.w tear_array.1.lifetime,X
    AMINUI 8
    sta.w $00 ; $00 is tear height
; Apply speed to position
    lda.w tear_array.1.pos.x,X
    clc
    adc.w tear_array.1.speed.x,X
    sta.w tear_array.1.pos.x,X
    clc
    adc #(4-ROOM_LEFT)*256
    .PositionToIndex_A
    sta currentConsideredTileX
    lda.w tear_array.1.pos.y,X
    clc
    adc.w tear_array.1.speed.y,X
    sta.w tear_array.1.pos.y,X
    clc
    adc #(-ROOM_TOP)*256
    .PositionToIndex_A
    sta currentConsideredTileY
; Check tile
    .BranchIfTileXYOOB currentConsideredTileX, currentConsideredTileY, @iter_remove
    .TileXYToIndexA currentConsideredTileX, currentConsideredTileY, TempTemp1
    tay
    lda [currentRoomTileTypeTableAddress],Y
    and #$00FF
    cmp #0
    beq @skipTileHandler
    jsr _UpdateTearTile
    bra @iter_remove
@skipTileHandler:
; Update rest of tear info
    jsr _UpdateTearPost
    rep #$30 ; 16AXY
    phx
    .IncrementObjectIndex
    plx
    txa ; ++X
    clc
    adc #_sizeof_tear_t
    tax
    cpx.w tear_bytes_used ; X < tear_bytes_used
    bcs @end
    jmp @iter
@end:
    rts

; Get the next available tear slot, and store it in X
; if there are no available slots, the tear with the lowest life will be chosen
GetTearSlot:
    rep #$30 ; 16 bit AXY
    lda.w tear_bytes_used
    cmp #TEAR_ARRAY_MAX_SIZE
    bcc @has_empty_slots
; no empty slots available:
; find the slot with the lowest lifetime
    lda #$7FFF
    sta $00 ; $00 is best value
    ldx #0 ; x is current index
    ldy #0 ; Y is best index
@iter_tears:
    lda.w tear_array.1.lifetime,X
    cmp $00
    bcs @skip_store
    sta $00
    txy ; if tears[X].lifetime < tears[Y].lifetime: Y=X
@skip_store:
; ++X
    txa ; increment X
    clc
    adc #_sizeof_tear_t
    tax
; X < TEAR_ARRAY_MAX_SIZE
    cpx #TEAR_ARRAY_MAX_SIZE
    bcc @iter_tears
; Finish, transfer Y to X
    tyx
    rts
; empty slots available:
@has_empty_slots:
    tax
    clc
    adc #_sizeof_tear_t
    sta.w tear_bytes_used
    rts

; Remove the tear at the index X
; AXY must be 16bit
RemoveTearSlot:
    rep #$30 ; 16 bit AXY
    ; decrement number of used tears
    lda.w tear_bytes_used
    sec
    sbc #_sizeof_tear_t
    sta.w tear_bytes_used
    ; Check if X is the last available tear slot
    cpx.w tear_bytes_used
    beq @skip_copy
    ; copy last tear slot to slot being removed
    ldy.w tear_bytes_used
    lda.w tear_array+0,Y
    sta.w tear_array+0,X
    lda.w tear_array+2,Y
    sta.w tear_array+2,X
    lda.w tear_array+4,Y
    sta.w tear_array+4,X
    lda.w tear_array+6,Y
    sta.w tear_array+6,X
    lda.w tear_array+8,Y
    sta.w tear_array+8,X
    lda.w tear_array+10,Y
    sta.w tear_array+10,X
    lda.w tear_array+12,Y
    sta.w tear_array+12,X
    lda.w tear_array+14,Y
    sta.w tear_array+14,X
@skip_copy:
    rts

PlayerMoveHorizontal:
    .ACCU 16
    .INDEX 16
    lda.w player.speed.x
    beq @skipmove
    clc
    adc.w player.pos.x
    AMAXU $00
    AMINU $02
    sta.w player.pos.x
    lda.w player.speed.x
    cmp #0
    bmi PlayerMoveLeft
    jmp PlayerMoveRight
@skipmove:
    rts

PlayerMoveLeft:
    .ACCU 16
    .INDEX 16
; Get Tile X from player left
    lda.w player.pos.x
    clc
    adc #(PLAYER_HITBOX_LEFT - ROOM_LEFT)*256
    .PositionToIndex_A
    sta TempTileX
; Get Tile Y (top)
    lda player.pos.y
    clc
    adc #(PLAYER_HITBOX_TOP - ROOM_TOP)*256
    .PositionToIndex_A
    sta TempTileY
; Get Tile Y (bottom)
    lda player.pos.y
    clc
    adc #(PLAYER_HITBOX_BOTTOM - ROOM_TOP)*256
    .PositionToIndex_A
    sta TempTileY2
; Get Tile Index
    .BranchIfTileXYOOB TempTileX, TempTileY, @end
    .TileXYToIndexA TempTileX, TempTileY, TempTemp1
    tay
    .TileXYToIndexA TempTileX, TempTileY2, TempTemp2
    tax
; Determine if tile is solid
    lda [currentRoomTileTypeTableAddress],Y ; top
    txy
    ora [currentRoomTileTypeTableAddress],y ; bottom
    and #$00FF
    beq @end
; get position that player would be when flush against wall
    lda TempTileX
    .IndexToPosition_A
    clc
    adc #(ROOM_LEFT + 16 - PLAYER_HITBOX_LEFT)*256
; apply position
    AMAXU player.pos.x
    sta.w player.pos.x
@end:
    rts

PlayerMoveRight:
    .ACCU 16
    .INDEX 16
; Get Tile X from player left
    lda.w player.pos.x
    clc
    adc #(PLAYER_HITBOX_RIGHT - ROOM_LEFT)*256-1
    .PositionToIndex_A
    sta TempTileX
; Get Tile Y (top)
    lda player.pos.y
    clc
    adc #(PLAYER_HITBOX_TOP - ROOM_TOP)*256
    .PositionToIndex_A
    sta TempTileY
; Get Tile Y (bottom)
    lda player.pos.y
    clc
    adc #(PLAYER_HITBOX_BOTTOM - ROOM_TOP)*256
    .PositionToIndex_A
    sta TempTileY2
; Get Tile Index
    .BranchIfTileXYOOB TempTileX, TempTileY, @end
    .TileXYToIndexA TempTileX, TempTileY, TempTemp1
    tay
    .TileXYToIndexA TempTileX, TempTileY2, TempTemp2
    tax
; Determine if tile is solid
    lda [currentRoomTileTypeTableAddress],Y ; top
    txy
    ora [currentRoomTileTypeTableAddress],y ; bottom
    and #$00FF
    beq @end
; get position that player would be when flush against wall
    lda TempTileX
    .IndexToPosition_A
    clc
    adc #(ROOM_LEFT - PLAYER_HITBOX_RIGHT)*256-1
; apply position
    AMINU player.pos.x
    sta.w player.pos.x
@end:
    rts

PlayerMoveVertical:
    .ACCU 16
    .INDEX 16
    lda.w player.speed.y
    beq @skipmove
    clc
    adc.w player.pos.y
    AMAXU $04
    AMINU $06
    sta.w player.pos.y
    lda.w player.speed.y
    cmp #0
    bmi PlayerMoveUp
    jmp PlayerMoveDown
@skipmove:
    rts

PlayerMoveUp:
    .ACCU 16
    .INDEX 16
; Get Tile Y from player top
    lda.w player.pos.y
    clc
    adc #(PLAYER_HITBOX_TOP - ROOM_TOP)*256
    .PositionToIndex_A
    sta TempTileY
; Get Tile X (left)
    lda player.pos.x
    clc
    adc #(PLAYER_HITBOX_LEFT - ROOM_LEFT)*256
    .PositionToIndex_A
    sta TempTileX
; Get Tile X (right)
    lda player.pos.x
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
    lda [currentRoomTileTypeTableAddress],Y ; top
    txy
    ora [currentRoomTileTypeTableAddress],y ; bottom
    and #$00FF
    beq @end
; get position that player would be when flush against wall
    lda TempTileY
    .IndexToPosition_A
    clc
    adc #(ROOM_TOP + 16 - PLAYER_HITBOX_TOP)*256
; apply position
    AMAXU player.pos.y
    sta.w player.pos.y
@end:
    rts

PlayerMoveDown:
    .ACCU 16
    .INDEX 16
; Get Tile Y from player bottom
    lda.w player.pos.y
    clc
    adc #(PLAYER_HITBOX_BOTTOM - ROOM_TOP)*256-1
    .PositionToIndex_A
    sta TempTileY
; Get Tile X (left)
    lda player.pos.x
    clc
    adc #(PLAYER_HITBOX_LEFT - ROOM_LEFT)*256
    .PositionToIndex_A
    sta TempTileX
; Get Tile X (right)
    lda player.pos.x
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
    lda [currentRoomTileTypeTableAddress],Y ; top
    txy
    ora [currentRoomTileTypeTableAddress],y ; bottom
    and #$00FF
    beq @end
; get position that player would be when flush against wall
    lda TempTileY
    .IndexToPosition_A
    clc
    adc #(ROOM_TOP - PLAYER_HITBOX_BOTTOM)*256 - 1
; apply position
    AMINU player.pos.y
    sta.w player.pos.y
@end:
    rts

.MACRO .VQueuePushMiniopForIndex ARGS ROOMINDEX
; First, set VRAM address
    lda vqueueNumMiniOps
    asl
    asl
    tax
    inc vqueueNumMiniOps
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
    lda player.pos.x
    cmp #(ROOM_LEFT - 16)*256
    bcc @left
    cmp #(ROOM_RIGHT)*256
    bcs @right
    lda player.pos.y
    cmp #(ROOM_TOP - 16)*256
    bcc @up
    lda player.pos.y
    cmp #(ROOM_BOTTOM)*256
    bcs @down
    rts
@left:
    .ACCU 16
    lda #(ROOM_RIGHT - PLAYER_HITBOX_RIGHT)*256
    sta player.pos.x
    lda #(ROOM_CENTER_Y - 8)*256
    sta player.pos.y
    lda #BG2_TILE_ADDR_OFFS_X
    eor gameRoomBG2Offset
    sta gameRoomBG2Offset
    sep #$20 ; 8 bit A
    lda loadedRoomIndex
    sta TempTemp2
    dec loadedRoomIndex
    jsr @initialize
    jmp WaitScrollLeft
@right:
    .ACCU 16
    lda #(ROOM_LEFT - PLAYER_HITBOX_LEFT)*256
    sta player.pos.x
    lda #(ROOM_CENTER_Y - 8)*256
    sta player.pos.y
    lda #BG2_TILE_ADDR_OFFS_X
    eor gameRoomBG2Offset
    sta gameRoomBG2Offset
    sep #$20 ; 8 bit A
    lda loadedRoomIndex
    sta TempTemp2
    inc loadedRoomIndex
    jsr @initialize
    jmp WaitScrollRight
@up:
    .ACCU 16
    lda #(ROOM_BOTTOM - 12)*256
    sta player.pos.y
    lda #(ROOM_CENTER_X - 8)*256
    sta player.pos.x
    lda #BG2_TILE_ADDR_OFFS_Y
    eor gameRoomBG2Offset
    sta gameRoomBG2Offset
    sep #$20 ; 8 bit A
    lda loadedRoomIndex
    sta TempTemp2
    sec
    sbc #MAP_MAX_WIDTH
    sta loadedRoomIndex
    jsr @initialize
    jmp WaitScrollUp
@down:
    .ACCU 16
    lda #(ROOM_TOP - 4)*256
    sta player.pos.y
    lda #(ROOM_CENTER_X - 8)*256
    sta player.pos.x
    lda #BG2_TILE_ADDR_OFFS_Y
    eor gameRoomBG2Offset
    sta gameRoomBG2Offset
    sep #$20 ; 8 bit A
    lda loadedRoomIndex
    sta TempTemp2
    clc
    adc #MAP_MAX_WIDTH
    sta loadedRoomIndex
    jsr @initialize
    jmp WaitScrollDown
@initialize:
; Set player speed to 0
    sep #$30 ; 16 bit A
; Load room
    sep #$30 ; 8 bit AXY
    ldx loadedRoomIndex
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
    ora vqueueMiniOps.1.data,X
    sta vqueueMiniOps.1.data,X
    .VQueuePushMiniopForIndex TempTemp2
    stz player.speed.x
    stz player.speed.y
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
    sta TEMP1
    @loopWait:
    ; First, move objects
        .IF SPRVAL != object_t.pos_x
            sep #$20 ; 8 bit A
        .ENDIF
        rep #$10 ; 16 bit XY
        ldx #0
        cpx objectIndex
        beq @loopSpriteEnd
        @loopSprite:
            .IF SPRVAL == object_t.pos_x
                jsr _MakeWaitScrollSub1
                sec
                sbc #(AMT - SAMT)/NFRAMES
                jsr _MakeWaitScrollSub2
            .ELSE
                lda objectData+SPRVAL,X
                sec
                sbc #(AMT - SAMT)/NFRAMES
                sta objectData+SPRVAL,X
            .ENDIF
            inx
            inx
            inx
            inx
            cpx objectIndex
            bne @loopSprite
        @loopSpriteEnd:
        .IF SPRVAL != object_t.pos_x
            rep #$20 ; 16 bit A
        .ENDIF
        sep #$10 ; 8 bit XY
    ; Wait for VBlank
        wai
    ; Scroll
        lda SVAR
        clc
        adc #AMT/NFRAMES
        and #$01FF
        sta SVAR
        ldx SVAR
        stx SREG
        ldx SVAR+1
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

.ENDS