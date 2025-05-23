.include "base.inc"

.DEFINE BOSS_WIDTH 32
.DEFINE BOSS_HEIGHT 36
.DEFINE BOSS_CENTER_Y 20
.DEFINE BOSS_TILE_X_OFFS -8
.DEFINE BOSS_TILE_Y_OFFS -16

.DEFINE duke_target_velocx loword(entity_char_custom.10)
.DEFINE duke_target_velocy loword(entity_char_custom.11)

.DEFINE TARGET_VELOC $060
.DEFINE ACCEL_VELOC $0002

; state when boss is idle
.DEFINE STATE_IDLE 0
.DEFINE STATE_SPAWNFLY 2
.DEFINE STATE_RELEASEFLIES 4
.DEFINE STATE_DEATH 6

.DEFINE BASE_HP 180
.DEFINE MAX_FLY_COUNT 8

.DEFINE _tmp_entityid $10

.BANK $02 SLOT "ROM"
.SECTION "Entity Boss Duke of Flies Extra" SUPERFREE

_duke_state_funcs:
    .dw _duke_idle
    .dw _duke_spawn_fly
    .dw _duke_releaseflies
    .dw _duke_death

_duke_idle:
    sep #$20
    ; decrement timer
    lda.w entity_timer,Y
    beq @maybe_spawn
    dec A
    sta.w entity_timer,Y
    jmp @no_spawn
    ; if zero, then maybe spawn fly
    @maybe_spawn:
        lda.w currentRoomEnemyCount
        cmp #MAX_FLY_COUNT
        bcs @no_spawn
        lda #STATE_SPAWNFLY
        sta.w entity_state,Y
        lda #0
        sta.w entity_timer,Y
    @no_spawn:
    jmp _duke_endtick

_duke_spawn_fly:
    sep #$20
    lda.w entity_timer,Y
    inc A
    sta.w entity_timer,Y
    cmp #30
    beq @do_spawn
    cmp #60
    bcs @end_spawn
    jmp @continue
    @do_spawn:
        rep #$30
        phy
        php
        lda #ENTITY_TYPE_ENEMY_ATTACK_FLY
        jsl entity_create_and_init
        tyx
        plp
        ply
        sep #$20
        lda.w entity_posx+1,Y
        clc
        adc #16
        sta.w entity_posx+1,X
        lda.w entity_posy+1,Y
        clc
        adc #36
        sta.w entity_posy+1,X
        jmp @continue
    @end_spawn:
        sep #$20
        lda #60
        sta.w entity_timer,Y
        lda #STATE_IDLE
        sta.w entity_state,Y
    @continue:
    jmp _duke_endtick

_duke_releaseflies:
    jmp _duke_endtick

_duke_death:
    rep #$30
    phy
    jsl entity_free
    rep #$30
    ply
    rts

_duke_endtick:
; check signal
    sep #$30
    lda #ENTITY_SIGNAL_KILL
    and.w entity_signal,Y
    beq @not_kill
        lda #0
        sta.w entity_timer,Y
        lda #STATE_DEATH
        sta.w entity_state,Y
        rts
    @not_kill:
    lda #ENTITY_SIGNAL_DAMAGE
    and.w entity_signal,Y
    beq @not_damage
        jsl BossBar.ReRender
    @not_damage:
; X VELOC
    rep #$30
    lda.w entity_posx,Y
    cmp #$100 * ROOM_LEFT
    bcs +
    @velocx_pos:
        lda.w entity_velocx,Y
        clc
        adc #ACCEL_VELOC
        .AMIN P_IMM, TARGET_VELOC
        sta.w entity_velocx,Y
        jmp @velocx_end
    +:
    lda.w entity_posx,Y
    cmp #$100 * (ROOM_RIGHT - BOSS_WIDTH)
    bcc +
    @velocx_neg:
        lda.w entity_velocx,Y
        sec
        sbc #ACCEL_VELOC
        .AMAX P_IMM, -TARGET_VELOC
        sta.w entity_velocx,Y
        jmp @velocx_end
    +:
    lda.w entity_velocx,Y
    bmi @velocx_neg
    jmp @velocx_pos
    @velocx_end:
; Y VELOC
    lda.w entity_posy,Y
    cmp #$100 * ROOM_TOP
    bcs +
    @velocy_pos:
        lda.w entity_velocy,Y
        clc
        adc #ACCEL_VELOC
        .AMIN P_IMM, TARGET_VELOC
        sta.w entity_velocy,Y
        jmp @velocy_end
    +:
    lda.w entity_posy,Y
    cmp #$100 * (ROOM_BOTTOM - BOSS_HEIGHT)
    bcc +
    @velocy_neg:
        lda.w entity_velocy,Y
        sec
        sbc #ACCEL_VELOC
        .AMAX P_IMM, -TARGET_VELOC
        sta.w entity_velocy,Y
        jmp @velocy_end
    +:
    lda.w entity_velocy,Y
    bmi @velocy_neg
    jmp @velocy_pos
    @velocy_end:
; finalize movement
    rep #$30
    lda.w entity_velocx,Y
    clc
    adc.w entity_posx,Y
    sta.w entity_posx,Y
    lda.w entity_velocy,Y
    clc
    adc.w entity_posy,Y
    sta.w entity_posy,Y
    lda BOSS_WIDTH + BOSS_HEIGHT * $0100
    sta.b $00
    jsl Entity.KeepInOuterBounds
; load & set gfx
    sep #$20
    rep #$10
    ldx.w objectIndex
    ; X pos
    lda.w entity_posx + 1,Y
    clc
    adc #BOSS_TILE_X_OFFS
    clc
    .REPT 3 INDEX ix
        .IF ix > 0
            adc #16
        .ENDIF
        .REPT 3 INDEX iy
            sta.w objectData.{iy * 3 + ix + 1}.pos_x,X
        .ENDR
    .ENDR
    ; Y pos
    lda.w entity_posy + 1,Y
    clc
    adc #BOSS_TILE_Y_OFFS
    clc
    .REPT 3 INDEX iy
        .IF iy > 0
            adc #16
        .ENDIF
        .REPT 3 INDEX ix
            sta.w objectData.{iy * 3 + ix + 1}.pos_y,X
        .ENDR
    .ENDR
    ; Flags
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
    .REPT 3 INDEX iy
        .REPT 3 INDEX ix
            sta.w objectData.{iy * 3 + ix + 1}.flags,X
        .ENDR
    .ENDR
    ; Tile
    stx.b $02
    lda #0
    xba
    .REPT 3 INDEX iy
        .REPT 3 INDEX ix
            ldx.w loword(entity_char_custom.{iy * 3 + ix + 1}),Y
            lda.l SpriteSlotIndexTable,X
            ldx.b $02
            sta.w objectData.{iy * 3 + ix + 1}.tileid,X
        .ENDR
    .ENDR
    ; inc object index
    ; (there's probably a more efficient way to do this but idc)
    rep #$30
    .REPT 9 INDEX i
        .SetCurrentObjectS_Inc
    .ENDR
    ldy _tmp_entityid
    pea (BOSS_HEIGHT - 8) + ($100*0)
    jsl EntityPutMediumShadow
    plx
; set some flags
    sep #$20
    lda #ENTITY_MASKSET_ENEMY
    sta.w entity_mask,Y
    lda #0
    sta.w entity_signal,Y
    rts

entity_duke_of_flies_main_tick:
    sep #$20
    lda.w entity_state,Y
    and #$00FF
    tax
    jsr (_duke_state_funcs,X)
    rtl

.ENDS

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Boss Duke of Flies Hooks" FREE

entity_boss_duke_of_flies_init:
    .ACCU 16
    .INDEX 16
    inc.w currentRoomEnemyCount
    ; default info
    lda #BASE_HP
    sta.w entity_health,Y
    sta.w loword(entity_char_max_health),Y
    lda #10
    sta.w entity_timer,Y
    sep #$20
    lda #0
    sta.w entity_signal,Y
    sta.w entity_mask,Y
    lda #STATE_IDLE
    sta.w entity_state,Y
    lda #60
    sta.w entity_timer,Y
    sty.b _tmp_entityid
    .REPT 3 INDEX iy
        .REPT 3 INDEX ix
            ; get slot
            sep #$30
            jsl Spriteman.GetRawSlot
            rep #$30
            txa
            ldy.b _tmp_entityid
            sta.w loword(entity_char_custom.{iy * 3 + ix + 1}),Y
            ; write to slot
            pea bankbyte(spritedata.boss_duke_of_flies) * $0101 ; >2
            pea loword(spritedata.boss_duke_of_flies) + (64 * ix + 128 * 3 * iy) ; >2
            pea loword(spritedata.boss_duke_of_flies) + (64 * ix + 128 * 3 * iy + 64 * 3) ; >2
            jsl Spriteman.WriteSpriteToRawSlot
            rep #$30
            pla ; <2
            pla ; <2
            pla ; <2
        .ENDR
    .ENDR
    ldy.b _tmp_entityid
    rep #$30
    lda #TARGET_VELOC
    sta.w duke_target_velocx,Y
    sta.w duke_target_velocy,Y
    ; add to bossbar
    lda.b _tmp_entityid
    jsl BossBar.Add
    rts

entity_boss_duke_of_flies_tick:
    .ACCU 16
    .INDEX 16
    sty.b _tmp_entityid
    sep #$30 ; 8B AXY
    ; main tick
    jsl entity_duke_of_flies_main_tick
    ; add to partition
    sep #$30
    lda.w entity_box_x1,Y
    clc
    adc #BOSS_WIDTH
    sta.w entity_box_x2,Y
    lda.w entity_box_y1,Y
    clc
    adc #BOSS_CENTER_Y
    sta.w loword(entity_ysort),Y
    adc #BOSS_HEIGHT - BOSS_CENTER_Y
    sta.w entity_box_y2,Y
    rts

entity_boss_duke_of_flies_free:
    .ACCU 16
    .INDEX 16
    dec.w currentRoomEnemyCount
    ; free mem
    .REPT 9 INDEX i
        phy
        php
        ldx.w loword(entity_char_custom.{i+1}),Y
        jsl Spriteman.FreeRawSlot
        plp
        ply
    .ENDR
    ; remove from bossbar
    lda.b _tmp_entityid
    jsl BossBar.Remove
    rts

.ENDS