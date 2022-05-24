.include "base.inc"

.BANK $00 SLOT "ROM"
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

    ; apply speed
    lda.w player.pos.x
    clc
    adc.w player.speed.x
    AMAXUI (32 - 4)*256
    AMINUI (32 + 12*16 - 12)*256
    sta.w player.pos.x
    lda.w player.pos.y
    clc
    adc.w player.speed.y
    AMAXUI (64 - 4)*256
    AMINUI (64 + 8*16 - 12)*256
    sta.w player.pos.y
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

.ENDS