; Palette handling
; Palettes are allocated as such:
;   tile palettes:
;     0       - ground
;     1,3     - tiles
;     5,6,7   - UI
;     2,4     - unused
;   sprite palettes:
;     8       - player (opaque)
;     9,10,11 - dynamic (opaque)
;     12      - shadows (transparent)
;     13,14   - dynamic (transparent)
;     15      - damage flash (transparent)
; so, we realistically only have 5 dynamically loaded palettes for all objects in a room.
.include "base.inc"

.SECTION "PaletteHandling" BANK ROMBANK_BASE SLOT "ROM" ORGA $8000 SEMIFREE

; Initialize all palette data to default
Palette.init_data:
    rep #$30
    lda #$8000
    .REPT 16 INDEX i
        .IF (i <= 8)
            sta.w palettePtr + (i*2)
            sta.w paletteRefCount + (i*2)
        .ELSE
            stz.w palettePtr + (i*2)
            stz.w paletteRefCount + (i*2)
        .ENDIF
    .ENDR
    rtl

; Return first free palette for opaque sprites
Palette.alloc_opaque:
    sep #$30
    ldx #9*2
    ; check second sprite palette, and return if empty
    lda.w paletteRefCount,X
    beq @end
    inx
    inx
    ; check third sprite palette, and return if empty
    lda.w paletteRefCount,X
    beq @end
    inx
    inx
    ; just return the fourth sprite palette regardless
    ; lda.w paletteUsageData,X
    ; beq @end
    ; inx
@end:
    ; palette is not 'claimed' until upload
    inc.w paletteRefCount,X
    rtl

; Return first free palette for transparent sprites
Palette.alloc_transparent:
    sep #$30
    ldx #13*2
    ; check fifth sprite palette, and return if empty
    lda.w paletteRefCount,X
    beq @end
    inx
    inx
    ; just return the sixth sprite palette regardless
    ; lda.w paletteUsageData,X
    ; beq @end
    ; inx
@end:
    ; palette is not 'claimed' until upload
    inc.w paletteRefCount,X
    rtl

Palette.incref:
    inc.w paletteRefCount,X
    rtl

Palette.free:
    rep #$20
    dec.w paletteRefCount,X
    bne +
        stz.w palettePtr,X
    +:
    rtl

; Queue for palette at [Y] to be uploaded into slot [A]
Palette.queue_upload:
    .INDEX 16
    sep #$20
    pha
    rep #$30
    ; set palette pointer
    tax
    tya
    sta.w palettePtr,X
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
    ; asl
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

; Search for a palette that has [Y] uploaded.
; if no such palette exists, claims a new palette.
; Returns palette in [X]
Palette.find_or_upload_opaque:
    rep #$30
    .REPT 4 INDEX i
        cpy.w palettePtr + ((i + 8)*2)
        bne +
            ldx #(i + 8)*2
            inc.w paletteRefCount + ((i + 8)*2)
            rtl
        +:
    .ENDR
    ; none found
    phy
    jsl Palette.alloc_opaque
    rep #$30
    ply
    txa
    phx
    jsl Palette.queue_upload
    rep #$30
    plx
    rtl

; Search for a palette that has [Y] uploaded.
; if no such palette exists, claims a new palette.
; Returns palette in [X]
Palette.find_or_upload_transparent:
    rep #$30
    .REPT 4 INDEX i
        cpy.w palettePtr + ((i + 8)*2)
        bne +
            ldx #(i + 8)*2
            inc.w paletteRefCount + ((i + 8)*2)
            rtl
        +:
    .ENDR
    ; none found
    phy
    jsl Palette.alloc_transparent
    rep #$30
    ply
    txa
    phx
    jsl Palette.queue_upload
    rep #$30
    plx
    rtl

.ENDS