.include "base.inc"

.BANK $00 SLOT "ROM"
.SECTION "PaletteHandling"

; Initialize all palette data to default
Palette.init_data:
    sep #$30
    lda #$FF
    .REPT 16 INDEX i
        .IF (i <= 8)
            sta.w paletteUsageData + (i)
        .ELSE
            stz.w paletteUsageData + (i)
        .ENDIF
    .ENDR
    rtl

; Return first free palette for opaque sprites
Palette.find_available_opaque:
    sep #$30
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
    lda #$FF
    sta.w paletteUsageData,X
    rtl

Palette.free_palette:
    sep #$20
    stz.w paletteUsageData,X
    rtl

; Queue for palette at [Y] to be uploaded into slot [A]
Palette.queue_upload:
    .INDEX 16
    sep #$20
    pha
    rep #$30
    ; get and inc vqueue index
    lda.l vqueueNumOps
    inc A
    sta.l vqueueNumOps
    dec A
    asl
    asl
    asl
    tax
    ; CGRAM mode
    sep #$20
    lda #VQUEUE_MODE_CGRAM
    sta.l vqueueOps.1.mode,X
    lda #bankbyte(palettes.palette0)
    sta.l vqueueOps.1.aAddr+2,X
    pla
    asl
    asl
    asl
    asl
    sta.l vqueueOps.1.vramAddr,X
    rep #$20
    lda #32
    sta.l vqueueOps.1.numBytes,X
    tya
    sta.l vqueueOps.1.aAddr,X
    rtl

.ENDS