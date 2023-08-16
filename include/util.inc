; test argument against A.
; if argument > A, set A to argument
; as a general rule, macro labels should begin with @@@@@
; that way, these labels don't mess with those in code

; Maximum of A register and value, signed
.MACRO .AMAX
    .IF \?1 == ARG_IMMEDIATE
        cmp #\1
    .ELSE
        cmp \1
    .ENDIF
    bpl @@@@@\.\@
    .IF \?1 == ARG_IMMEDIATE
        lda #\1
    .ELSE
        lda \1
    .ENDIF
@@@@@\.\@:
.ENDM

; Minimum of A register and value, signed
.MACRO .AMIN
    .IF \?1 == ARG_IMMEDIATE
        cmp #\1
    .ELSE
        cmp \1
    .ENDIF
    bmi @@@@@\.\@
    .IF \?1 == ARG_IMMEDIATE
        lda #\1
    .ELSE
        lda \1
    .ENDIF
@@@@@\.\@:
.ENDM

; Maximum of A register and value, unsigned
.MACRO .AMAXU
    .IF \?1 == ARG_IMMEDIATE
        cmp #\1
    .ELSE
        cmp \1
    .ENDIF
    bcs @@@@@\.\@
    .IF \?1 == ARG_IMMEDIATE
        lda #\1
    .ELSE
        lda \1
    .ENDIF
@@@@@\.\@:
.ENDM

; Minimum of A register and value, unsigned
.MACRO .AMINU
    .IF \?1 == ARG_IMMEDIATE
        cmp #\1
    .ELSE
        cmp \1
    .ENDIF
    bcc @@@@@\.\@
    .IF \?1 == ARG_IMMEDIATE
        lda #\1
    .ELSE
        lda \1
    .ENDIF
@@@@@\.\@:
.ENDM

; Calculate the absolute value of A
; ONLY use after an instruction that loads the value into A (checks N flag)
; e.g.: ADC, SBC, DEC, INC, AND, ORA, EOR, ASL, LSR, ROL, ROR, LDA, PLA, TXA, and TYA
; some other instructions also set the N flag but may either refer to a
; different register (e.g. LDX), or don't reflect the current value of A (e.g. CMP)
.MACRO ABS_A16_POSTLOAD
    bpl @@@@@\.\@
    eor #FFFF
    inc
@@@@@\.\@:
.ENDM

; Calculate the absolute value of A
; ONLY use after an instruction that loads the value into A (checks N flag)
.MACRO ABS_A8_POSTLOAD
    bpl @@@@@\.\@
    eor #FF
    inc
@@@@@\.\@:
.ENDM

.define BYTES_PER_TILE16 32

.MACRO BEGININTERRUPT
    phb
    phd
    rep #$30
    pha
    phx
    phy
.ENDM

.MACRO ENDINTERRUPT
    rep #$30
    ply
    plx
    pla
    pld
    plb
.ENDM

.MACRO .ChangeDataBank ARGS bank
    pea bank + ($0100*(bank))
    plb
    plb
.ENDM

.MACRO .CopyROMToVQueueBin ARGS ROMADDR, NBYTES
    rep #$20 ; 16 bit A
    lda #NBYTES
    sta DMA0_SIZE
    lda #loword(ROMADDR)
    sta DMA0_SRCL
    lda.w vqueueBinOffset
    sta WMADDL
    sep #$20 ; 8 bit A
    lda #bankbyte(ROMADDR)
    sta DMA0_SRCH
    lda #$7F
    sta WMADDH
    ; Absolute address, no increment, 1 byte at a time
    lda #%00000000
    sta DMA0_CTL
    ; Write to WRAM
    lda #$80
    sta DMA0_DEST
    lda #$01
    sta MDMAEN
.ENDM

.MACRO .ClearWRam ARGS ADDRL, NBYTES
    rep #$20 ; 16 bit A
    lda #NBYTES
    sta DMA0_SIZE
    lda #loword(EmptyData)
    sta DMA0_SRCL
    lda #loword(ADDRL)
    sta WMADDL
    sep #$20 ; 8 bit A
    lda #bankbyte(EmptyData)
    sta DMA0_SRCH
    lda #bankbyte(ADDRL)
    sta WMADDH
    ; Absolute address, no increment, 1 byte at a time
    lda #%00001000
    sta DMA0_CTL
    ; Write to WRAM
    lda #$80
    sta DMA0_DEST
    lda #$01
    sta MDMAEN
.ENDM

.MACRO .ClearWRam_ZP ARGS ADDRL, NBYTES
    rep #$20 ; 16 bit A
    lda #NBYTES
    sta.b <DMA0_SIZE
    lda #loword(EmptyData)
    sta.b <DMA0_SRCL
    lda #loword(ADDRL)
    sta.l WMADDL
    sep #$20 ; 8 bit A
    lda #bankbyte(EmptyData)
    sta.b <DMA0_SRCH
    lda #bankbyte(ADDRL)
    sta.l WMADDH
    ; Absolute address, no increment, 1 byte at a time
    lda #%00001000
    sta.b <DMA0_CTL
    ; Write to WRAM
    lda #$80
    sta.b <DMA0_DEST
    lda #$01
    sta.l MDMAEN
.ENDM

.MACRO .InitializeObjectIndices
    stz.w objectIndex
.ENDM

.MACRO .SetCurrentObjectS
    lda.w objectIndex
    lsr
    lsr
    tay
    and #3
    tax
    tya
    lsr
    lsr
    tay
    lda.l SpriteIndexToExtMaskS,X
    and #$FF
    ora.w objectDataExt,Y
    sta.w objectDataExt,Y
.ENDM

.MACRO .SetCurrentObjectX
    lda.w objectIndex
    lsr
    lsr
    tay
    and #3
    tax
    tya
    lsr
    lsr
    tay
    lda.l SpriteIndexToExtMaskX,X
    and #$FF
    ora.w objectDataExt,Y
    sta.w objectDataExt,Y
.ENDM

.MACRO .GetObjectPos_X
    phy
    phx
    txa
    lsr
    lsr
    lsr
    lsr
    tay ; Y is index into objectDataExt [0,31]
    lda $01,S
    and #3
    tax ; X is index into SpriteIndexToExtMaskX [0,3]
    lda.l SpriteIndexToExtMaskX,X
    and #$FF
    and.w objectDataExt,Y ; Get X mask
    beq @@@@@\.\@pos
@@@@@\.\@neg:
    plx
    lda objectData.1.pos_x,X
    and #$FF
    eor #$FFFF
    sec
    adc #1
    bra @@@@@\.\@end
@@@@@\.\@pos:
    plx
    lda objectData.1.pos_x,X
    and #$FF
@@@@@\.\@end:
    ply
.ENDM

; Put the value A into the sprite at index X
.MACRO .PutObjectPos_X
; push
    phy
    pha
    phx
; Y is index into objectDataExt [0,31]
    txa
    lsr
    lsr
    lsr
    lsr
    tay
; X is index into SpriteIndexToExtMaskX [0,3]
    lda $01,S
    and #3
    tax
; Check if A is positive or negative
    lda $03,S
    bpl @@@@@\.\@pos
@@@@@\.\@neg:
    lda.l SpriteIndexToExtMaskX,X
    and #$FF
    ora.w objectDataExt,Y
    sta.w objectDataExt,Y
    lda $03,S
    eor #$FFFF
    sec
    adc #1
    sep #$20 ; 8b A
    plx
    sta objectData.1.pos_x,X
    rep #$20 ; 16b A
    bra @@@@@\.\@end
@@@@@\.\@pos:
    lda.l SpriteIndexToExtMaskX,X
    eor #$FFFF
    ora #$FF00
    and.w objectDataExt,Y
    sta.w objectDataExt,Y
    lda $03,S
    sep #$20 ; 8b A
    plx
    sta objectData.1.pos_x,X
    rep #$20 ; 16b A
@@@@@\.\@end:
    pla
    ply
.ENDM

.MACRO .SetCurrentObjectXS
    lda.w objectIndex
    lsr
    lsr
    tay
    and #3
    tax
    tya
    lsr
    lsr
    tay
    lda.l SpriteIndexToExtMaskXS,X
    and #$FF
    ora.w objectDataExt,Y
    sta.w objectDataExt,Y
.ENDM

.MACRO .IncrementObjectIndex
    ldx.w objectIndex
    inx
    inx
    inx
    inx
    stx.w objectIndex
.ENDM

; Clobbers A
.MACRO .VQueueOpToA
    lda.w vqueueNumOps
    asl
    asl
    asl
    clc
    adc.w vqueueNumOps
.ENDM

; Clobbers A
.MACRO .VQueueOpIncX
    txa
    clc
    adc #9
    tax
.ENDM

.MACRO .VQueueBinToX
    ldx.w vqueueBinOffset
.ENDM

; Clobbers A
.MACRO .VQueuePushBinA ARGS amount
    lda.w vqueueBinOffset
    adc amount
    sta.w vqueueBinOffset
.ENDM

; Clobbers A
.MACRO .VQueuePushBinI ARGS amount
    lda.w vqueueBinOffset
    adc #amount
    sta.w vqueueBinOffset
.ENDM

; Clobbers A
.MACRO .BranchIfTileXYOOB ARGS XMEM, YMEM, LABEL
    lda XMEM
    cmp #12
    bcs LABEL
    lda YMEM
    cmp #8
    bcs LABEL
.ENDM

.MACRO .TileXYToIndexA ARGS XMEM, YMEM, TEMPMEM
    lda YMEM
    asl
    asl
    sta TEMPMEM
    asl
    clc
    adc TEMPMEM
    adc XMEM
.ENDM

.FUNCTION IS_POW2(x) !(x & (x - 1))

.FUNCTION log2(x) log(x) / log(2.0)

.MACRO .CheapModA8 ARGS num
    .IF num == 1
    .ELIF num > 0 && num <= (2^7) && IS_POW2(num)
        and.b #(num - 1)
    .ELSE
        .FAIL "CheapModA8: invalid num"
    .ENDIF
.ENDM

.MACRO .CheapModA16 ARGS num
    ; .PRINT num "\n"
    ; .PRINT num-1 "\n"
    ; .PRINT num & (num - 1)  "\n"
    ; .PRINT (num & (num - 1))==0 "\n"
    ; .PRINT IS_POW2(num) "\n"
    ; .PRINT 2^15  "\n"
    .IF num == 1
    .ELIF num > 1 && num <= (2^15) && IS_POW2(num)
        and.w #(num - 1)
    .ELSE
        .FAIL "CheapModA16: invalid num"
    .ENDIF
.ENDM

.MACRO .ShiftLeft ARGS num
    .REPT num
        asl
    .ENDR
.ENDM

.MACRO .ShiftRight ARGS num
    .REPT num
        lsr
    .ENDR
.ENDM

.MACRO .MultiplyStatic ARGS num
    .IF num == 0
    .ELIF IS_POW2(num)
        .ShiftLeft round(log2(num))
    .ELSE
        .FAIL "MultiplyStatic: invalid num"
    .ENDIF
.ENDM

.MACRO .DivideStatic ARGS num
    .IF num == 0
    .ELIF IS_POW2(num)
        .ShiftRight round(log2(num))
    .ELSE
        .FAIL "DivideStatic: invalid num"
    .ENDIF
.ENDM

.MACRO .ShiftRight_SIGN ARGS num, do_cmp
    .IF num > 0
        clc
        .IF do_cmp
            cmp #0
        .ENDIF
        bpl +++++
            .IF num > 1
                ora #((2^(num-1)) - 1)
            .ENDIF
            sec
        +++++:
        .REPT num
            ror
        .ENDR
    .ENDIF
.ENDM

; will only break if value overflows :)
.MACRO .ShiftLeft_SIGN ARGS num
    .REPT num
        asl
    .ENDR
.ENDM

; COLLISION

.MACRO .InsertHitboxLite
    .REPT SPATIAL_LAYER_COUNT INDEX i
        ldy.w spatial_partition.{i+1},X
        bne +++++
        sta.w spatial_partition.{i+1},X
        bra @@@@@\.\@
        +++++:
    .ENDR
    @@@@@\.\@:
.ENDM

.MACRO .EraseHitboxLite
    .REPT SPATIAL_LAYER_COUNT INDEX i
        cmp.w spatial_partition.{i+1},X
        beq @@@@@\.\@{i}
    .ENDR
    bra @@@@@\.\@end
    .REPT SPATIAL_LAYER_COUNT INDEX i
        @@@@@\.\@{i}:
        .IF (i != (SPATIAL_LAYER_COUNT-1))
            lda.w spatial_partition.{i+2},X
            sta.w spatial_partition.{i+1},X
            ; beq @@@@@\.\@end
        .ELSE
            stz.w spatial_partition.{i+1},X
        .ENDIF
    .ENDR
    @@@@@\.\@end:
.ENDM

.MACRO .EntityRemoveHitbox ARGS NUM_X, NUM_Y
    lda.w entity_posy+1,Y
    and #$F0
    sta.b $00
    lda.w entity_posx+1,Y
    lsr
    lsr
    lsr
    lsr
    ora.b $00
    sta.b $00
    .REPT NUM_Y INDEX iy
        tax
        .REPT NUM_X INDEX ix
            .IF ix > 0
                inx
            .ENDIF
            tya
            jsr EraseHitbox
        .ENDR
        .IF iy < (NUM_Y-1)
            lda.b $00
            clc
            adc #16
            sta.b $00
        .ENDIF
    .ENDR
.ENDM

.MACRO .EntityAddHitbox ARGS NUM_X, NUM_Y
    sty.b $01
    lda.w entity_posy+1,Y
    and #$F0
    sta.b $00
    lda.w entity_posx+1,Y
    lsr
    lsr
    lsr
    lsr
    ora.b $00
    sta.b $00
    .REPT NUM_Y INDEX iy
        tax
        lda.b $01
        .REPT NUM_X INDEX ix
            .IF ix > 0
                inx
            .ENDIF
            jsr InsertHitbox
        .ENDR
        .IF iy < (NUM_Y-1)
            lda.b $00
            clc
            adc #16
            sta.b $00
        .ENDIF
    .ENDR
    ldy.b $01
.ENDM

; Pathing

.MACRO .DefinePathSpeedTable ARGS tblName, speed, is_wide
    {tblName}_X:
        .IF is_wide == 1
            .dw 0, 0, speed, -speed, 0, 0
        .ELSE
            .db 0, 0, speed, -speed, 0, 0
        .ENDIF
    {tblName}_Y:
        .IF is_wide == 1
            .dw 0, speed, 0, 0, -speed, 0
        .ELSE
            .db 0, speed, 0, 0, -speed, 0
        .ENDIF

.ENDM
