.include "base.inc"

.BANK $00 SLOT "ROM"
.SECTION "PaletteHandling"

; Initialize all palette data to default
Palette.init_data:
    rep #$30
    lda #$FFFF
    .REPT 16 INDEX i
        .IF (i <= 8)
            sta.w paletteUsageData + (i*2)
        .ELSE
            stz.w paletteUsageData + (i*2)
        .ENDIF
    .ENDR
    rtl

; Return first free palette for opaque sprites
Palette.find_available_opaque:
    sep #$10
    rep #$20
    ldx #9
    ; check second sprite palette, and return if empty
    lda.w paletteUsageData,X
    beq @end
    inx
    ; check third sprite palette, and return if empty
    lda.w paletteUsageData,X
    beq @end
    inx
    ; just return the fourth sprite palette regardless
    ; lda.w paletteUsageData,X
    ; beq @end
    ; inx
@end:
    ; claim palette
    lda #$FFFF
    sta.w paletteUsageData,X
    rtl

Palette.free_palette:
    rep #$20
    stz.w paletteUsageData,X
    rtl

; Queue for palette at [X] to be uploaded into slot [A]
Palette.queue_upload:
    ; .INDEX 16
    ; sep #$20
    ; pha
    ; rep #$30
    ; ; get vqueue index
    ; lda.l vqueueNumOps
    ; asl
    ; asl
    ; asl
    ; clc
    ; adc.l vqueueNumOps
    ; tay
    ; ; inc vqueue index
    ; lda.l vqueueNumOps
    ; inc A
    ; sta.l vqueueNumOps
    ; ; param = CPU->PPU,auto-inc,1B
    ; ; reg = $22
    ; lda #(%00000000 + ($0100 * $22))
    ; sta.w loword(vqueueOps.1.param),Y
    rtl

.ENDS