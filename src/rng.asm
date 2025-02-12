.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "RNG" FREE

; macro for loop unrolling
.MACRO .UpdateRng_ABS ARGS rngaddr, N
    lda.w rngaddr
    .REPT N
        asl A
        rol.w rngaddr+2
        bcc +++++
        eor #$A3
        +++++:
    .ENDR
    sta.w rngaddr
.ENDM

; macro for loop unrolling
.MACRO .UpdateRng_DIR_INDL ARGS rngaddr_low, rngaddr_high, N
    lda [rngaddr_low]
    .REPT N
        asl A
        pha
        lda [rngaddr_high]
        rol
        sta [rngaddr_high]
        pla
        bcc +++++
        eor #$A3
        +++++:
    .ENDR
    sta [rngaddr_low]
.ENDM

; STAGE RNG
; Use stage RNG for generating the level, i.e. in mapgenerator.asm

; Use if boolean value is needed for stage
; Though you may still be able to use more of byte if bad entropy is acceptible
StageRand_Update1:
    rep #$20 ; 16 bit A
    .UpdateRng_ABS stageSeed, 1
    rtl

; Use if 4-bit value is needed for stage
; Result stored in lower byte of A
StageRand_Update4:
    rep #$20 ; 16 bit A
    .UpdateRng_ABS stageSeed, 4
    rtl

; Use if 8-bit value is needed for stage
; Result stored in lower byte of A, though higher byte may also be used if
; bad entropy is acceptible
StageRand_Update8:
    rep #$20 ; 16 bit A
    .UpdateRng_ABS stageSeed, 8
    rtl

; Use if 16-bit value is needed for stage
StageRand_Update16:
    rep #$20 ; 16 bit A
    .UpdateRng_ABS stageSeed, 16
    rtl

; Use if 32-bit value is needed for stage
; lower two bytes stored in A, higher two bytes stored in Y
StageRand_Update32:
    rep #$30 ; 16 bit AXY
    .UpdateRng_ABS stageSeed, 32
    ldy.w stageSeed+2
    rtl

_RngGeneratorInitStage:
    rep #$30 ; 16 bit AXY
    .UpdateRng_ABS gameSeed, 16
    sta.w stageSeed.low
    .UpdateRng_ABS gameSeed, 16
    sta.w stageSeed.high
    rts

; ROOM RNG
; Use Room RNG for the init functions of entities, the FIRST TIME THEY LOAD,
; and for room rewards

; Use if 8-bit value is needed for stage
; Result stored in lower byte of A, though higher byte may also be used if
; bad entropy is acceptible
RoomRand_Update8:
    rep #$20 ; 16 bit A
    .UpdateRng_DIR_INDL currentRoomRngAddress_Low, currentRoomRngAddress_High, 8
    rtl

; Use if 16-bit value is needed for stage
RoomRand_Update16:
    rep #$20 ; 16 bit A
    .UpdateRng_DIR_INDL currentRoomRngAddress_Low, currentRoomRngAddress_High, 16
    rtl

RngGameInitialize:
    ; TODO: use better method
    rep #$20 ; 16 bit A
    lda #$0001
    sta.w gameSeed.low
    sta.w gameSeed.high
    sta.w gameSeedStored.low
    sta.w gameSeedStored.high
    jsr _RngGeneratorInitStage
    rtl

.ENDS