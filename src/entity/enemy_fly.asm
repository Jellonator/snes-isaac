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
    tyx
    sep #$20
    lda.l RandTable,X
    sta.w entity_timer,Y
    rep #$20
    lda #BASE_HEALTH
    sta.w entity_health,Y
    ; load sprite
    lda #sprite.enemy.attack_fly.0
    phy
    jsl Spriteman.NewSpriteRef
    rep #$30
    ply
    txa
    sta.w _fly_fgxptr.1,Y
    ; load frame 2
    lda #sprite.enemy.attack_fly.1
    phy
    jsl Spriteman.NewSpriteRef
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
    jsl Entity.Enemy.DirectTargetPlayer
    sep #$30
    lda.b entityTargetFound
    beq @no_target
        ldx.b entityTargetAngle
        lda.l SinTable8,X
        .Convert8To16_SIGNED 0, 0
        .ShiftRight_SIGN 2, 0
        clc
        adc.w entity_posy,Y
        sta.w entity_posy,Y
        sep #$20
        lda.l CosTable8,X
        .Convert8To16_SIGNED 0, 0
        .ShiftRight_SIGN 2, 0
        clc
        adc.w entity_posx,Y
        sta.w entity_posx,Y
    @no_target:
    ; apply velocity
    rep #$20
    lda.w entity_velocx,Y
    clc
    adc.w entity_posx,Y
    sta.w entity_posx,Y
    lda.w entity_velocy,Y
    clc
    adc.w entity_posy,Y
    sta.w entity_posy,Y
    ; reduce velocity
    lda.w entity_velocx,Y
    .ShiftRight_SIGN 1, 0
    sta.w entity_velocx,Y
    lda.w entity_velocy,Y
    .ShiftRight_SIGN 1, 0
    sta.w entity_velocy,Y
    ; randomish movement
    sep #$30
    ldx.w entity_timer,Y
    lda.l SinTable8,X
    .ShiftRight_SIGN 2, 0
    .Convert8To16_SIGNED 0, 0
    clc
    adc.w entity_posx,Y
    sta.w entity_posx,Y
    sep #$20
    lda.l CosTable8,X
    .ShiftRight_SIGN 2, 0
    .Convert8To16_SIGNED 0, 0
    clc
    adc.w entity_posy,Y
    sta.w entity_posy,Y
    ; set box
    sep #$30 ; 8B AXY
    lda.w entity_box_x1,Y
    clc
    adc #15
    sta.w entity_box_x2,Y
    lda.w entity_box_y1,Y
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
    jsl Entity.Enemy.TickContactDamage
@no_player_col:
    ; end
    rts

entity_basic_fly_free:
    .ACCU 16
    .INDEX 16
    dec.w currentRoomEnemyCount
    lda #0
    sta.w entity_mask,Y
    ldx.w _fly_fgxptr.1,Y
    phy
    php
    jsl Spriteman.UnrefSprite
    plp
    ply
    lda.w _fly_fgxptr.2,Y
    tax
    jsl Spriteman.UnrefSprite
    rts

.ENDS
