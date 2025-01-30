.include "base.inc"

.DEFINE TempTileX $08
.DEFINE TempTileY $0A
.DEFINE TempTileX2 $0C
.DEFINE TempTileY2 $0E
.DEFINE TempTemp1 $14
.DEFINE TempTemp2 $16
.DEFINE TempTearIdx $18

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
    .dw deft($00, 0) | T_HIGHP ; null
    .dw deft($32, 5) | T_HIGHP ; red empty
    .dw deft($31, 5) | T_HIGHP ; red half
    .dw deft($30, 5) | T_HIGHP ; red full
    .dw deft($33, 6) | T_HIGHP ; spirit half
    .dw deft($30, 6) | T_HIGHP ; spirit full
    .dw deft($00, 5) | T_HIGHP ; eternal

_PlayerHealthEffectiveValueTable:
    .db 0 ; null
    .db 0 ; red empty
    .db 1 ; red half
    .db 2 ; red full
    .db 1 ; spirit half
    .db 2 ; spirit full
    .db 1 ; eternal

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

Player.health_up:
    sep #$30
    ldy #HEALTHSLOT_COUNT-1
    @loop:
        ; move health slots over one
        lda.w playerData.healthSlots,Y
        sta.w playerData.healthSlots+1,Y
        cpy #0
        beq @end
        dey
        jmp @loop
@end:
    lda #HEALTH_REDHEART_FULL
    sta.w playerData.healthSlots,Y
    jmp _PlayerRenderAllHearts

Player.get_effective_health:
    sep #$30
    stz.b $00
    ldy #HEALTHSLOT_COUNT-1
    @loop:
        lda.w playerData.healthSlots,Y
        tax
        lda.b $00
        clc
        adc.l _PlayerHealthEffectiveValueTable,X
        sta.b $00
        dey
        bpl @loop
    lda.b $00
    rtl
        
@end:
    lda #HEALTH_REDHEART_FULL
    sta.w playerData.healthSlots,Y
    jmp _PlayerRenderAllHearts

Player.reset_stats:
    rep #$20
    lda #PLAYER_STATBASE_ACCEL
    sta.w playerData.stat_accel
    lda #PLAYER_STATBASE_SPEED
    sta.w playerData.stat_speed
    lda #PLAYER_STATBASE_TEAR_RATE
    sta.w playerData.stat_tear_rate
    lda #PLAYER_STATBASE_TEAR_SPEED
    sta.w playerData.stat_tear_speed
    lda #PLAYER_STATBASE_DAMAGE
    sta.w playerData.stat_damage
    lda #PLAYER_STATBASE_TEAR_LIFETIME
    sta.w playerData.stat_tear_lifetime
    stz.w playerData.tearflags
    rtl

Player.update_money_display:
    rep #$30 ; 16B AXY
    ; inc vqueue
    lda.w vqueueNumMiniOps
    asl
    asl
    tax
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    ; first, determine offset
    lda #BG1_TILE_BASE_ADDR + $46
    sta.l vqueueMiniOps.1.vramAddr,X
    lda #BG1_TILE_BASE_ADDR + $47
    sta.l vqueueMiniOps.2.vramAddr,X
    ; now, determine character
    lda.w playerData.money
    and #$00F0
    lsr
    lsr
    lsr
    lsr
    clc
    adc #$3C70
    sta.l vqueueMiniOps.1.data,X
    lda.w playerData.money
    and #$000F
    clc
    adc #$3C70
    sta.l vqueueMiniOps.2.data,X
    rtl

PlayerInit:
    jsl Costume.player_reset
    rep #$20 ; 16 bit A
    stz.w joy1held
    stz.w joy1press
    stz.w joy1raw
    lda #0
    sta.w playerData.flags
    sta.w player_velocx
    sta.w player_velocy
    stz.w player_damageflag
    lda #((32 + 6 * 16 - 8) * 256)
    sta.w player_posx
    lda #((64 + 4 * 16 - 8) * 256)
    sta.w player_posy
    ; stz.w projectile_count_2x
    ; setup HP
    .REPT HEALTHSLOT_COUNT INDEX i
        stz.w playerData.healthSlots + (i * 2)
    .ENDR
    stz.w playerData.invuln_timer
    stz.w playerData.money
    stz.w playerData.keys
    stz.w playerData.bombs
    sep #$30
    lda #HEALTH_REDHEART_FULL
    sta.w playerData.healthSlots.1
    sta.w playerData.healthSlots.2
    sta.w playerData.healthSlots.3
    jsl _PlayerRenderAllHearts
    jsl Item.reset_items
    jsl Player.reset_stats
    stz.w playerData.walk_frame
    sep #$30
    stz.w playerData.anim_wait_timer
    stz.w playerData.head_offset_y
    lda #FACINGDIR_DOWN
    sta.w playerData.facingdir_head
    sta.w playerData.facingdir_body
    lda #2
    jsl Player.set_head_frame@upload_frame
    sep #$30
    lda #2
    jsl Player.set_body_frame@upload_frame
    rts

; Set head frame to A
Player.set_head_frame:
    sep #$30
    cmp.w playerData.active_head_frame
    bne @upload_frame
        rtl ; - same frame, no upload
    @upload_frame:
    sta.w playerData.active_head_frame
; upload
    ; inc ops
    rep #$30
    lda.l vqueueNumOps
    asl
    asl
    asl
    tax
    lda.l vqueueNumOps
    inc A
    inc A
    sta.l vqueueNumOps
    ; mode[] = VQUEUE_MODE_VRAM
    sep #$20
    lda #VQUEUE_MODE_VRAM
    sta.l vqueueOps.1.mode,X
    sta.l vqueueOps.2.mode,X
    ; set aAddr bank
    lda #$7F
    sta.l vqueueOps.1.aAddr+2,X
    sta.l vqueueOps.2.aAddr+2,X
    ; aAddr[0] = playerSpriteBuffer + frame×128
    ; aAddr[1] = playerSpriteBuffer + frame×128 + 64
    rep #$30
    lda.w playerData.active_head_frame
    and #$00FF
    xba
    lsr
    clc
    adc #loword(playerSpriteBuffer)
    sta.l vqueueOps.1.aAddr,X
    clc
    adc #64
    sta.l vqueueOps.2.aAddr,X
    ; vAddr[0] = SPRITE1_BASE_ADDR + $0000
    ; vAddr[1] = SPRITE1_BASE_ADDR + $0100
    lda #SPRITE1_BASE_ADDR
    sta.l vqueueOps.1.vramAddr,X
    lda #SPRITE1_BASE_ADDR + $0100
    sta.l vqueueOps.2.vramAddr,X
    ; numBytes[] = 64
    lda #64
    sta.l vqueueOps.1.numBytes,X
    sta.l vqueueOps.2.numBytes,X
; end upload
    rtl

; Set body frame to A
Player.set_body_frame:
    sep #$30
    cmp.w playerData.active_body_frame
    bne @upload_frame
        rtl ; - same frame, no upload
    @upload_frame:
    sta.w playerData.active_body_frame
; upload
    ; inc ops
    rep #$30
    lda.l vqueueNumOps
    asl
    asl
    asl
    tax
    lda.l vqueueNumOps
    inc A
    inc A
    sta.l vqueueNumOps
    ; mode[] = VQUEUE_MODE_VRAM
    sep #$20
    lda #VQUEUE_MODE_VRAM
    sta.l vqueueOps.1.mode,X
    sta.l vqueueOps.2.mode,X
    ; set aAddr bank
    lda #$7F
    sta.l vqueueOps.1.aAddr+2,X
    sta.l vqueueOps.2.aAddr+2,X
    ; aAddr[0] = playerSpriteBuffer + frame×128
    ; aAddr[1] = playerSpriteBuffer + frame×128 + 64
    rep #$30
    lda.w playerData.active_body_frame
    and #$00FF
    xba
    lsr
    clc
    adc #loword(playerSpriteBuffer)
    sta.l vqueueOps.1.aAddr,X
    clc
    adc #64
    sta.l vqueueOps.2.aAddr,X
    ; vAddr[0] = SPRITE1_BASE_ADDR + $0020
    ; vAddr[1] = SPRITE1_BASE_ADDR + $0120
    lda #SPRITE1_BASE_ADDR + $0020
    sta.l vqueueOps.1.vramAddr,X
    lda #SPRITE1_BASE_ADDR + $0120
    sta.l vqueueOps.2.vramAddr,X
    ; numBytes[] = 64
    lda #64
    sta.l vqueueOps.1.numBytes,X
    sta.l vqueueOps.2.numBytes,X
; end upload
    rtl

.DEFINE PLAYER_WALK_TIMER_FRAME_DELAY $0900

_update_player_animation_vx:
    rep #$30
    lda.w player_velocx
    beq @not_moving
    .ABS_A16_POSTLOAD
    clc
    adc.w playerData.walk_timer
    cmp #PLAYER_WALK_TIMER_FRAME_DELAY
    bcs @next_frame
    sta.w playerData.walk_timer
    jmp @upload_frame
@not_moving:
    stz.w playerData.walk_timer
    sep #$20
    stz.w playerData.walk_frame
    jmp @upload_frame
@next_frame:
    stz.w playerData.walk_timer
    sep #$20
    lda.w playerData.walk_frame
    inc A
    cmp #6
    bcc +
        lda #0
    +:
    sta.w playerData.walk_frame
@upload_frame:
    sep #$30
    lda.w playerData.walk_frame
    clc
    adc #24
    jsl Player.set_body_frame
    rep #$30
    lda.w player_velocx
    bpl +
        sep #$20
        lda #%01100000
        sta.w playerData.body_flags 
    +:
    rts

_update_player_animation_vy_up:
    rep #$30
    lda.w player_velocy
    .NEG_A16
    clc
    adc.w playerData.walk_timer
    cmp #PLAYER_WALK_TIMER_FRAME_DELAY
    bcs @next_frame
    sta.w playerData.walk_timer
    jmp @upload_frame
@not_moving:
    stz.w playerData.walk_timer
    sep #$20
    stz.w playerData.walk_frame
    jmp @upload_frame
@next_frame:
    stz.w playerData.walk_timer
    sep #$20
    lda.w playerData.walk_frame
    dec A
    cmp #6
    bcc +
        lda #5
    +:
    sta.w playerData.walk_frame
@upload_frame:
    sep #$30
    lda.w playerData.walk_frame
    clc
    adc #16
    jsl Player.set_body_frame
    rts

_update_player_animation_vy:
    rep #$30
    lda.w player_velocy
    beq @not_moving
    bmil _update_player_animation_vy_up
    clc
    adc.w playerData.walk_timer
    cmp #PLAYER_WALK_TIMER_FRAME_DELAY
    bcs @next_frame
    sta.w playerData.walk_timer
    jmp @upload_frame
@not_moving:
    stz.w playerData.walk_timer
    sep #$20
    stz.w playerData.walk_frame
    jmp @upload_frame
@next_frame:
    stz.w playerData.walk_timer
    sep #$20
    lda.w playerData.walk_frame
    inc A
    cmp #6
    bcc +
        lda #0
    +:
    sta.w playerData.walk_frame
@upload_frame:
    sep #$30
    lda.w playerData.walk_frame
    clc
    adc #16
    jsl Player.set_body_frame
    rts

_update_player_animation:
    sep #$20
    lda.w playerData.anim_wait_timer
    beq +
        dec A
        sta.w playerData.anim_wait_timer
        rts
    +
    lda #%00100000
    sta.w playerData.body_flags
    sta.w playerData.head_flags
    lda #FACINGDIR_DOWN
    sta.w playerData.facingdir_body
    stz.w playerData.head_offset_y
    lda #0
    jsl Player.set_head_frame
    rep #$30
    lda.w player_velocx
    .ABS_A16_POSTLOAD
    sta.b $00
    lda.w player_velocy
    .ABS_A16_POSTLOAD
    cmp.b $00
    bcs @update_y
        sep #$10
        lda.w player_velocx
        beq @nomovex
            ldy #FACINGDIR_RIGHT
            cmp #0
            bpl +
                ldy #FACINGDIR_LEFT
            +:
            sty.w playerData.facingdir_body
        @nomovex:
        jsr _update_player_animation_vx
        jmp @end
    @update_y:
        sep #$10
        lda.w player_velocy
        beq @nomovey
            ldy #FACINGDIR_DOWN
            cmp #0
            bpl +
                ldy #FACINGDIR_UP
            +:
            sty.w playerData.facingdir_body
        @nomovey:
        jsr _update_player_animation_vy
    @end:
    ; update head sprite
    sep #$30
    lda.w playerData.playerItemStackNumber+ITEMID_CHOCOLATE_MILK
    bne @chocolate_milk
; regular
    lda.w playerData.tear_timer+1
    cmp #$1E
    bcc +
        jsr _update_player_head_facing
    +
    sep #$30
    ldy #0
    lda.w playerData.tear_timer+1
    cmp #$1E
    bcs +
        inc.w playerData.head_offset_y
        ldy #4
    +:
    tya
    clc
    adc.w playerData.facingdir_head
    jsl Player.set_head_frame
    rts
@chocolate_milk:
    jsr _update_player_head_facing
    sep #$30
    lda.w playerData.tear_timer+1
    bne +
        lda.w playerData.facingdir_head
        jsl Player.set_head_frame
        rts
    +:
    cmp #$F0
    bcc +
        lda #12
        clc
        adc.w playerData.facingdir_head
        jsl Player.set_head_frame
        rts
    +:
    lda #8
    clc
    adc.w playerData.facingdir_head
    jsl Player.set_head_frame
    rts

_update_player_head_facing:
    rep #$20
    sep #$10
    lda.w joy1held
    bit #(JOY_A|JOY_B|JOY_Y|JOY_X)
    bne +
        ; not facing, use body
        ldy.w playerData.facingdir_body
        sty.w playerData.facingdir_head
        rts
    +:
    bit #JOY_Y
    beq +
        ; face left
        ldy #FACINGDIR_LEFT
        sty.w playerData.facingdir_head
        rts
    +
    bit #JOY_A
    beq +
        ; face right
        ldy #FACINGDIR_RIGHT
        sty.w playerData.facingdir_head
        rts
    +
    bit #JOY_B
    beq +
        ; face down
        ldy #FACINGDIR_DOWN
        sty.w playerData.facingdir_head
        rts
    +
    ; face up
    ldy #FACINGDIR_UP
    sty.w playerData.facingdir_head
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
; check stats
    jsl Item.check_and_recalculate
; remove from partition
    sep #$30
    lda.w player_box_y1
    and #$F0
    sta.b $00
    lda.w player_box_x1
    lsr
    lsr
    lsr
    lsr
    ora.b $00
    sta.b $00
    .REPT 2 INDEX iy
        tax
        .REPT 2 INDEX ix
            .IF ix > 0
                inx
            .ENDIF
            lda #ENTITY_INDEX_PLAYER
            .EraseHitboxLite
        .ENDR
        .IF iy < 1
            lda.b $00
            clc
            adc #16
            sta.b $00
        .ENDIF
    .ENDR
; movement
    rep #$30 ; 16 bit AXY
    lda.w playerData.stat_speed
    sta $00 ; $00 = speed
    ; check (LEFT OR RIGHT) AND (UP OR DOWN)
    ; if so, multiply speed by 3/4; aka (A+A+A) >> 2
    lda.w joy1held
    ; LEFT or RIGHT. 00 = F; 01,10,11 = T
    bit #$0C00
    beq @skip_slow
    bit #$0300
    beq @skip_slow
    lda.b $00
    asl
    clc
    adc $00
    lsr
    lsr
    sta $00 ; $00 = speed * 0.75
@skip_slow:
; Y MOVEMENT
    lda.w joy1held
    bit #JOY_DOWN
    bne @down
    bit #JOY_UP
    bne @up
    ; Y stop
    lda.w player_velocy
    cmp #0
    bpl @slowup
    ; slowdown
    lda.w player_velocy
    clc
    adc.w playerData.stat_accel
    .AMIN P_IMM, $00
    jmp @endy
@slowup:
    ; slowup
    lda.w player_velocy
    sec
    sbc.w playerData.stat_accel
    .AMAX P_IMM, $00
    jmp @endy
@down:
    ; up
    lda.w player_velocy
    clc
    adc.w playerData.stat_accel
    .AMIN P_DIR, $00
    .AMAX P_IMM $00
    jmp @endy
@up:
    ; up
    lda.w player_velocy
    sec
    sbc.w playerData.stat_accel
    eor #$FFFF
    inc A
    .AMIN P_DIR, $00
    eor #$FFFF
    inc A
    .AMIN P_IMM $00
@endy:
    sta.w player_velocy
; X MOVEMENT
    lda.w joy1held
    bit #JOY_RIGHT
    bne @right
    bit #JOY_LEFT
    bne @left
    ; X stop
    lda.w player_velocx
    cmp #0
    bpl @slowleft ; If speed.x > 0
    ; slowright
    lda.w player_velocx
    clc
    adc.w playerData.stat_accel
    .AMIN P_IMM, $00
    jmp @endx
@slowleft:
    ; slowleft
    lda.w player_velocx
    sec
    sbc.w playerData.stat_accel
    .AMAX P_IMM, $00
    jmp @endx
@right:
    ; right
    lda.w player_velocx
    clc
    adc.w playerData.stat_accel
    .AMIN P_DIR, $00
    .AMAX P_IMM $00
    jmp @endx
@left:
    ; left
    lda.w player_velocx
    sec
    sbc.w playerData.stat_accel
    eor #$FFFF
    inc A
    .AMIN P_DIR, $00
    eor #$FFFF
    inc A
    .AMIN P_IMM $00
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
    jsr _update_player_animation
; setup partition
    sep #$30
    ; add to partition
    lda.w player_box_y1
    and #$F0
    sta.b $00
    lda.w player_box_x1
    lsr
    lsr
    lsr
    lsr
    ora.b $00
    sta.b $00
    .REPT 2 INDEX iy
        tax
        lda #ENTITY_INDEX_PLAYER
        .REPT 2 INDEX ix
            .IF ix > 0
                inx
            .ENDIF
            .InsertHitboxLite
        .ENDR
        .IF iy < 1
            lda.b $00
            clc
            adc #16
            sta.b $00
        .ENDIF
    .ENDR
    ; set box pos
    lda.w player_box_x1
    clc
    adc #16
    sta.w player_box_x2
    lda.w player_box_y1
    clc
    adc #8
    sta.w entity_ysort + ENTITY_INDEX_PLAYER
    adc #8
    sta.w player_box_y2
    ; set flags/mask
    lda #ENTITY_MASK_PROJECTILE
    sta.w player_mask
    sep #$30 ; 16b AXY
    lda.w playerData.playerItemStackNumber+ITEMID_CHOCOLATE_MILK
    bnel _player_handle_shoot_chocolate_milk
; handle player shoot
_player_handle_shoot_standard:
    rep #$30 ; 16b AXY
    lda.w playerData.tear_timer
    clc
    adc.w playerData.stat_tear_rate
    sta.w playerData.tear_timer
    cmp #$3C00
    bcc @tear_not_ready
    ; check inputs
    lda.w joy1held
    bit #(JOY_A|JOY_B|JOY_Y|JOY_X)
    beq @player_did_not_fire
    jsr PlayerShootTear
    jsl Tear.set_size_from_damage
    rep #$20
    lda.w playerData.tear_timer
    sec
    sbc #$3C00
    sta.w playerData.tear_timer
    ; .AMINU P_ABS playerData.stat_tear_rate
    ; lda #0
    rts
@player_did_not_fire:
    lda #$3C00
    sta.w playerData.tear_timer
    rts
@tear_not_ready:
    rts

_player_handle_shoot_chocolate_milk:
    rep #$30
    ; check inputs
    lda.w joy1held
    bit #(JOY_A|JOY_B|JOY_Y|JOY_X)
    beq @finish_charge
    sta.w playerData.input_buffer
    ; holding button, so charge up
@keep_charging:
    lda.w playerData.stat_tear_rate
    clc
    adc.w playerData.tear_timer
    cmp #$F000
    bcs @cap_charge ; overshot max
    cmp.w playerData.stat_tear_rate
    bcc @cap_charge ; overshot max and overflowed
    jmp @store_charge
@cap_charge:
    lda #$F000
@store_charge:
    sta.w playerData.tear_timer
    rts
@finish_charge:
    lda.w playerData.tear_timer
    beq @end
    cmp #$0600
    bcc @keep_charging
    ; shoot tear
    lda.w playerData.input_buffer
    sta.w joy1held
    jsr PlayerShootTear
    ; we still have projectile in X
    ; handle bottom byte of damage
    sep #$20
    rep #$10
    lda.w projectile_damage,X
    sta.w MULTU_A
    lda.w playerData.tear_timer+1
    sta.w MULTU_B
    nop ; +2 | 2
    nop ; +2 | 4
    nop ; +2 | 6
    rep #$20 ; +3 | 9
    lda.w MULTU_RESULT
    sta.b $00
    ; top byte of damage
    sep #$20
    lda.w projectile_damage+1,X
    sta.w MULTU_A
    lda.w playerData.tear_timer+1
    sta.w MULTU_B
    nop ; +2 | 2
    nop ; +2 | 4
    nop ; +2 | 6
    rep #$20 ; +3 | 9
    lda.w MULTU_RESULT
    sta.b $02
    ; divide low byte properly
    lda.b $00
    sta.w DIVU_DIVIDEND
    sep #$20
    lda #$3C
    sta.w DIVU_DIVISOR
    ; divide high byte by $3C, multiply by $100. Comes out to ~×4
    ; this may bias high damages to be even higher, but idc
    rep #$20 ;  +3 | 3
    lda.b $02 ; +4 | 7
    asl ;       +2 | 9
    asl ;       +2 | 11
    clc ;       +2 | 13
    stz.w playerData.tear_timer ; +5 | 18
    adc.w DIVU_QUOTIENT
    .AMAXU P_IMM 1
    sta.w projectile_damage,X
    jsl Tear.set_size_from_damage
    ; DAMAGE = projectile_damage * timer / $3C00
    rts
@end:
    rep #$30
    stz.w playerData.tear_timer
    rts

PlayerRender:
    sep #$20
    rep #$10
    ; update render data
    lda.w playerData.invuln_timer
    bit #$08
    bnel @invis_frame
        ldx.w objectIndex
        lda.w player_posx+1
        sta.w objectData.1.pos_x,X
        sta.w objectData.2.pos_x,X
        lda.w player_posy+1
        sta.w objectData.2.pos_y,X
        sec
        sbc #10
        clc
        adc.w playerData.head_offset_y
        sta.w objectData.1.pos_y,X
        stz.w objectData.1.tileid,X
        lda #2
        sta.w objectData.2.tileid,X
        lda.w playerData.head_flags
        sta.w objectData.1.flags,X
        lda.w playerData.body_flags
        sta.w objectData.2.flags,X
        rep #$30 ; 16 bit AXY
        .SetCurrentObjectS_Inc
        .SetCurrentObjectS_Inc
@invis_frame:
    ; put shadow
    sep #$20
    rep #$10
    ldy #ENTITY_INDEX_PLAYER
    pea $0405
    jsl EntityPutShadow
    plx
    rtl

PlayerShootTear:
    sep #$20
    lda #0
    xba
    lda #ENTITY_TYPE_PROJECTILE
    jsl entity_create
    rep #$30 ; 16 bit AXY
    sty.b TempTearIdx
    tyx
; set player info
    ; stz.w playerData.tear_timer
    lda.w playerData.flags
    eor #PLAYER_FLAG_EYE
    sta.w playerData.flags
; set base projectile info
    ; life
    lda.w playerData.stat_tear_lifetime
    sta.w projectile_lifetime,X
    ; size
    lda.w playerData.tearflags
    sta.w projectile_flags,X
    sep #$20
    lda #3
    sta.w projectile_size,X
    ; type
    lda #PROJECTILE_TYPE_PLAYER_BASIC
    sta.w projectile_type,X
    rep #$20
    lda #$0800
    sta.w projectile_height,X
    ; dmg
    lda.w playerData.stat_damage
    sta.w projectile_damage,X
; check direction
    lda.w joy1held
    bit #JOY_Y
    beq +
        brl @tear_left
    +
    bit #JOY_A
    beq +
        brl @tear_right
    +
    bit #JOY_B
    beq +
        brl @tear_down
    +
;tear_up:
    lda.w player_velocx
    sta.w entity_velocx,X
    lda.w player_velocy
    .ShiftRight_SIGN 1, FALSE
    .AMIN P_IMM, $0100 * 0.25
    .AMAX P_IMM, -$0100
    sec
    sbc.w playerData.stat_tear_speed
    sta.w entity_velocy,X
    jmp @vertical
@tear_left:
    lda.w player_velocy
    sta.w entity_velocy,X
    lda.w player_velocx
    .ShiftRight_SIGN 1, FALSE
    .AMIN P_IMM, $0100 * 0.25
    .AMAX P_IMM, -$0100
    sec
    sbc.w playerData.stat_tear_speed
    sta.w entity_velocx,X
    jmp @horizontal
@tear_right:
    lda.w player_velocy
    sta.w entity_velocy,X
    lda.w player_velocx
    .ShiftRight_SIGN 1, FALSE
    .AMAX P_IMM, -$0100 * 0.25
    .AMIN P_IMM, $0100
    clc
    adc.w playerData.stat_tear_speed
    sta.w entity_velocx,X
    jmp @horizontal
@tear_down:
    lda.w player_velocx
    sta.w entity_velocx,X
    lda.w player_velocy
    .ShiftRight_SIGN 1, FALSE
    .AMAX P_IMM, -$0100 * 0.25
    .AMIN P_IMM, $0100
    clc
    adc.w playerData.stat_tear_speed
    sta.w entity_velocy,X
    jmp @vertical
@vertical:
    lda.w playerData.flags
    bit #PLAYER_FLAG_EYE
    bne @vertical_skip
    lda.w player_posx
    sta.w entity_posx,X
    lda.w player_posy
    clc
    adc #256*4
    sta.w entity_posy,X
    rts
@vertical_skip:
    lda.w player_posx
    clc
    adc #256*8
    sta.w entity_posx,X
    lda.w player_posy
    clc
    adc #256*4
    sta.w entity_posy,X
    rts
@horizontal:
    lda.w playerData.flags
    bit #PLAYER_FLAG_EYE
    bne @horizontal_skip
    lda.w player_posx
    clc
    adc #256*4
    sta.w entity_posx,X
    lda.w player_posy
    ; sec
    ; sbc.w #256*1
    sta.w entity_posy,X
    rts
@horizontal_skip:
    lda.w player_posx
    clc
    adc #256*4
    sta.w entity_posx,X
    lda.w player_posy
    clc
    adc.w #256*6
    sta.w entity_posy,X
    rts

PlayerMoveHorizontal:
    .ACCU 16
    .INDEX 16
    lda.w player_velocx
    beq @skipmove
    clc
    adc.w player_posx
    ; EXPANSION OF: .AMAXU P_DIR, $00
        .g_instruction cmp, P_DIR, $00
        bcs +
            .g_instruction lda, P_DIR, $00
            stz.w player_velocx
        +:
    ; EXPANSION OF: .AMINU P_DIR, $02
        .g_instruction cmp, P_DIR, $02
        bcc +
            .g_instruction lda, P_DIR, $02
            stz.w player_velocx
        +:
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
    .AMAXU P_ABS, player_posx
    stz.w player_velocx
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
    .AMINU P_ABS, player_posx
    stz.w player_velocx
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
    ; EXPANSION OF: .AMAXU P_DIR, $04
        .g_instruction cmp, P_DIR, $04
        bcs +
            .g_instruction lda, P_DIR, $04
            stz.w player_velocy
        +:
    ; EXPANSION OF: .AMINU P_DIR, $06
        .g_instruction cmp, P_DIR, $06
        bcc +
            .g_instruction lda, P_DIR, $06
            stz.w player_velocy
        +:
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
    .AMAXU P_ABS, player_posy
    stz.w player_velocy
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
    .AMINU P_ABS, player_posy
    stz.w player_velocy
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
; unload previous room
    jsl Room_Unload
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
        lda.w SVAR
        .IF SREG == BG2VOFS
            clc
            adc #32
        .ENDIF
        tax
        stx SREG+2 ; scroll floor
        xba
        tax
        stx SREG+2 ; scroll floor
        ; Depending on scroll value, upload tile data.
        ; We want to upload the line that has just came into view.
        rep #$20 ; 16 bit A
        .IF SREG == BG2HOFS
        ; right / left
            ; source address = ADDR + column * 8
            ; inc address by 8 each update
            lda.w SVAR
            clc
            .IF AMT > 0
                adc #216
            .ELSE
                adc #224
            .ENDIF
            and #$00F8
            cmp #24*8
            bcc +
                jmp @skipUpload
            +:
            sta.b $00
            sep #$20 ; 8 bit A
            ; source bank
            lda.w currentRoomGroundData+2
            sta DMA0_SRCH
            ; VRAM address increment flags
            lda #$80
            sta VMAIN
            ; write to PPU, absolute address, auto increment, 2 bytes at a time
            lda #%00000001
            sta DMA0_CTL
            ; Write to VRAM
            lda #$18
            sta DMA0_DEST
            ; begin transfer
            rep #$30
            .REPT 16 INDEX i
                rep #$20
                    lda.b $00
                    clc
                    adc #(8 * 24 * i) + BG3_CHARACTER_BASE_ADDR
                    sta VMADDR
                    lda.b $00
                    asl
                    clc
                    adc #(16 * 24 * i)
                    clc
                    adc.w currentRoomGroundData
                    sta DMA0_SRCL
                ; number of bytes
                lda #8 * 2
                sta DMA0_SIZE
                sep #$20
                lda #$0001
                sta MDMAEN
            .ENDR
            ; next, clear tile data to defaults
            lda #$81
            sta VMAIN
            rep #$30
            lda.b $00
            lsr
            lsr
            lsr
            clc
            adc #$0104 + BG3_TILE_BASE_ADDR
            sta VMADDR
            lda.b $00
            lsr
            lsr
            lsr
            ora.w currentRoomGroundPalette
            .REPT 16
                sta VMDATA
                clc
                adc #24
            .ENDR
        .ELIF SREG == BG2VOFS
        ; up / down
            ; number of bytes
            lda #24 * 8 * 2
            sta DMA0_SIZE
            ; source address = ADDR + row * 24 * 8
            lda.w SVAR
            clc
            .IF AMT > 0
                adc #184
            .ELSE
                adc #224
            .ENDIF
            and #$00F8
            cmp #16*8
            bcc + 
                jmp @skipUpload
            +:
            sta.b $02
            asl
            asl
            asl
            sta.b $00
            asl
            clc
            adc.b $00
            sta.b $00
            asl
            clc
            adc.w currentRoomGroundData
            sta DMA0_SRCL
            ; VRAM address
            lda.b $00
            clc
            adc #BG3_CHARACTER_BASE_ADDR
            sta VMADDR
            sep #$20 ; 8 bit A
            ; source bank
            lda.w currentRoomGroundData+2
            sta DMA0_SRCH
            ; VRAM address increment flags
            lda #$80
            sta VMAIN
            ; write to PPU, absolute address, auto increment, 2 bytes at a time
            lda #%00000001
            sta DMA0_CTL
            ; Write to VRAM
            lda #$18
            sta DMA0_DEST
            ; begin transfer
            lda #$01
            sta MDMAEN
            ; update tiles
            rep #$20
            lda.b $02
            asl
            asl
            clc
            adc #$0104 + BG3_TILE_BASE_ADDR
            sta VMADDR
            lda.b $02
            clc
            asl
            adc $02
            ora.w currentRoomGroundPalette
            .REPT 24
                sta VMDATA
                inc A
            .ENDR
        .ENDIF
        @skipUpload:
        ; Upload objects to OAM
        rep #$20
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
        beq +
        jmp @loopWait
        +:
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
    rep #$30
    phb
    ; loop
    .REPT 8 INDEX i
        ldx #loword(InitialPathfindingData) + 16 * 4 + 2 + (16 * i)
        ldy #loword(pathfind_player_data) + 16 * 4 + 2 + (16 * i)
        lda #11
        mvn bankbyte(InitialPathfindingData), bankbyte(pathfind_player_data)
    .ENDR
    ; end
    plb
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