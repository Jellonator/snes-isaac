; test argument against A.
; if argument > A, set A to argument
; as a general rule, macro labels should begin with @@@@@
; that way, these labels don't mess with those in code

; Maximum of A register and memory location, signed
.MACRO AMAX
    cmp \1
    bpl @@@@@\.\@
    lda \1
@@@@@\.\@:
.ENDM

; Minimum of A register and memory location, signed
.MACRO AMIN
    cmp \1
    bmi @@@@@\.\@
    lda \1
@@@@@\.\@:
.ENDM

; Maximum of A register and immediate value, signed
.MACRO AMAXI
    cmp #\1
    bpl @@@@@\.\@
    lda #\1
@@@@@\.\@:
.ENDM

; Minimum of A register and immediate value, signed
.MACRO AMINI
    cmp #\1
    bmi @@@@@\.\@
    lda #\1
@@@@@\.\@:
.ENDM

; Maximum of A register and memory location, unsigned
.MACRO AMAXU
    cmp \1
    bcs @@@@@\.\@
    lda \1
@@@@@\.\@:
.ENDM

; Minimum of A register and memory location, unsigned
.MACRO AMINU
    cmp \1
    bcc @@@@@\.\@
    lda \1
@@@@@\.\@:
.ENDM

; Maximum of A register and immediate value, unsigned
.MACRO AMAXUI
    cmp #\1
    bcs @@@@@\.\@
    lda #\1
@@@@@\.\@:
.ENDM

; Minimum of A register and immediate value, unsigned
.MACRO AMINUI
    cmp #\1
    bcc @@@@@\.\@
    lda #\1
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

.MACRO .MultiplyStatic ARGS num
    .IF num == 1
    .ELIF num == 2
        asl
    .ELIF num == 4
        asl
        asl
    .ELIF num == 8
        asl
        asl
        asl
    .ELIF num == 16
        asl
        asl
        asl
        asl
    .ELIF num == 32
        asl
        asl
        asl
        asl
        asl
    .ELIF num == 64
        asl
        asl
        asl
        asl
        asl
    .ELSE
        .FAIL "CheapModA16: invalid num"
    .ENDIF
.ENDM