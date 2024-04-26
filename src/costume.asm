.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "Player Costume" FREE

; .STRUCT customedef_t

; .ENDSTRUCT

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
        .ChangeDataBank bankbyte(spritedata.costume_polyphemus)
        ldy #loword(spritedata.costume_polyphemus)
        ldx #loword(playerSpriteBuffer)
        lda #8 * 4
        jsl Costume.copy_over
        sep #$20
    +:
    lda.l playerData.playerItemStackNumber + ITEMID_WIRE_COAT_HANGER
    beq +
        .ChangeDataBank bankbyte(spritedata.costume_wire_coat_hanger)
        ldy #loword(spritedata.costume_wire_coat_hanger)
        ldx #loword(playerSpriteBuffer)
        lda #4 * 4
        jsl Costume.copy_over
        sep #$20
        ldy #loword(spritedata.costume_wire_coat_hanger)
        lda #4 * 4
        jsl Costume.copy_over
        sep #$20
        ldy #loword(spritedata.costume_wire_coat_hanger)
        lda #4 * 4
        jsl Costume.copy_over
        sep #$20
        ldy #loword(spritedata.costume_wire_coat_hanger)
        lda #4 * 4
        jsl Costume.copy_over
        sep #$20
    +:
    ; end
    plb
    rtl

; Copy spritedata from DB,Y into $7E0000,X
; Copy A tiles
; Assumes 16b XY
Costume.copy_over:
    .INDEX 16
    sta.b $00
@loop:
    ; note: we have 4bpp, with four bitplanes
    ; 0,Y: abcdefgh 1,Y: abcdefgh ... 16,Y: abcdefgh, 17,Y: abcdefgh
    ; for each incoming pixel aaaa,bbbb:
    ; write out bbbb if bbbb != 0, aaaa otherwise

    rep #$20
    .REPT 8
        ; DETERMINE MASK bits in $04,$05,$06,$07 (maps to 0,1,16,17)
        ; set up four pixels at a time
        ; a-c-e-g- a-c-e-g-
        ; lda #$FFFF
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
    ; rep #$20
    txa
    clc
    adc #16
    tax
    tya
    clc
    adc #16
    tay
    dec.b $00
    bnel @loop
    ; end
    rtl

.ENDS
