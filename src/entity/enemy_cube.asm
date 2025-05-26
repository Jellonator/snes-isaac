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

_frame_index_topleft:
    .db $10
    .db $10
    .db $10
    .db $10
    .db $12
    .db $12
    .db $12
    .db $12
    .db $08
    .db $08
    .db $08
    .db $08
    .db $08
    .db $09
    .db $0A
    .db $0B

_frame_index_topright:
    .db $11
    .db $11
    .db $11
    .db $11
    .db $13
    .db $13
    .db $13
    .db $13
    .db $14
    .db $14
    .db $14
    .db $14
    .db $14
    .db $14
    .db $14
    .db $14

_frame_index_bottomleft:
    .db $00
    .db $01
    .db $02
    .db $03
    .db $04
    .db $05
    .db $06
    .db $07
    .db $0C
    .db $0D
    .db $0E
    .db $0F
    .db $0C
    .db $0C
    .db $0C
    .db $0C

_frame_index_bottom_right:
    .db $15
    .db $15
    .db $15
    .db $15
    .db $17
    .db $17
    .db $17
    .db $17
    .db $16
    .db $16
    .db $16
    .db $16
    .db $16
    .db $16
    .db $16
    .db $16

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
    ; upload sprite
    .REPT 4 INDEX i
        ldx.w _current_frame,Y
        lda.l _frame_index_topleft + 16*i - 1,X
        and #$FF00
        lsr
        clc
        adc #loword(spritedata.enemy.isaac_cube)
        pha
        clc
        adc #64
        pha
        lda.w _gfxptr.{i+1},Y
        tax
        jsl Spriteman.WriteSpriteToRawSlot
        ldy.b _tmp_entityid
        rep #$30
        pla
        pla
    .ENDR
    ; pla
    ; pla
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
    rep #$20
    lda #ENTITY_FLAGS_BLOCKING
    sta.w loword(entity_flags),Y
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
    sta.b $14 ; $14 - TILE
    tax
    lda.w pathfind_player_data,X
    tax
    lda.l PathValid,X
    beql @not_valid
        ; Check Orthagonal horizontal
        stx.b $12 ; $12 - DIRECTION (ORIGINAL)
        lda.l PathOrthagonal_H,X
        sta.b $16 ; $16 - DIRECTION (NEW)
        tax
        lda.l Path_TileOffset,X
        clc
        adc.b $14
        tay
        lda #ENTITY_FLAGS_BLOCKING
        .REPT SPATIAL_LAYER_COUNT INDEX i
            ldx.w spatial_partition.{i+1},Y
            beq @valid_dir
            bit.w loword(entity_flags),X
            bne @invalid_h
        .ENDR
        jmp @valid_dir
    @invalid_h:
        ; Check orthagonal vertical
        ldx.b $12
        lda.l PathOrthagonal_V,X
        sta.b $16
        tax
        lda.l Path_TileOffset,X
        clc
        adc.b $14
        tay
        lda #ENTITY_FLAGS_BLOCKING
        .REPT SPATIAL_LAYER_COUNT INDEX i
            ldx.w spatial_partition.{i+1},Y
            beq @valid_dir
            bit.w loword(entity_flags),X
            bne @not_valid
        .ENDR
    @valid_dir:
        ; Insert into spatial partition, to prevent same-frame bugs
        lda.b _tmp_entityid
        .InsertHitboxLite_Y
        tay
        ; set direction, properly
        lda.b $16
        sta.w _current_direction,Y
        lda #STATE_MOVE_START
        sta.w entity_state,Y
        lda #3 ; 4-1 for timer since we do movement on this tick as well
        sta.w entity_timer,Y
        ; handle one tick of movement
        jmp _handle_directional_movement
@not_valid:
    ldy.b _tmp_entityid
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
    sbc #3
    sta.w objectData.1.pos_x,X
    sta.w objectData.3.pos_x,X
    clc
    adc #16
    sta.w objectData.2.pos_x,X
    sta.w objectData.4.pos_x,X
    ; y pos
    lda.w _current_frame,Y
    cmp #8
    bcc @lower_y
        lda.w entity_box_y1,Y
        clc
        adc #6
        bra @upper_y
    @lower_y:
        lda.w entity_box_y1,Y
    @upper_y:
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
    jsl Entity.Enemy.TickContactDamage
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
        jsl Spriteman.FreeRawSlot
        rep #$30
        ldy.b _tmp_entityid
    .ENDR
    ; free palette
    ldx.w _palette,Y
    jsl Palette.free
    rts

.ENDS
