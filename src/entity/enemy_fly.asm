.include "base.inc"

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Enemy Fly" FREE

.DEFINE _fly_fgxptr.1 loword(entity_char_custom.1)
.DEFINE _fly_fgxptr.2 loword(entity_char_custom.2)

.DEFINE BASE_HEALTH 24

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "entity_basic_fly_init", "IEntityInit"
    .SoftSetA 16
    .SoftSetX 16
    inc.w currentRoomEnemyCount
    ; default info
    tyx
    .ForceSetA 8
    lda.l RandTable,X
    sta.w entity_timer,Y
    .ForceSetA 16
    lda #BASE_HEALTH
    sta.w entity_health,Y
    lda #ENTITY_FLAGS_NEAREST_ENEMY_TARGET
    sta.w loword(entity_flags),Y
    ; load sprite
    lda #sprite.enemy.attack_fly.0
    phy
    jsl Spriteman.NewSpriteRef
    .ForceSetAX 16, 16
    ply
    txa
    sta.w _fly_fgxptr.1,Y
    ; load frame 2
    lda #sprite.enemy.attack_fly.1
    phy
    jsl Spriteman.NewSpriteRef
    .ForceSetAX 16, 16
    ply
    txa
    sta.w _fly_fgxptr.2,Y
    ; end
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "entity_basic_fly_tick", "IEntityTick"
; check signal
    .ForceSetAX 8, 8
    lda #ENTITY_SIGNAL_KILL
    and.w entity_signal,Y
    beq +
        ; We have perished
        jsl Entity.PutSplatter
        .PushContext
        .ForceSetAX 16, 16
        .call "Entity.Free"
        rts
        .PopContextSoft
    +:
; move
    jsl Entity.Enemy.DirectTargetPlayer
    lda.b entityTargetFound
    beq @no_target
        ldx.b entityTargetAngle
        lda.l SinTable8,X
        .Convert8To16_SIGNED 0, 0
        .ShiftRight_SIGN 2, 0
        clc
        adc.w entity_posy,Y
        sta.w entity_posy,Y
        .ForceSetA 8
        lda.l CosTable8,X
        .Convert8To16_SIGNED 0, 0
        .ShiftRight_SIGN 2, 0
        clc
        adc.w entity_posx,Y
        sta.w entity_posx,Y
    @no_target:
    ; apply velocity
    .ForceSetA 16
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
    .ForceSetAX 8, 8
    ldx.w entity_timer,Y
    lda.l SinTable8,X
    .ShiftRight_SIGN 2, 0
    .Convert8To16_SIGNED 0, 0
    clc
    adc.w entity_posx,Y
    sta.w entity_posx,Y
    .ForceSetA 8
    lda.l CosTable8,X
    .ShiftRight_SIGN 2, 0
    .Convert8To16_SIGNED 0, 0
    clc
    adc.w entity_posy,Y
    sta.w entity_posy,Y
    ; set box
    .ForceSetAX 8, 8
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
    .ForceSetA 16
    lda #0
    .ForceSetA 8
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
    .OX_Get
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
    .ForceSetAX 16, 16
    .OX_Next_S
    ; put shadow
    .SetAX 8, 16
    pea $0404
    .call "Entity.Shadow.PutSmall"
    plx
    ; Check collision with player
    jsl Entity.Enemy.TickContactDamage
@no_player_col:
    ; end
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "entity_basic_fly_free", "IEntityFree"
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
.endproc

.ENDS
