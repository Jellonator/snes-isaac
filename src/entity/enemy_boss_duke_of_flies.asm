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

.DEFINE BASE_HP 220
.DEFINE MAX_FLY_COUNT 8

.DEFINE _tmp_entityid $10

.SoftSetAX 8, 8
.SoftSetBank $7E
.SoftSetDirect $0000
.procinterfaces "IDukeState"
    .InvalidateAX
.endproc

.BANK $02 SLOT "ROM"
.SECTION "Entity Boss Duke of Flies Extra" SUPERFREE

_duke_state_funcs:
    .dw _duke_idle
    .dw _duke_spawn_fly
    .dw _duke_releaseflies
    .dw _duke_death

.SoftSetAX 8, 8
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_duke_endtick"
; check signal
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
    .ForceSetAX 16, 16
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
    .ForceSetAX 16, 16
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
    .ForceSetAX 8, 8
    jsl Entity.KeepInOuterBounds
; load & set gfx
    .ForceSetA 8
    .ForceSetX 16
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
    .ForceSetAX 16, 16
    .REPT 9 INDEX i
        .SetCurrentObjectS_Inc
    .ENDR
    ldy.b _tmp_entityid
    pea (BOSS_HEIGHT - 8) + ($100*0)
    .call "Entity.Shadow.PutMedium"
    plx
; set some flags
    .ForceSetA 8
    lda #ENTITY_MASKSET_ENEMY
    sta.w entity_mask,Y
    lda #0
    sta.w entity_signal,Y
    rts
.endproc

.SoftSetAX 8, 8
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_duke_idle", "IDukeState"
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
    .SetAX 8, 8
    .tailcall "_duke_endtick"
.endproc

.SoftSetAX 8, 8
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_duke_spawn_fly", "IDukeState"
    lda.w entity_timer,Y
    inc A
    sta.w entity_timer,Y
    cmp #30
    beq @do_spawn
    cmp #60
    bcs @end_spawn
    jmp @continue
    @do_spawn:
        .ForceSetAX 16, 16
        phy
        php
        lda #ENTITY_TYPE_ENEMY_ATTACK_FLY
        .call "Entity.CreateAndInit"
        tyx
        plp
        ply
        .ForceSetA 8
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
        .ForceSetA 8
        lda #60
        sta.w entity_timer,Y
        lda #STATE_IDLE
        sta.w entity_state,Y
    @continue:
    .SetAX 8, 8
    .tailcall "_duke_endtick"
.endproc

.SoftSetAX 8, 8
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_duke_releaseflies", "IDukeState"
    .SetAX 8, 8
    .tailcall "_duke_endtick"
.endproc

.SoftSetAX 8, 8
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_duke_death", "IDukeState"
    .ForceSetAX 16, 16
    phy
    .call "Entity.Free"
    .SetAX 16, 16
    ply
    rts
.endproc

.SoftSetAX 8, 8
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefinel "entity_duke_of_flies_main_tick"
    ldx.w entity_state,Y
    .setupcall_in "IDukeState"
    jsr (_duke_state_funcs,X)
    .setupcall_out "IDukeState"
    rtl
.endproc

.ENDS

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Boss Duke of Flies Hooks" FREE

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "entity_boss_duke_of_flies_init", "IEntityInit"
    inc.w currentRoomEnemyCount
    ; default info
    lda #BASE_HP
    sta.w entity_health,Y
    sta.w loword(entity_char_max_health),Y
    lda #ENTITY_FLAGS_NEAREST_ENEMY_TARGET
    sta.w loword(entity_flags),Y
    .ForceSetA 8
    lda #10
    sta.w entity_timer,Y
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
            .ForceSetAX 8, 8
            jsl Spriteman.GetRawSlot
            .ForceSetAX 16, 16
            txa
            ldy.b _tmp_entityid
            sta.w loword(entity_char_custom.{iy * 3 + ix + 1}),Y
            ; write to slot
            pea bankbyte(spritedata.boss_duke_of_flies) * $0101 ; >2
            pea loword(spritedata.boss_duke_of_flies) + (64 * ix + 128 * 3 * iy) ; >2
            pea loword(spritedata.boss_duke_of_flies) + (64 * ix + 128 * 3 * iy + 64 * 3) ; >2
            jsl Spriteman.WriteSpriteToRawSlot
            .ForceSetAX 16, 16
            pla ; <2
            pla ; <2
            pla ; <2
        .ENDR
    .ENDR
    ldy.b _tmp_entityid
    .ForceSetAX 16, 16
    lda #TARGET_VELOC
    sta.w duke_target_velocx,Y
    sta.w duke_target_velocy,Y
    ; add to bossbar
    lda.b _tmp_entityid
    jsl BossBar.Add
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "entity_boss_duke_of_flies_tick", "IEntityTick"
    sty.b _tmp_entityid
    .ForceSetAX 8, 8
    ; main tick
    .call "entity_duke_of_flies_main_tick"
    ; add to partition
    .ForceSetAX 8, 8
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
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "entity_boss_duke_of_flies_free", "IEntityFree"
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
.endproc

.ENDS