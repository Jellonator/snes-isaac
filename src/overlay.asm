.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "Overlay"

Overlay.init:
    rep #$30
    lda #0
    sta.l textLines
    sta.l textDisplayTimer
    rtl

Overlay.update:
    rep #$30
    lda.l textDisplayTimer
    beq @end
        dec A
        sta.l textDisplayTimer
        bne @dont_clear
            jsl Overlay.clear
    @dont_clear:
@end:
    rtl

; Get length of string in X
; Returns length as A
; Ideally, A should be in 8b mode
String.len:
    .INDEX 16
    .ACCU 8
    ldy #0
@loop:
    lda.w $0000,X
    beq @end
    inx
    iny
    jmp @loop
@end:
    rep #$20
    tya
    rtl

Overlay.clear:
    rep #$30
    ; get vqueue ptr
    lda.l vqueueNumOps
    inc A
    sta.l vqueueNumOps
    dec A
    asl
    asl
    asl
    tax
    ; put info
    rep #$30
    lda.l textLines
    cmp #8
    bcc +
        lda #8
    +:
    asl
    asl
    asl
    asl
    asl
    asl
    sta.l vqueueOps.1.numBytes,X
    lda #BG1_TILE_BASE_ADDR + 32 * 8
    sta.l vqueueOps.1.vramAddr,X
    sep #$20
    lda #VQUEUE_MODE_VRAM_CLEAR
    sta.l vqueueOps.1.mode,X
    rep #$30
    lda #0
    sta.l textLines
    rtl

; Put string of characters onto overlay
; String is in X, with appropriate data bank
Overlay.putline:
    .DEFINE PREFIX_LEN $00
    .DEFINE STRING_LEN $01
    .DEFINE SUFFIX_LEN $02
    .DEFINE STRING_PTR $03
    .DEFINE BEGIN $05
    .DEFINE END $06
    rep #$10
    sep #$20
    stx.b STRING_PTR
    jsl String.len
    .ACCU 16
    sta.b STRING_LEN
    lda #32
    sec
    sbc.b STRING_LEN
    lsr
    sta.b PREFIX_LEN
    sta.b BEGIN
    lda #32
    sec
    sbc.b STRING_LEN
    sbc.b PREFIX_LEN
    sta.b SUFFIX_LEN
    lda.b BEGIN
    clc
    adc.b STRING_LEN
    sta.b END
    ; get and increment vqueueBinOffset
    rep #$20
    lda.l vqueueBinOffset
    sec
    sbc #64
    sta.l vqueueBinOffset
    tax
    sep #$20
    ; put PREFIX
    lda #0
@loop_prefix:
    dec.b PREFIX_LEN
    bmi @end_prefix
    sta.l $7F0000,X
    inx
    sta.l $7F0000,X
    inx
    jmp @loop_prefix
@end_prefix:
    ; put STRING
    ldy.b STRING_PTR
@loop_string:
    dec.b STRING_LEN
    bmi @end_string
    lda.w $0000,Y
    sta.l $7F0000,X
    inx
    lda #%00110100
    sta.l $7F0000,X
    inx
    iny
    jmp @loop_string
@end_string:
    ; put SUFFIX
    lda #0
@loop_suffix:
    dec.b SUFFIX_LEN
    bmi @end_suffix
    sta.l $7F0000,X
    inx
    sta.l $7F0000,X
    inx
    jmp @loop_suffix
@end_suffix:
; put additional flair
    rep #$30
    lda.b BEGIN
    and #$00FF
    asl
    clc
    adc.l vqueueBinOffset
    tax
    lda #deft($BE, 4) | T_HIGHP
    sta.l $7F0000 - 4,X
    lda #deft($BF, 4) | T_HIGHP
    sta.l $7F0000 - 2,X
    lda.b END
    and #$00FF
    asl
    clc
    adc.l vqueueBinOffset
    tax
    lda #deft($BE, 4) | T_HIGHP | T_FLIPH
    sta.l $7F0000 + 2,X
    lda #deft($BF, 4) | T_HIGHP | T_FLIPH
    sta.l $7F0000,X
; write to vqueue
    ; get vqueue ptr
    rep #$30
    lda.l vqueueNumOps
    inc A
    sta.l vqueueNumOps
    dec A
    asl
    asl
    asl
    tax
    ; put info
    lda.l vqueueBinOffset
    sta.l vqueueOps.1.aAddr,X
    lda #32*2
    sta.l vqueueOps.1.numBytes,X
    lda.l textLines
    and #$07
    asl
    asl
    asl
    asl
    asl
    clc
    adc #BG1_TILE_BASE_ADDR + 32 * 8
    sta.l vqueueOps.1.vramAddr,X
    sep #$20
    lda #$7F
    sta.l vqueueOps.1.aAddr+2,X
    lda #VQUEUE_MODE_VRAM
    sta.l vqueueOps.1.mode,X
    ; increment line
    lda.l textLines
    inc A
    sta.l textLines
    ; set timer
    lda #120
    sta.l textDisplayTimer
    rtl

.ENDS