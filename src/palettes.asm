; Palette handling
; We are only concerned with sprite palettes here.
;
; There are 8 sprite palettes, grouped into 4 opaque palettes, and 4
; translucent (affected by color math) palettes.
;
; In order to maximize the number of available palettes, each 16-color palette
; is subdivided into three 4-color subpalettes.
; We subdivide into three, not four, as the first four colors of each palette
; is dedicated to four common neutral colors: transparent, black, white, and gray.
;
; Objects which need a full 16-color (or, 12-color) may do so by allocating all
; three subpalettes for a row.
.include "base.inc"

.SECTION "PaletteHandling" BANK ROMBANK_BASE SLOT "ROM" ORGA $8000 SEMIFREE

; Initialize all palette data to default
Palette.init_data:
    rep #$30
    lda #$8080
    .REPT 8 INDEX iy
        .REPT 4 INDEX ix
            stz.w palettePtr + (iy*16 + ix*2)
            .IF ix == 0 || iy == 0 || iy == 4 || iy == 7
                sta.w paletteRefCount + (iy*8 + ix*2)
            .ELSE
                stz.w paletteRefCount + (iy*8 + ix*2)
            .ENDIF
        .ENDR
    .ENDR
    ; default palettes
    lda #palettes.palette0
    sta.w palettePtr + 2
    sta.w palettePtr + 2 + 4*8
    lda #palettes.red
    sta.w palettePtr + 2 + 7*8
    rtl

; Return first free palette for opaque sprites
; Parameters: A - palette depth
; Return: X as palette ID
Palette.alloc_opaque:
    sep #$30
    tax
    lda.l PaletteDepthRequiredSlots,X
    cmp #0
    beql @skip
    sta.b $00
    ; search for line with 'A' free slots
    .REPT 7 INDEX palindex
        ; we skip i == 0, i == 4, and i == 7
        .IF palindex != 0 && palindex != 4 && palindex != 7
            lda #0
            ldy.w paletteRefCount + (palindex*$04 + 3)*2
            bne +
                ldx #(palindex*$04 + 3)*2
                inc A
            +
            ldy.w paletteRefCount + (palindex*$04 + 2)*2
            bne +
                ldx #(palindex*$04 + 2)*2
                inc A
            +
            ldy.w paletteRefCount + (palindex*$04 + 1)*2
            bne +
                ldx #(palindex*$04 + 1)*2
                inc A
            +
            cmp.b $00
            bcs @found
        .ENDIF
    .ENDR
@skip:
    ; no palettes available, or 0 colors required: do nothing and return
    ldx #0
    rtl
@found:
    ; we found a palette with available slots, now allocate subpalettes
    ; Note: X points to the first empty subpalette
    lda #PALLETE_ALLOC_8A
    sta.b $01
    inc.w paletteRefCount,X
    dec.b $00
    beq @end
    ; maybe increment next subpalette(s)
    ldy.w paletteRefCount+2,X
    bne +
        lda #PALLETE_ALLOC_8B
        tsb.b $01
        inc.w paletteRefCount+2,X
        dec.b $00
        beq @end
    +
    ldy.w paletteRefCount+4,X
    bne +
        lda #PALLETE_ALLOC_8C
        tsb.b $01
        inc.w paletteRefCount+4,X
        dec.b $00
        beq @end
    +
@end:
    lda.b $01
    sta.w paletteAllocMode,X
    rtl

; Return first free palette for transparent sprites
Palette.alloc_transparent:
    sep #$30
    tax
    lda.l PaletteDepthRequiredSlots,X
    cmp #0
    beql @skip
    sta.b $00
    ; search for line with 'A' free slots
    .REPT 7 INDEX i
        .DEFINE palindex (7-i)
        ; we skip i == 0, i == 4, and i == 7
        .IF palindex != 0 && palindex != 4 && palindex != 7
            lda #0
            ldy.w paletteRefCount + (palindex*$04 + 3)*2
            bne +
                ldx #(palindex*$04 + 3)*2
                inc A
            +
            ldy.w paletteRefCount + (palindex*$04 + 2)*2
            bne +
                ldx #(palindex*$04 + 2)*2
                inc A
            +
            ldy.w paletteRefCount + (palindex*$04 + 1)*2
            bne +
                ldx #(palindex*$04 + 1)*2
                inc A
            +
            cmp.b $00
            bcs @found
        .ENDIF
        .UNDEFINE palindex
    .ENDR
@skip:
    ; no palettes available, or 0 colors required: do nothing and return
    ldx #0
    rtl
@found:
    ; we found a palette with available slots, now allocate subpalettes
    ; Note: X points to the first empty subpalette
    lda #PALLETE_ALLOC_8A
    sta.b $01
    inc.w paletteRefCount,X
    dec.b $00
    beq @end
    ; maybe increment next subpalette(s)
    ldy.w paletteRefCount+2,X
    bne +
        lda #PALLETE_ALLOC_8B
        tsb.b $01
        inc.w paletteRefCount+2,X
        dec.b $00
        beq @end
    +
    ldy.w paletteRefCount+4,X
    bne +
        lda #PALLETE_ALLOC_8C
        tsb.b $01
        inc.w paletteRefCount+4,X
        dec.b $00
        beq @end
    +
@end:
    lda.b $01
    sta.w paletteAllocMode,X
    rtl

; Increment refcount for palette in X
Palette.incref:
    inc.w paletteRefCount,X
    ; we don't care about incrementing ref counts for subpalettes
    rtl

; Free palette in X
Palette.free:
    rep #$20
    dec.w paletteRefCount,X
    bne +
        ; de-allocate subpalettes
        lda.w paletteAllocMode,X
        bit #PALLETE_ALLOC_8B
        beq ++
            stz.w palettePtr+2,X
            stz.w paletteRefCount+2,X
            stz.w paletteAllocMode+2,X
        ++:
        bit #PALLETE_ALLOC_8C
        beq ++
            stz.w palettePtr+4,X
            stz.w paletteRefCount+4,X
            stz.w paletteAllocMode+4,X
        ++:
        stz.w palettePtr,X
        stz.w paletteAllocMode,X
    +:
    rtl

; Queue for palette at [Y] to be uploaded into slot [X]
Palette.queue_upload:
    rep #$30
    ; set palette pointer
    tya
    sta.w palettePtr,X
    ; Upload to vqueue
    ; Up to three operations, depending on allocation mode
    stx.b $00
    .REPT 3 INDEX i
        ; check alloc bit (we assume that subpalette [X] is always uploaded)
        ldx.b $00
        .IF i > 0
            lda.w paletteAllocMode,X
            bit #(1 << i)
            beq @skip_{i}
        .ENDIF
        ; get and increment vqueue
        lda.l vqueueNumOps
        inc A
        sta.l vqueueNumOps
        dec A
        .MultiplyStatic 8
        tax
        ; CGRAM mode
        sep #$20
        lda #VQUEUE_MODE_CGRAM
        sta.l vqueueOps.1.mode,X
        lda #bankbyte(palettes.default)
        sta.l vqueueOps.1.aAddr+2,X
        ; VRAM addr
        lda.b $00
        asl
        clc
        adc #$80 + i*4
        sta.l vqueueOps.1.vramAddr,X
        ; num bytes
        rep #$20
        lda #8
        sta.l vqueueOps.1.numBytes,X
        ; addr
        tya
        clc
        adc #8
        tay
        sta.l vqueueOps.1.aAddr,X
    @skip_{i}:
    .ENDR
    rtl

; Search for a palette that has [Y] uploaded.
; if no such palette exists, allocates an opaque palette.
; Returns palette in [X]
; Parameters:
;    A - palette depth
;    Y - palette data pointer
; Returns:
;    X - palette ID
Palette.find_or_upload_opaque:
    rep #$30
    .REPT 32 INDEX i
        ; skip standard color subpalettes
        .IF (i # 4 != 0)
            cpy.w palettePtr + i*2
            bne +
                ldx #i*2
                inc.w paletteRefCount + i*2
                rtl
            +:
        .ENDIF
    .ENDR
    ; none found, allocate new
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
; if no such palette exists, allocates a transparent palette.
; Returns palette in [X]
; Parameters:
;    A - palette depth
;    Y - palette data pointer
; Returns:
;    X - palette ID
Palette.find_or_upload_transparent:
    rep #$30
    .REPT 32 INDEX i
        ; skip standard color subpalettes
        .IF (i # 4 != 0)
            cpy.w palettePtr + i*2
            bne +
                ldx #i*2
                inc.w paletteRefCount + i*2
                rtl
            +:
        .ENDIF
    .ENDR
    ; none found, allocate new
    phy
    jsl Palette.alloc_transparent
    rep #$30
    ply
    phx
    jsl Palette.queue_upload
    rep #$30
    plx
    rtl

.ENDS