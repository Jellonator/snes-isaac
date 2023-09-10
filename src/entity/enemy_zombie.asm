.include "base.inc"

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Enemy Zombie" FREE

.DEFINE _zombie_gfxptr.1 entity_char_custom.1
.DEFINE _zombie_gfxptr.2 entity_char_custom.2

entity_zombie_init:
    .ACCU 16
    .INDEX 16
    inc.w currentRoomEnemyCount
    ; default info
    tya
    sta.w entity_timer,Y
    lda #10
    sta.w entity_health,Y
    sep #$20
    lda #0
    ; sta.w entitycharacterdata_t.status_effects
    sta.w entity_signal,Y
    sta.w entity_mask,Y
    ; VARIANT 0: headless
    ; VARIANT 1: headed
    lda #1
    sta.w entity_variant,Y
    rep #$20
    ; load frame 1
    lda #sprite.enemy.zombie.0
    phy
    jsl spriteman_new_sprite_ref
    rep #$30
    ply
    txa
    sta.w _zombie_gfxptr.1,Y
    ; load frame 2
    lda #sprite.enemy.zombie.1
    phy
    jsl spriteman_new_sprite_ref
    rep #$30
    ply
    txa
    sta.w _zombie_gfxptr.2,Y
    ; end
    rts

.DefinePathSpeedTable "_e_zombie_speedtable", 128, 1
.DEFINE ZOMBIE_ACCEL 4

entity_zombie_tick:
    .ACCU 16
    .INDEX 16
; Remove col
    sep #$30 ; 8B AXY
    .EntityRemoveHitbox 2, 2
; check signal
    lda #ENTITY_SIGNAL_KILL
    and.w entity_signal,Y
    beq @not_kill
        phy
        jsl EntityPutSplatter
        sep #$30
        ply
        lda.w entity_variant,Y
        bne @not_headless
            ; We have perished
            jsl entity_free
            rts
        @not_headless:
        lda #0
        sta.w entity_variant,Y
        rep #$20
        lda #10
        sta.w entity_health,Y
    @not_kill:
; move
    sep #$30
    lda.w entity_posx+1,Y
    adc #8
    lsr
    lsr
    lsr
    lsr
    sta.b $00
    lda.w entity_posy+1,Y
    adc #8
    and #$F0
    ora.b $00
    tax
    lda.w pathfind_player_data,X
    rep #$30
    and #$00FF
    asl
    tax
    ; X
    lda.w entity_velocx,Y
    .CMPS_BEGIN P_LONG_X, _e_zombie_speedtable_X
        ; velocx < target
        lda.w entity_velocx,Y
        clc
        adc #ZOMBIE_ACCEL
        .AMIN P_LONG_X, _e_zombie_speedtable_X
        .AMAX P_IMM, -$0040
    .CMPS_GREATER
        ; velocx > target
        lda.w entity_velocx,Y
        sec
        sbc #ZOMBIE_ACCEL
        .AMAX P_LONG_X, _e_zombie_speedtable_X
        .AMIN P_IMM, $0040
    .CMPS_EQUAL
        .AMAX P_IMM, -$0100
        .AMIN P_IMM, $0100
    .CMPS_END
    sta.w entity_velocx,Y
    clc
    adc.w entity_posx,Y
    sta.w entity_posx,Y
    ; Y
    lda.w entity_velocy,Y
    .CMPS_BEGIN P_LONG_X, _e_zombie_speedtable_Y
        ; velocx < target
        lda.w entity_velocy,Y
        clc
        adc #ZOMBIE_ACCEL
        .AMIN P_LONG_X, _e_zombie_speedtable_Y
        .AMAX P_IMM, -$0040
    .CMPS_GREATER
        ; velocx > target
        lda.w entity_velocy,Y
        sec
        sbc #ZOMBIE_ACCEL
        .AMAX P_LONG_X, _e_zombie_speedtable_Y
        .AMIN P_IMM, $0040
    .CMPS_EQUAL
        .AMAX P_IMM, -$0100
        .AMIN P_IMM, $0100
    .CMPS_END
    sta.w entity_velocy,Y
    clc
    adc.w entity_posy,Y
    sta.w entity_posy,Y
; load & set gfx
    rep #$30
    lda #0
    sep #$20
    ldx.w _zombie_gfxptr.1,Y
    lda.w loword(spriteTableValue + spritetab_t.spritemem),X
    tax
    lda.l SpriteSlotIndexTable,X
    sta.b $00

    ldx.w _zombie_gfxptr.2,Y
    lda.w loword(spriteTableValue + spritetab_t.spritemem),X
    tax
    lda.l SpriteSlotIndexTable,X
    sta.b $01
    
    lda.w entity_variant,Y
    beq @headless
        ldx.w objectIndex
        lda.b $01
        sta.w objectData.2.tileid,X
        lda.w entity_posx + 1,Y
        sta.w objectData.1.pos_x,X
        sta.w objectData.2.pos_x,X
        lda.w entity_posy + 1,Y
        sta.w objectData.2.pos_y,X
        sec
        sbc #10
        sta.w objectData.1.pos_y,X
        lda #%00100001
        sta.w objectData.1.flags,X
        sta.w objectData.2.flags,X
        lda.b $00
        sta.w objectData.1.tileid,X
        bra +
    @headless:
        ldx.w objectIndex
        lda.b $01
        sta.w objectData.1.tileid,X
        lda.w entity_posx + 1,Y
        sta.w objectData.1.pos_x,X
        lda.w entity_posy + 1,Y
        sta.w objectData.1.pos_y,X
        lda #%00100001
        sta.w objectData.1.flags,X
    +
    ; add to partition
    sep #$30
    .EntityAddHitbox 2, 2
    lda.w entity_box_x1,Y
    clc
    adc #16
    sta.w entity_box_x2,Y
    lda.w entity_box_y1,Y
    clc
    adc #8
    sta.w entity_ysort,Y
    adc #8
    sta.w entity_box_y2,Y
    ; set some flags
    lda #ENTITY_MASK_TEAR
    sta.w entity_mask,Y
    lda #0
    sta.w entity_signal,Y
    ; inc object index
    rep #$30
    phy
    lda.w entity_variant,Y
    and #$00FF
    beq +
        .SetCurrentObjectS
        .IncrementObjectIndex
    +:
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
    pea $0405
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

entity_zombie_free:
    .ACCU 16
    .INDEX 16
    dec.w currentRoomEnemyCount
    lda #0
    sta.w entity_mask,Y
    lda.w _zombie_gfxptr.1,Y
    tax
    phy
    php
    jsl spriteman_unref
    plp
    ply
    lda.w _zombie_gfxptr.2,Y
    tax
    jsl spriteman_unref
    rts

.ENDS