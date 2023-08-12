.include "base.inc"

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Enemy Zombie" FREE

.DEFINE _zombie_gfxptr.1 entity_char_custom.1
.DEFINE _zombie_gfxptr.2 entity_char_custom.2

entity_zombie_init:
    .ACCU 16
    .INDEX 16
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
    cmp.l _e_zombie_speedtable_X,X
    beq ++
    bpl +
        ; velocx < target
        adc #ZOMBIE_ACCEL
    bra ++
    +:
        ; velocx > target
        sbc #ZOMBIE_ACCEL
    ++:
    sta.w entity_velocx,Y
    adc.w entity_posx,Y
    sta.w entity_posx,Y
    ; Y
    lda.w entity_velocy,Y
    cmp.l _e_zombie_speedtable_Y,X
    beq ++
    bpl +
        ; velocy < target
        adc #ZOMBIE_ACCEL
    bra ++
    +:
        ; velocy > target
        sbc #ZOMBIE_ACCEL
    ++:
    sta.w entity_velocy,Y
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
        lda #%00101001
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
        lda #%00101001
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
    adc #16
    sta.w entity_box_y2,Y
    ; set some flags
    lda #ENTITY_MASK_TEAR
    sta.w entity_mask,Y
    lda #0
    sta.w entity_signal,Y
    ; inc object index
    rep #$30
    lda.w entity_variant,Y
    and #$00FF
    beq +
        .SetCurrentObjectS
        .IncrementObjectIndex
    +:
    .SetCurrentObjectS
    .IncrementObjectIndex
    ; end
    rts

entity_zombie_free:
    .ACCU 16
    .INDEX 16
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