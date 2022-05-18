.BANK 0 SLOT "ROM"
.SECTION "RNG" FREE

; macro for loop unrolling
.MACRO .UpdateRng ARGS rngaddr, N
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

; Use if boolean value is needed for stage
; Though you may still be able to use more of byte if bad entropy is acceptible
RngGeneratorUpdate1:
    rep #$20 ; 16 bit A
    .UpdateRng stageSeed, 1
    rtl

; Use if 4-bit value is needed for stage
; Result stored in lower byte of A
RngGeneratorUpdate4:
    rep #$20 ; 16 bit A
    .UpdateRng stageSeed, 4
    rtl

; Use if 8-bit value is needed for stage
; Result stored in lower byte of A, though higher byte may also be used if
; bad entropy is acceptible
RngGeneratorUpdate8:
    rep #$20 ; 16 bit A
    .UpdateRng stageSeed, 8
    rtl

; Use if 16-bit value is needed for stage
RngGeneratorUpdate16:
    rep #$20 ; 16 bit A
    .UpdateRng stageSeed, 16
    rtl

; Use if 32-bit value is needed for stage
; lower two bytes stored in A, higher two bytes stored in Y
RngGeneratorUpdate32:
    rep #$30 ; 16 bit AXY
    .UpdateRng stageSeed, 32
    ldy.w stageSeed+2
    rtl

_RngGeneratorInitStage:
    rep #$30 ; 16 bit AXY
    .UpdateRng gameSeed, 16
    sta.w stageSeed.low
    .UpdateRng gameSeed, 16
    sta.w stageSeed.high
    rts

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