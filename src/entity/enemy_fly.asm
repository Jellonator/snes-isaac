.include "base.inc"

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Enemy Fly" FREE

.DEFINE _fly_fgxptr.1 entity_char_custom.1
.DEFINE _fly_fgxptr.2 entity_char_custom.2

entity_basic_fly_init:
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
    rep #$20
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
; Remove col
    sep #$30 ; 8B AXY
    .EntityRemoveHitbox 2, 2
; check signal
    lda #ENTITY_SIGNAL_KILL
    and.w entity_signal,Y
    beq +
        ; We have perished
        jsl entity_free
        rts
    +:
; move
    ; TO PLAYER
    lda.w entity_posx+1,Y
    lsr
    sta.b $02
    lda.w player_posx+1
    lsr
    sec
    sbc.b $02
    bmi +
        adc #15
    +:
    and #$F0
    sta.b $02
    lda.w entity_posy+1,Y
    lsr
    sta.b $03
    lda.w player_posy+1
    lsr
    sec
    sbc.b $03
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
    adc #15
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
    sta.w objectData.1.pos_y,X
    lda #%00101001
    sta.w objectData.1.flags,X
    ; add to partition
    .EntityAddHitbox 2, 2
    ; set some flags
    lda #ENTITY_MASK_TEAR
    sta.w entity_mask,Y
    lda #0
    sta.w entity_signal,Y
    ; inc object index
    rep #$30
    .SetCurrentObjectS
    .IncrementObjectIndex
    ; end
    rts

entity_basic_fly_free:
    .ACCU 16
    .INDEX 16
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
