.include "base.inc"

.DEFINE MAX_HELPER_FLY_BUFFER_COUNT 128
.DEFINE MAX_HELPER_FLY_ACTIVE_COUNT 8

.DEFINE _position_angle_index loword(entity_custom.1)
.DEFINE _target_entity_verification loword(entity_custom.2)

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Helper Fly" FREE

.DEFINE TARGET_DISTANCE 40*$0100

.DEFINE D_LENGTH 14*$100

_target_player_offset_x:
    .dw cos((0.0 / 8.0) * TAU) * D_LENGTH + 8*$100
    .dw cos((4.0 / 8.0) * TAU) * D_LENGTH + 8*$100
    .dw cos((2.0 / 8.0) * TAU) * D_LENGTH + 8*$100
    .dw cos((6.0 / 8.0) * TAU) * D_LENGTH + 8*$100
    .dw cos((1.0 / 8.0) * TAU) * D_LENGTH + 8*$100
    .dw cos((5.0 / 8.0) * TAU) * D_LENGTH + 8*$100
    .dw cos((3.0 / 8.0) * TAU) * D_LENGTH + 8*$100
    .dw cos((7.0 / 8.0) * TAU) * D_LENGTH + 8*$100

_target_player_offset_y:
    .dw sin((0.0 / 8.0) * TAU) * D_LENGTH + 8*$100
    .dw sin((4.0 / 8.0) * TAU) * D_LENGTH + 8*$100
    .dw sin((2.0 / 8.0) * TAU) * D_LENGTH + 8*$100
    .dw sin((6.0 / 8.0) * TAU) * D_LENGTH + 8*$100
    .dw sin((1.0 / 8.0) * TAU) * D_LENGTH + 8*$100
    .dw sin((5.0 / 8.0) * TAU) * D_LENGTH + 8*$100
    .dw sin((3.0 / 8.0) * TAU) * D_LENGTH + 8*$100
    .dw sin((7.0 / 8.0) * TAU) * D_LENGTH + 8*$100

entity_helper_fly_init:
    .ACCU 16
    .INDEX 16
    ; inc count
    sep #$20
    inc.w playerData.helperFlyActiveCount
    lda #0
    sta.w entity_state,Y
    ; random timer
    jsl QuickRand16
    sep #$30
    sta.w entity_timer,Y
    ; get position mask and angle
    lda.w playerData.helperFlyPositionMask
    eor #$FF
    tax
    lda.l Log2Table8,X
    sta.w _position_angle_index,Y
    tax
    lda.l ShiftLeftTable8,X
    tsb.w playerData.helperFlyPositionMask
    rts

entity_helper_fly_tick:
    .ACCU 16
    .INDEX 16
; determine target
    sep #$10
    ldx.w entity_state,Y
    beq @no_target_entity
    ; verify target
        lda.w _target_entity_verification,Y
        ldx.w entity_state,Y
        cmp.w entity_type,X
        beq +
        @stop_following_target:
            sep #$20
            lda #0
            sta.w entity_state,Y
            rep #$20
            jmp @no_target_entity
        +:
        lda.w entity_mask,X
        and #ENTITY_MASK_TEAR
        beq @stop_following_target ; no longer targettable - end
    ; move toward target
        lda.w entity_posx,X
        adc.w entity_box_x2-1,X
        ror
        sta.b tempDP+$00
        lda.w entity_posy,X
        adc.w entity_box_y2-1,X
        ror
        sta.b tempDP+$02
    ; check collision with target
        sep #$20
        lda.w entity_posx+1,Y
        cmp.w entity_box_x1,X
        bcc @end_collision_check
        cmp.w entity_box_x2,X
        bcs @end_collision_check
        lda.w entity_posy+1,Y
        cmp.w entity_box_y1,X
        bcc @end_collision_check
        cmp.w entity_box_y2,X
        bcs @end_collision_check
            rep #$20
            lda.w playerData.stat_damage
            asl
            sta.b $00
            lda.w entity_health,X
            sec
            sbc.b $00
            sta.w entity_health,X
            sep #$20
            php
            lda.w entity_signal,X
            plp
            ora #ENTITY_SIGNAL_DAMAGE
            bcs +
                ora #ENTITY_SIGNAL_KILL
            +:
            sta.w entity_signal,X
            ; alright, now we do damage and unalive self
            jsl entity_free
            rts
        @end_collision_check:
        jmp @end_targetting
    @no_target_entity:
        .ACCU 16
        .INDEX 8
        lda.w _position_angle_index,Y
        asl
        tax
        lda.w player_posx
        clc
        adc.l _target_player_offset_x,X
        sta.b tempDP+$00
        lda.w player_posy
        adc.l _target_player_offset_y,X
        sta.b tempDP+$02
    ; check for target in range
        ; get nearest enemy ID
        sep #$30
        lda.w entity_posx+1,Y
        lsr
        lsr
        lsr
        lsr
        sta.b $00
        lda.w entity_posy+1,Y
        and #$F0
        ora.b $00
        tax
        lda.w pathfind_nearest_enemy_id,X
        beq @end_targetting
        tax
        lda.w entity_type,X
        beq @end_targetting
        ; check enemy is in range
        rep #$20
        lda.w entity_posx,X
        adc.w entity_box_x2-1,X
        ror
        sbc.w entity_posx,Y
        .ABS_A16_POSTLOAD
        cmp #TARGET_DISTANCE
        bcs @end_targetting
        lda.w loword(entity_ysort)-1,X
        sbc.w entity_posy,Y
        .ABS_A16_POSTLOAD
        cmp #TARGET_DISTANCE
        bcs @end_targetting
        ; target is valid, store
        sep #$20
        txa
        sta.w entity_state,Y
        rep #$20
        lda.w entity_type,X
        sta.w _target_entity_verification,Y
    @end_targetting:
    rep #$20
; Move X position
    lda.b tempDP+$00
    sec
    sbc.w entity_posx,Y
    php
    .ABS_A16_POSTSBC
    cmp #$0100
    bcs +
        lda.b tempDP+$00
        sta.w entity_posx,Y
        plp
        jmp @end_move_x
    +:
    xba
    tax
    lda.l Log2Table8,X
    xba
    lsr
    plp
    bcs +
        .NEG_A16
    +:
    clc
    adc.w entity_posx,Y
    sta.w entity_posx,Y
@end_move_x:
; Move Y position
    lda.b tempDP+$02
    sec
    sbc.w entity_posy,Y
    php
    .ABS_A16_POSTSBC
    cmp #$0100
    bcs +
        lda.b tempDP+$02
        sta.w entity_posy,Y
        plp
        jmp @end_move_y
    +:
    xba
    tax
    lda.l Log2Table8,X
    xba
    lsr
    plp
    bcs +
        .NEG_A16
    +:
    clc
    adc.w entity_posy,Y
    sta.w entity_posy,Y
@end_move_y:
; animate
    jsl QuickRand16
    sep #$30
    and #$01
    adc.w entity_timer,Y
    inc A
    sta.w entity_timer,Y
; put sprite
    ; TILE
    lda.w entity_timer,Y
    lsr
    lsr
    lsr
    and #$01
    clc
    adc #$AE
    ldx.w objectIndex
    sta.w objectData.1.tileid,X
    ; FLAG
    lda #%00100000
    sta.w objectData.1.flags,X
    ; POSITION
    lda.w entity_posx+1,Y
    sec
    sbc #4
    sta.w objectData.1.pos_x,X
    lda.w entity_timer,Y
    lsr
    lsr
    lsr
    lsr
    lsr
    lsr
    and #$03
    cmp #3
    bne +
        lda #1
    +:
    clc
    adc.w entity_posy+1,Y
    sta.w loword(entity_ysort),Y
    sbc #12
    sta.w objectData.1.pos_y,X
    inx
    inx
    inx
    inx
    stx.w objectIndex
    rts

entity_helper_fly_free:
    .ACCU 16
    .INDEX 16
    sep #$30
    dec.w playerData.helperFlyActiveCount
    ; If freed by room transition, then increment buffer
    lda.b entityExecutionContext
    cmp #ENTITY_CONTEXT_TRANSITION
    bne +
        inc.w playerData.helperFlyBufferCount
    +:
    ; clear position mask
    ldx.w _position_angle_index,Y
    lda.l ShiftLeftTable8,X
    trb.w playerData.helperFlyPositionMask
    rts

.ENDS

.BANK $02 SLOT "ROM"
.SECTION "Entity Helper Fly Extra" SUPERFREE

; Add `A` to helper fly count
HelperFly.Add:
    sep #$20
    clc
    adc.w playerData.helperFlyBufferCount
    bcc +
        ; unsigned overflow: store max count instead
        lda #MAX_HELPER_FLY_BUFFER_COUNT
        sta.w playerData.helperFlyBufferCount
        rtl
    +:
    ; no overflow, check max
    .AMINU P_IMM, MAX_HELPER_FLY_BUFFER_COUNT
    sta.w playerData.helperFlyBufferCount
    rtl

HelperFly.Tick:
    sep #$20
    lda.w playerData.helperFlyBufferCount
    bne +
        rtl ; no flies in buffer, exit
    +:
    lda.w playerData.helperFlyActiveCount
    cmp #MAX_HELPER_FLY_ACTIVE_COUNT
    bcc +
        rtl ; active fly count is full, exit
    +:
    ; spawn a fly
    dec.w playerData.helperFlyBufferCount
    rep #$30
    lda #entityvariant(ENTITY_TYPE_HELPER_FLY, 0)
    jsl entity_create_and_init
    ; set position and velocity
    rep #$30
    lda.w player_velocx
    sta.w entity_velocx,Y
    lda.w player_velocy
    sta.w entity_velocy,Y
    lda.w player_posx
    sta.w entity_posx,Y
    lda.w player_posy
    sta.w entity_posy,Y
    rtl

.ENDS
