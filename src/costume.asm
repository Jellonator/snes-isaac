.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "Player Costume" FREE

.MACRO .put_sprite ARGS spriteaddr, ntiles, spriteoffs, bufferoffs
    php
    phb
    .ChangeDataBank bankbyte(spriteaddr)
    ldy #loword(spriteaddr) + (spriteoffs * 48 * 4)
    ldx #loword(playerSpriteBuffer) + (bufferoffs * 32 * 4)
    lda #ntiles * 4
    jsl Costume.blit_tiles_with_interlaced_mask
    sep #$20
    plb
    plp
.ENDM

Costume.player_reset:
    ; copy data from `spritedata.isaac_head` to `playerSpriteBuffer`
    phb
    rep #$30
    lda #(32 * 4 * 32)
    ldx #loword(spritedata.isaac_head)
    ldy #loword(playerSpriteBuffer)
    mvn bankbyte(spritedata.isaac_head),bankbyte(playerSpriteBuffer)
    plb
    rtl

Costume.player_recalculate:
    jsl Costume.player_reset
    phb
    sep #$20
    rep #$10
    ; POLYPHEMUS
    lda.l playerData.playerItemStackNumber + ITEMID_POLYPHEMUS
    beq +
        .put_sprite spritedata.costume_polyphemus, 8, 0, 0
        .put_sprite spritedata.costume_polyphemus, 8, 0, 8
    +:
    ; WIRE COAT HANGER
    lda.l playerData.playerItemStackNumber + ITEMID_WIRE_COAT_HANGER
    beq +
        .put_sprite spritedata.costume_wire_coat_hanger, 4, 0, 0
        .put_sprite spritedata.costume_wire_coat_hanger, 4, 0, 4
        .put_sprite spritedata.costume_wire_coat_hanger, 4, 0, 8
        .put_sprite spritedata.costume_wire_coat_hanger, 4, 0, 12
    +:
    ; SPOON BENDER
    lda.l playerData.playerItemStackNumber + ITEMID_SPOON_BENDER
    beq +
        .put_sprite spritedata.costume_spoon_bender, 4, 0, 0
        .put_sprite spritedata.costume_spoon_bender, 4, 0, 4
        .put_sprite spritedata.costume_spoon_bender, 4, 0, 8
        .put_sprite spritedata.costume_spoon_bender, 4, 0, 12
    +:
    ; end
    plb
    rtl

; Blit A tiles from DB,Y into $7E0000,X
Costume.blit_tiles_no_mask:
    sta.b $00
    rep #$30
@loop:
    ; note: we have 4bpp, with four bitplanes
    ; 0,Y: abcdefgh 1,Y: abcdefgh ... 16,Y: abcdefgh, 17,Y: abcdefgh
    ; for each incoming pixel aaaa,bbbb:
    ; write out bbbb if bbbb != 0, aaaa otherwise
    .REPT 8
        ; DETERMINE MASK bits in $04,$05,$06,$07 (maps to 0,1,16,17)
        ; set up four pixels at a time
        ; a-c-e-g- a-c-e-g-
        stz.b $04
        lda.w $0000,Y
        and #$5555
        sta.b $02
        lda.w $0010,Y
        and #$5555
        asl
        tsb.b $02
        ; $02 now contains aacceeggaacceegg
        ; individual pixel handling
        .REPT 4 INDEX i
            lda.b $02
            and #$0303 << 2 * i ; aa------aa------
            beq +
                ; overwrite color mask
                lda #$0101 << i * 2
                tsb.b $04
            +:
        .ENDR
        ; -b-d-f-h -b-d-f-h
        lda.w $0000,Y
        and #$AAAA
        sta.b $02
        lda.w $0010,Y
        and #$AAAA
        lsr
        tsb.b $02
        .REPT 4 INDEX i
            lda.b $02
            and #$0303 << 2 * i ; bb------bb------
            beq +
                ; overwrite color mask
                lda #$0202 << i * 2
                tsb.b $04
            +:
        .ENDR
        ; WRITE COLOR
        lda.l $7F0000,X
        eor.w $0000,Y
        and.b $04
        eor.l $7F0000,X
        sta.l $7F0000,X
        lda.l $7F0010,X
        eor.w $0010,Y
        and.b $04
        eor.l $7F0010,X
        sta.l $7F0010,X
        ; inc
        inx
        inx
        iny
        iny
    .ENDR
    ; while (--count)
    txa
    clc
    adc #16
    tax
    tya
    clc
    adc #32
    tay
    dec.b $00
    bnel @loop
    ; end
    rtl

; Copy A tiles from DB,Y into $7E0000,X
; Tiles blitted using this routine must include an interlaced mask.
; The mask indicates which values in the copied are opaque.
; Character data will be stored in the following order:
;   16B: bitplanes 1 and 2
;   16B: bitplanes 3 and 4
;   16B: mask - each bit corresponds to a bit in each bitplane
Costume.blit_tiles_with_interlaced_mask:
    sta.b $00
    rep #$30
@loop:
    .REPT 8
        ; WRITE COLOR
        lda.l $7F0000,X
        eor.w $0000,Y
        and.w $0020,Y
        eor.l $7F0000,X
        sta.l $7F0000,X
        lda.l $7F0010,X
        eor.w $0010,Y
        and.w $0020,Y
        eor.l $7F0010,X
        sta.l $7F0010,X
        ; inc
        inx
        inx
        iny
        iny
    .ENDR
    ; while (--count)
    txa
    clc
    adc #16
    tax
    tya
    clc
    adc #48 - 16
    tay
    dec.b $00
    bnel @loop
    ; end
    rtl

.ENDS
