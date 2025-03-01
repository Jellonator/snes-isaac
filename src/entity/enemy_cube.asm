.include "base.inc"

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Enemy Cube" FREE

.DEFINE BASE_HEALTH 64

.DEFINE _gfxptr.1 loword(entity_char_custom.1)
.DEFINE _gfxptr.2 loword(entity_char_custom.2)
.DEFINE _gfxptr.3 loword(entity_char_custom.3)
.DEFINE _gfxptr.4 loword(entity_char_custom.4)

.DEFINE _current_frame loword(entity_char_custom.5)
.DEFINE _current_direction loword(entity_char_custom.6)
.DEFINE _current_rotation loword(entity_char_custom.7)
.DEFINE _palette loword(entity_char_custom.8)

.DEFINE _tmp_entityid $10

.DEFINE STATE_IDLE 0
.DEFINE STATE_MOVE_START 2
.DEFINE STATE_MOVE_MID 4
.DEFINE STATE_MOVE_END 6

; set frame to A
_set_frame:
    .ACCU 16
    .INDEX 16
    ; setup
    cmp.w _current_frame,Y
    bne +
        rts
    +:
    sta.w _current_frame,Y
    pea bankbyte(spritedata.enemy.isaac_cube) * $0101
    .MultiplyStatic 512
    clc
    adc #loword(spritedata.enemy.isaac_cube)
    pha
    adc #128
    pha
    ; upload sprite
    .REPT 4 INDEX i
        .IF i == 1 || i == 3
            plx
            pla
            clc
            adc #64
            pha
            txa
            clc
            adc #64
            pha
        .ELIF i == 2
            plx
            pla
            clc
            adc #192
            pha
            txa
            clc
            adc #192
            pha
        .ENDIF
        lda.w _gfxptr.{i+1},Y
        tax
        jsl spriteman_write_sprite_to_raw_slot
        ldy.b _tmp_entityid
        rep #$30
    .ENDR
    pla
    pla
    pla
    rts

entity_enemy_cube_init:
    .ACCU 16
    .INDEX 16
    inc.w currentRoomEnemyCount
    ; setup
    lda #$FFFF
    sta.w _current_frame,Y
    sty.b _tmp_entityid
    ; default info
    lda #BASE_HEALTH
    sta.w entity_health,Y
    ; get sprite slots
    sep #$30
    .REPT 4 INDEX i
        .spriteman_get_raw_slot_lite
        ldy.b _tmp_entityid
        txa
        sta.w _gfxptr.{i+1},Y
        lda #0
        sta.w _gfxptr.{i+1}+1,Y
    .ENDR
    ; load palette
    rep #$30
    ldy #loword(palettes.enemy.isaac_cube)
    lda #10
    jsl Palette.find_or_upload_opaque
    rep #$30
    ldy.b _tmp_entityid
    txa
    sta.w _palette,Y
    ; TODO: put sprite into shared RAM and swizzle it
    ; put initial sprite
    rep #$30
    lda #0
    jsr _set_frame
    ; put initial values
    sep #$30
    lda #16
    sta.w entity_timer,Y
    lda #0
    sta.w entity_state,Y
    sta.w _current_rotation,Y
    ; end
    rts

_state_idle:
    .ACCU 8
    .INDEX 8
    lda.w entity_timer,Y
    beq @allow_next_dir
        dec A
        sta.w entity_timer,Y
        rts
@allow_next_dir:
    ; determine direction
    lda.w entity_box_x1,Y
    .ShiftRight 4
    sta.b $00
    lda.w entity_box_y1,Y
    and #$F0
    ora.b $00
    tax
    lda.w pathfind_player_data,X
    tax
    lda.l PathValid,X
    beq @not_valid
        ; orthagonalize
        lda.l PathOrthagonal,X
        sta.w _current_direction,Y
        lda #STATE_MOVE_START
        sta.w entity_state,Y
        lda #4
        sta.w entity_timer,Y
@not_valid:
    rts

_midframes_by_direction:
    .db  0 ; PATH_DIR_NULL
    .db  8 ; PATH_DIR_DOWN
    .db  4 ; PATH_DIR_RIGHT
    .db  4 ; PATH_DIR_LEFT
    .db 12 ; PATH_DIR_UP
    .db  0 ; PATH_DIR_UPLEFT
    .db  0 ; PATH_DIR_UPRIGHT
    .db  0 ; PATH_DIR_DOWNLEFT
    .db  0 ; PATH_DIR_DOWNRIGHT
    .db  0 ; PATH_DIR_NONE

_state_move_start:
    .ACCU 8
    .INDEX 8
    lda.w entity_timer,Y
    dec A
    sta.w entity_timer,Y
    bne @continue
        lda #STATE_MOVE_MID
        sta.w entity_state,Y
        lda #8
        sta.w entity_timer,Y
        ; handle rotation
        lda.w _current_direction,Y
        cmp #PATH_DIR_LEFT
        beq @left
        jmp @no_dir
        @left:
            lda.w _current_rotation,Y
            dec A
            and #$03
            sta.w _current_rotation,Y
        @no_dir:
        ; set frame
        rep #$30
        lda.w _current_direction,Y
        and #$00FF
        tax
        lda.l _midframes_by_direction,X
        clc
        adc.w _current_rotation,Y
        and #$00FF
        jsr _set_frame
        sep #$30
@continue:
    jmp _handle_directional_movement

_state_move_mid:
    .ACCU 8
    .INDEX 8
    lda.w entity_timer,Y
    dec A
    sta.w entity_timer,Y
    bne @continue
        lda #STATE_MOVE_END
        sta.w entity_state,Y
        lda #4
        sta.w entity_timer,Y
        ; handle rotation
        lda.w _current_direction,Y
        cmp #PATH_DIR_DOWN
        beq @reset_rot
        cmp #PATH_DIR_UP
        beq @reset_rot
        cmp #PATH_DIR_RIGHT
        beq @right
        jmp @keep_rot
        @reset_rot:
            lda #0
            sta.w _current_rotation,Y
            jmp @keep_rot
        @right:
            lda.w _current_rotation,Y
            inc A
            and #$03
            sta.w _current_rotation,Y
        @keep_rot:
        ; set frame
        rep #$30
        lda.w _current_rotation,Y
        and #$00FF
        jsr _set_frame
        sep #$30
@continue:
    jmp _handle_directional_movement

_state_move_end:
    .ACCU 8
    .INDEX 8
    lda.w entity_timer,Y
    dec A
    sta.w entity_timer,Y
    bne @continue
        lda #STATE_IDLE
        sta.w entity_state,Y
        lda #8
        sta.w entity_timer,Y
@continue:
    jmp _handle_directional_movement

_handle_directional_movement:
    .ACCU 8
    .INDEX 8
    ldx.w _current_direction,Y
    lda.l Path_X,X
    clc
    adc.w entity_box_x1,Y
    sta.w entity_box_x1,Y
    lda.l Path_Y,X
    clc
    adc.w entity_box_y1,Y
    sta.w entity_box_y1,Y
    rts

_funclist_state:
    .dw _state_idle
    .dw _state_move_start
    .dw _state_move_mid
    .dw _state_move_end

entity_enemy_cube_tick:
    .ACCU 16
    .INDEX 16
    sty.b _tmp_entityid
; check signal
    sep #$30 ; 8B AXY
    lda #ENTITY_SIGNAL_KILL
    and.w entity_signal,Y
    beq +
        ; We have perished
        lda.w entity_box_y1,Y
        clc
        adc #12
        sta.w entity_box_y1,Y
        jsl EntityPutSplatter
        jsl entity_free
        rts
    +:
; AI
    lda.w loword(entity_damageflash),Y
    bne @no_tick
    sep #$30
    lda #1
    bit.w tickCounter
    beq @no_tick
    ldx.w entity_state,Y
    jsr (_funclist_state,X)
    @no_tick:
; draw
    sep #$20
    rep #$10
    ldx.w objectIndex
    ; x pos
    lda.w entity_box_x1,Y
    sec
    sbc #4
    sta.w objectData.1.pos_x,X
    sta.w objectData.3.pos_x,X
    clc
    adc #16
    sta.w objectData.2.pos_x,X
    sta.w objectData.4.pos_x,X
    ; y pos
    lda.w entity_box_y1,Y
    sta.w objectData.3.pos_y,X
    sta.w objectData.4.pos_y,X
    sec
    sbc #16
    sta.w objectData.1.pos_y,X
    sta.w objectData.2.pos_y,X
    ; flags
    lda.w _palette,Y
    .PaletteIndexToPaletteSpriteA
    ora #%00100001
    xba
    lda.w loword(entity_damageflash),Y
    beq +
        dec A
        sta.w loword(entity_damageflash),Y
        xba
        lda #%00101111
        xba
    +:
    xba
    sta.w objectData.1.flags,X
    sta.w objectData.2.flags,X
    sta.w objectData.3.flags,X
    sta.w objectData.4.flags,X
    ; tiles
    stx.b $02
    .REPT 4 INDEX i
        ldx.w _gfxptr.{i+1},Y
        lda.l SpriteSlotIndexTable,X
        ldx.b $02
        sta.w objectData.{i+1}.tileid,X
    .ENDR
    rep #$30
    .REPT 4
        .SetCurrentObjectS_Inc
    .ENDR
    ldy.b _tmp_entityid
; insert hitbox
    sep #$20
    lda #ENTITY_MASKSET_ENEMY
    sta.w entity_mask,Y
    lda #0
    sta.w entity_signal,Y
    lda.w entity_box_x1,Y
    clc
    adc #16
    sta.w entity_box_x2,Y
    lda.w entity_box_y1,Y
    sta.w loword(entity_ysort),Y
    clc
    adc #16
    sta.w entity_box_y2,Y
; Check collision with player
    sep #$20
    lda.w player_box_x1
    clc
    adc #8 ; ACC = player center x
    cmp.w entity_box_x1,Y
    bmi @no_player_col
    cmp.w entity_box_x2,Y
    bpl @no_player_col
    lda.w player_box_y1
    clc
    adc #8
    cmp.w entity_box_y1,Y
    bmi @no_player_col
    cmp.w entity_box_y2,Y
    bpl @no_player_col
    rep #$20
    dec.w player_damageflag
@no_player_col:
    ; end
    rts

entity_enemy_cube_free:
    .ACCU 16
    .INDEX 16
    dec.w currentRoomEnemyCount
    sty.b _tmp_entityid
    .REPT 4 INDEX i
        ldx.w _gfxptr.{i+1},Y
        jsl spriteman_free_raw_slot
        rep #$30
        ldy.b _tmp_entityid
    .ENDR
    ; free palette
    ldx.w _palette,Y
    jsl Palette.free
    rts

.ENDS
