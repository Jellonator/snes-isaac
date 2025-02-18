.include "base.inc"

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Enemy Fly" FREE

.DEFINE _fly_fgxptr.1 loword(entity_char_custom.1)
.DEFINE _fly_fgxptr.2 loword(entity_char_custom.2)

.DEFINE BASE_HEALTH 12

entity_basic_fly_init:
    .ACCU 16
    .INDEX 16
    inc.w currentRoomEnemyCount
    ; default info
    tya
    sta.w entity_timer,Y
    lda #BASE_HEALTH
    sta.w entity_health,Y
    ; load sprite
    lda #sprite.enemy.attack_fly.0
    phy
    jsl spriteman_new_sprite_ref
    rep #$30
    ply
    txa
    sta.w _fly_fgxptr.1,Y
    ; load frame 2
    lda #sprite.enemy.attack_fly.1
    phy
    jsl spriteman_new_sprite_ref
    rep #$30
    ply
    txa
    sta.w _fly_fgxptr.2,Y
    ; end
    rts

entity_basic_fly_tick:
    .ACCU 16
    .INDEX 16
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
; move
    ; TO PLAYER
    lda.w player_box_x1
    sec
    sbc.w entity_box_x1,Y
    ror
    eor #$80
    bmi +
        adc #15
    +:
    and #$F0
    sta.b $02
    lda.w player_box_y1
    sec
    sbc.w entity_box_y1,Y
    ror
    eor #$80
    bmi +
        adc #15
    +:
    lsr
    lsr
    lsr
    lsr
    ora.b $02
    tax
    rep #$20
    lda.l VecNormTableB_X,X
    and #$00FF
    cmp #$80
    php
    lsr
    lsr
    plp
    bcc +
        ora #$FFC0
    +:
    sta.b $06 ; $02: Norm X
    lda.l VecNormTableB_Y,X
    and #$00FF
    cmp #$80
    php
    lsr
    lsr
    plp
    bcc +
        ora #$FFC0
    +:
    sta.b $04 ; $04: Norm Y
    sep #$20
    ; RAND X
    stz.b $01
    ldx.w entity_timer,Y
    lda.l CosTableB,X
    php
    lsr
    lsr
    plp
    bpl +
        dec $01
        ora #$C0
    +:
    sta.b $00
    rep #$20
    lda.w entity_posx,Y
    ; Apply X
    clc
    adc.b $00
    clc
    adc.b $06
    sta.w entity_posx,Y
    sep #$30 ; 8B AXY
    xba
    clc
    adc #15
    sta.w entity_box_x2,Y
    ; RAND Y
    stz.b $01
    ldx.w entity_timer,Y
    lda.l SinTableB,X
    php
    lsr
    lsr
    plp
    bpl +
        dec $01
        ora #$C0
    +:
    sta.b $00
    rep #$20
    lda.w entity_posy,Y
    ; Apply Y
    clc
    adc.b $00
    clc
    adc.b $04
    sta.w entity_posy,Y
    sep #$30 ; 8B AXY
    xba
    clc
    adc #8
    sta.w loword(entity_ysort),Y
    adc #7
    sta.w entity_box_y2,Y
; load & set gfx
    rep #$20
    lda #0
    sep #$20
    ldx.w _fly_fgxptr.1,Y
    lda.w entity_timer,Y
    dec A
    sta.w entity_timer,Y
    and #$08
    beq +
        ldx.w _fly_fgxptr.2,Y
    +:
    lda.w loword(spriteTableValue + spritetab_t.spritemem),X
    tax
    lda.l SpriteSlotIndexTable,X
    ldx.w objectIndex
    sta.w objectData.1.tileid,X
    lda.w entity_posx + 1,Y
    sta.w objectData.1.pos_x,X
    lda.w entity_posy + 1,Y
    sec
    sbc #8
    sta.w objectData.1.pos_y,X
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
    ; set some flags
    lda #ENTITY_MASKSET_ENEMY
    sta.w entity_mask,Y
    lda #0
    sta.w entity_signal,Y
    ; inc object index
    rep #$30
    phy
    .SetCurrentObjectS
    ply
    ; put shadow
    sep #$20
    rep #$10
    ldx.w objectIndex
    inx
    inx
    inx
    inx
    stx.w objectIndex
    pea $0404
    jsl EntityPutShadow
    plx
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

entity_basic_fly_free:
    .ACCU 16
    .INDEX 16
    dec.w currentRoomEnemyCount
    lda #0
    sta.w entity_mask,Y
    lda.w _fly_fgxptr.1,Y
    tax
    phy
    php
    jsl spriteman_unref
    plp
    ply
    lda.w _fly_fgxptr.2,Y
    tax
    jsl spriteman_unref
    rts

.ENDS
