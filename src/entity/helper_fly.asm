.include "base.inc"

.DEFINE MAX_HELPER_FLY_BUFFER_COUNT 128
.DEFINE MAX_HELPER_FLY_ACTIVE_COUNT 8

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Helper Fly" FREE

entity_helper_fly_init:
    .ACCU 16
    .INDEX 16
    sep #$20
    inc.w playerData.helperFlyActiveCount
    jsl QuickRand16
    sep #$20
    sta.w entity_timer,Y
    rts

entity_helper_fly_tick:
    .ACCU 16
    .INDEX 16
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
    lda.w entity_posy+1,Y
    sbc #4
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
    sep #$20
    dec.w playerData.helperFlyActiveCount
    ; If freed by room transition, then increment buffer
    lda.b entityExecutionContext
    cmp #ENTITY_CONTEXT_TRANSITION
    bne +
        inc.w playerData.helperFlyBufferCount
    +:
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
