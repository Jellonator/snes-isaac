.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "Player" FREE

PlayerInit:
    rep #$20 ; 16 bit A
    stz.w joy1held
    stz.w joy1press
    stz.w joy1raw
    lda #24
    sta.w player.stat_accel
    lda #256
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

    ; apply speed
    jsr PlayerMoveHorizontal
    jsr PlayerMoveVertical
; handle player shoot
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
    ; lda player.pos.x
    ; sta tear_array.1.pos.x,X
    ; lda player.pos.y
    ; sta tear_array.1.pos.y,X
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

UpdateTears:
    rep #$30 ; 16 bit AXY
    ldx #$0000
    cpx.w tear_bytes_used
    beq @end
    jmp @iter
@iter_remove:
    jsr RemoveTearSlot
    ; No ++X, but do check that this is the end of the array
    cpx.w tear_bytes_used ; X != tear_bytes_used
    bcs @end
@iter:
    lda.w tear_array.1.lifetime,X
    dec A
    cmp #0 ; if lifetime == 0, then remove
    beq @iter_remove
    sta.w tear_array.1.lifetime,X
    AMINUI 8
    sta.w $00
    lda.w tear_array.1.pos.x,X
    clc
    adc.w tear_array.1.speed.x,X
    sta.w tear_array.1.pos.x,X
    lda.w tear_array.1.pos.y,X
    clc
    adc.w tear_array.1.speed.y,X
    sta.w tear_array.1.pos.y,X
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
    rep #$20 ;16AXY
    phx
    .IncrementObjectIndex
    plx
    txa ; ++X
    clc
    adc #_sizeof_tear_t
    tax
    cpx.w tear_bytes_used ; X < tear_bytes_used
    bcc @iter
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

.DEFINE TempTileX $08
.DEFINE TempTileY $0A
.DEFINE TempTileX2 $0C
.DEFINE TempTileY2 $0E
.DEFINE TempTemp1 $10
.DEFINE TempTemp2 $12

; Clobbers A
.MACRO .BranchIfTileXYOOB ARGS XMEM, YMEM, LABEL
    lda XMEM
    cmp #12
    bcs LABEL
    lda YMEM
    cmp #8
    bcs LABEL
.ENDM

.MACRO .TileXYToIndexA ARGS XMEM, YMEM, TEMPMEM
    lda YMEM
    asl
    asl
    sta TEMPMEM
    asl
    clc
    adc TEMPMEM
    adc XMEM
.ENDM

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
; Determine if tile is solid
    adc.w loadedMapAddressOffset
    tax
    .TileXYToIndexA TempTileX, TempTileY2, TempTemp2
    adc.w loadedMapAddressOffset
    tay
    lda.l roominfo_t.tileTypeTable+$7E0000,X ; top
    tyx
    ora.l roominfo_t.tileTypeTable+$7E0000,X ; bottom
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
; Determine if tile is solid
    adc.w loadedMapAddressOffset
    tax
    .TileXYToIndexA TempTileX, TempTileY2, TempTemp2
    adc.w loadedMapAddressOffset
    tay
    lda.l roominfo_t.tileTypeTable+$7E0000,X ; top
    tyx
    ora.l roominfo_t.tileTypeTable+$7E0000,X ; bottom
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
; Determine if tile is solid
    adc.w loadedMapAddressOffset
    tax
    .TileXYToIndexA TempTileX2, TempTileY, TempTemp2
    adc.w loadedMapAddressOffset
    tay
    lda.l roominfo_t.tileTypeTable+$7E0000,X ; top
    tyx
    ora.l roominfo_t.tileTypeTable+$7E0000,X ; bottom
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
; Determine if tile is solid
    adc.w loadedMapAddressOffset
    tax
    .TileXYToIndexA TempTileX2, TempTileY, TempTemp2
    adc.w loadedMapAddressOffset
    tay
    lda.l roominfo_t.tileTypeTable+$7E0000,X ; top
    tyx
    ora.l roominfo_t.tileTypeTable+$7E0000,X ; bottom
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

.ENDS