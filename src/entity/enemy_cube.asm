.include "base.inc"

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Enemy Cube" FREE

.DEFINE BASE_HEALTH 12

.DEFINE _gfxptr.1 loword(entity_char_custom.1)
.DEFINE _gfxptr.2 loword(entity_char_custom.2)
.DEFINE _gfxptr.3 loword(entity_char_custom.3)
.DEFINE _gfxptr.4 loword(entity_char_custom.4)

.DEFINE _current_frame loword(entity_char_custom.5)

.DEFINE _tmp_entityid $10

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
    sta.w entity_timer,Y
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
    ; put initial sprite
    rep #$30
    lda #0
    jsr _set_frame
    ; end
    rts

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
        jsl EntityPutSplatter
        jsl entity_free
        rts
    +:
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
    lda #%00100001
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
    rts

.ENDS
