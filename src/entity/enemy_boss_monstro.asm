.include "base.inc"

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Boss Monstro" FREE

.DEFINE MONSTRO_WIDTH 64
.DEFINE MONSTRO_HEIGHT 24
.DEFINE MONSTRO_TILE_X_OFFS 0
.DEFINE MONSTRO_TILE_Y_OFFS -24

entity_boss_monstro_init:
    .ACCU 16
    .INDEX 16
    inc.w currentRoomEnemyCount
    ; default info
    lda #100
    sta.w entity_health,Y
    sep #$20
    lda #0
    sta.w entity_signal,Y
    sta.w entity_mask,Y
    lda #10
    sta.w entity_timer,Y
    phy
    .REPT 3 INDEX iy
        .REPT 4 INDEX ix
            ; get slot
            jsl spriteman_get_raw_slot
            txa
            sta.w entity_char_custom.{iy * 4 + ix + 1},Y
            ; write to slot
            pea bankbyte(sprites@boss_monstro) * $0101 ; >2
            pea loword(sprites@boss_monstro) + (64 * ix + 128 * 4 * iy) ; >2
            pea loword(sprites@boss_monstro) + (64 * ix + 128 * 4 * iy + 64 * 4) ; >2
            jsl spriteman_write_sprite_to_raw_slot
            rep #$30
            pla ; <2
            pla ; <2
            pla ; <2
            lda $01,S
            tay
        .ENDR
    .ENDR
    ply
    rts

entity_boss_monstro_tick:
    .ACCU 16
    .INDEX 16
    sty.b $08
; Remove col
    sep #$30 ; 8B AXY
    .EntityRemoveHitbox (MONSTRO_WIDTH+15)/16,(MONSTRO_HEIGHT+15)/16
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
; load & set gfx
    sep #$20
    rep #$10
    ldx.w objectIndex
    ; X pos
    lda.w entity_posx + 1,Y
    clc
    adc #MONSTRO_TILE_X_OFFS
    clc
    .REPT 4 INDEX ix
        .IF ix > 0
            adc #16
        .ENDIF
        .REPT 3 INDEX iy
            sta.w objectData.{iy * 4 + ix + 1}.pos_x,X
        .ENDR
    .ENDR
    ; Y pos
    lda.w entity_posy + 1,Y
    clc
    adc #MONSTRO_TILE_Y_OFFS
    clc
    .REPT 3 INDEX iy
        .IF iy > 0
            adc #16
        .ENDIF
        .REPT 4 INDEX ix
            sta.w objectData.{iy * 4 + ix + 1}.pos_y,X
        .ENDR
    .ENDR
    ; Flags
    lda #%00101001
    .REPT 3 INDEX iy
        .REPT 4 INDEX ix
            sta.w objectData.{iy * 4 + ix + 1}.flags,X
        .ENDR
    .ENDR
    ; Tile
    stx.b $02
    lda #0
    xba
    .REPT 3 INDEX iy
        .REPT 4 INDEX ix
            ldx.w entity_char_custom.{iy * 4 + ix + 1},Y
            lda.l SpriteSlotIndexTable,X
            ldx.b $02
            sta.w objectData.{iy * 4 + ix + 1}.tileid,X
        .ENDR
    .ENDR
    ; inc object index
    ; (there's probably a more efficient way to do this but idc)
    .REPT 12 INDEX i
        .SetCurrentObjectS
        inc.w objectIndex
        inc.w objectIndex
        inc.w objectIndex
        inc.w objectIndex
    .ENDR
    ldy $08
; add to partition
    sep #$30
    .EntityAddHitbox (MONSTRO_WIDTH+15)/16,(MONSTRO_HEIGHT+15)/16
    lda.w entity_box_x1,Y
    clc
    adc #MONSTRO_WIDTH
    sta.w entity_box_x2,Y
    lda.w entity_box_y1,Y
    clc
    adc #MONSTRO_HEIGHT
    sta.w entity_box_y2,Y
; set some flags
    sep #$20
    lda #ENTITY_MASK_TEAR
    sta.w entity_mask,Y
    lda #0
    sta.w entity_signal,Y
; fire projectiles
    rts
    lda.w entity_timer,Y
    dec A
    sta.w entity_timer,Y
    bne @no_projectile
        rep #$30 ; 16 bit AXY
        jsl projectile_slot_get
    ; set base projectile info
        ; life
        lda #120
        sta.w projectile_lifetime,X
        ; size
        stz.w projectile_flags,X
        sep #$20
        stz.w projectile_size,X
        ; type
        lda #PROJECTILE_TYPE_ENEMY_BASIC
        sta.w projectile_type,X
        rep #$20
        ; position
        ldy $08
        lda.w entity_posx,Y
        sta.w projectile_posx,X
        lda.w entity_posy,Y
        clc
        adc #16 * 256
        sta.w projectile_posy,X
        lda #$100
        sta.w projectile_velocx,X
        lda #0
        sta.w projectile_velocy,X
        ; dmg
        lda #100
        sta.w projectile_damage,X
    ; set timer
        lda #10
        sta.w entity_timer,Y
@no_projectile:
    rts

entity_boss_monstro_free:
    .ACCU 16
    .INDEX 16
    dec.w currentRoomEnemyCount
    ; free mem
    .REPT 12 INDEX i
        phy
        php
        ldx.w entity_char_custom.{i+1},Y
        jsl spriteman_free_raw_slot
        plp
        ply
    .ENDR
    rts

.ENDS