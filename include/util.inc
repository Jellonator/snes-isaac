; test argument against A.
; if argument > A, set A to argument
; as a general rule, macro labels should begin with @@@@@
; that way, these labels don't mess with those in code

.ENUMID 0
.ENUMID P_IMM
.ENUMID P_ABS
.ENUMID P_ABS_X
.ENUMID P_ABS_Y
.ENUMID P_ABS_IND
.ENUMID P_ABS_INDL
.ENUMID P_DIR
.ENUMID P_DIR_X
.ENUMID P_DIR_Y
.ENUMID P_DIR_IND
.ENUMID P_DIR_INDL
.ENUMID P_DIR_X_IND
.ENUMID P_DIR_IND_Y
.ENUMID P_DIR_INDL_Y
.ENUMID P_LONG
.ENUMID P_LONG_X
.ENUMID P_STACK
.ENUMID P_STACK_IND_Y
.ENUMID P_IMPLIED
.ENUMID P_REL8
.ENUMID P_REL16
.ENUMID P_SRC_DEST

; meta instructions
.MACRO beql ARGS addr
    bne +++++
        jmp addr
    +++++:
.ENDM
.MACRO bnel ARGS addr
    beq +++++
        jmp addr
    +++++:
.ENDM
.MACRO bccl ARGS addr
    bcs +++++
        jmp addr
    +++++:
.ENDM
.MACRO bcsl ARGS addr
    bcc +++++
        jmp addr
    +++++:
.ENDM
.MACRO bvcl ARGS addr
    bvs +++++
        jmp addr
    +++++:
.ENDM
.MACRO bvsl ARGS addr
    bvc +++++
        jmp addr
    +++++:
.ENDM
.MACRO bmil ARGS addr
    bpl +++++
        jmp addr
    +++++:
.ENDM
.MACRO bpll ARGS addr
    bmi +++++
        jmp addr
    +++++:
.ENDM

; GENERIC INSTRUCTION
; Parameters:
;   inst   - the instruction
;   method - address mode
;   arg    - address
.MACRO .g_instruction ARGS inst method arg
    .IF method == P_IMM
        \1 #arg
    .ELIF method == P_ABS
        \1.w arg
    .ELIF method == P_ABS_X
        \1.w arg,X
    .ELIF method == P_ABS_Y
        \1.w arg,Y
    .ELIF method == P_ABS_IND
        \1.w (arg)
    .ELIF method == P_ABS_INDL
        \1.w [arg]
    .ELIF method == P_DIR
        \1.b arg
    .ELIF method == P_DIR_X
        \1.b arg,X
    .ELIF method == P_DIR_Y
        \1.b arg,Y
    .ELIF method == P_DIR_IND
        \1.b (arg)
    .ELIF method == P_DIR_INDL
        \1.b [arg]
    .ELIF method == P_DIR_X_IND
        \1.b (arg,X)
    .ELIF method == P_DIR_IND_Y
        \1.b (arg),Y
    .ELIF method == P_DIR_INDL_Y
        \1.b [arg],Y
    .ELIF method == P_LONG
        \1.l arg
    .ELIF method == P_LONG_X
        \1.l arg,X
    .ELIF method == P_STACK
        \1 arg,S
    .ELIF method == P_STACK_IND_Y
        \1 (arg,S),Y
    .ELIF method == P_REL8 || method == P_REL16
        \1 arg
    .ELIF method == P_IMPLIED || method == P_SRC_DEST
        .FAIL "Incompatible addressing mode"
    .ELSE
        .FAIL "Invalid addressing mode"
    .ENDIF
.ENDM

.MACRO .CMPS_BEGIN ARGS method, addr
    sec
    .g_instruction sbc, method, addr
    bvs @@@@@\@cmps_invert
    bpl @@@@@\@cmps_greater
@@@@@\@cmps_lesser:
.ENDM

.MACRO .CMPS_GREATER
    bra @@@@@\@cmps_end
@@@@@\@cmps_invert:
    bpl @@@@@\@cmps_lesser
@@@@@\@cmps_greater:
.ENDM

.MACRO .CMPS_EQUAL
    bra @@@@@\@cmps_end
@@@@@\@cmps_equal:
.ENDM

.MACRO .CMPS_END
@@@@@\@cmps_end:
.ENDM

.MACRO .AMAX ARGS method arg
    sec
    .g_instruction sbc, method, arg
    bvs @@@@@@\.\@invert
    bpl @@@@@@\.\@restore
@@@@@@\.\@load:
    .g_instruction lda, method, arg
    bra @@@@@@\.\@end
@@@@@@\.\@invert:
    bpl @@@@@@\.\@load
@@@@@@\.\@restore:
    clc
    .g_instruction adc, method, arg
@@@@@@\.\@end:
.ENDM

; Minimum of A register and value, signed
.MACRO .AMIN ARGS method, arg
    sec
    .g_instruction sbc, method, arg
    bvs @@@@@@\.\@invert
    bmi @@@@@@\.\@restore
@@@@@@\.\@load:
    .g_instruction lda, method, arg
    bra @@@@@@\.\@end
@@@@@@\.\@invert:
    bmi @@@@@@\.\@load
@@@@@@\.\@restore:
    clc
    .g_instruction adc, method, arg
@@@@@@\.\@end:
.ENDM

; Maximum of A register and value, unsigned
.MACRO .AMAXU ARGS method, addr
    .g_instruction cmp, method, addr
    bcs @@@@@\.\@
        .g_instruction lda, method, addr
    @@@@@\.\@:
.ENDM

; Minimum of A register and value, unsigned
.MACRO .AMINU ARGS method, addr
    .g_instruction cmp, method, addr
    bcc @@@@@\.\@
        .g_instruction lda, method, addr
    @@@@@\.\@:
.ENDM

; Calculate the absolute value of A
; ONLY use after an instruction that loads the value into A (checks N flag)
; e.g.: ADC, SBC, DEC, INC, AND, ORA, EOR, ASL, LSR, ROL, ROR, LDA, PLA, TXA, and TYA
; some other instructions also set the N flag but may either refer to a
; different register (e.g. LDX), or don't reflect the current value of A (e.g. CMP)
.MACRO .ABS_A16_POSTLOAD
    bpl @@@@@\.\@
    eor.w #$FFFF
    inc A
@@@@@\.\@:
.ENDM

.MACRO .NEG_A16
    eor.w #$FFFF
    inc A
.ENDM

; Calculate the absolute value of A
; ONLY use after an instruction that loads the value into A (checks N flag)
.MACRO .ABS_A8_POSTLOAD
    bpl @@@@@\.\@
    eor.b #$FF
    inc A
@@@@@\.\@:
.ENDM

.MACRO .NEG_A8
    eor.w #$FF
    inc A
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

.MACRO .SetCurrentObjectS
    lda.w objectIndex
    lsr
    lsr
    lsr
    lsr
    tay
    ldx.w objectIndex
    lda.l SpriteIndexToExtMaskS,X
    ora.w objectDataExt,Y
    sta.w objectDataExt,Y
.ENDM

.MACRO .SetCurrentObjectS_Inc
    .SetCurrentObjectS
    inx
    inx
    inx
    inx
    stx.w objectIndex
.ENDM

.MACRO .SetCurrentObjectX
    lda.w objectIndex
    lsr
    lsr
    lsr
    lsr
    tay
    ldx.w objectIndex
    lda.l SpriteIndexToExtMaskX,X
    ora.w objectDataExt,Y
    sta.w objectDataExt,Y
.ENDM

.MACRO .SetCurrentObjectX_Inc
    .SetCurrentObjectX
    inx
    inx
    inx
    inx
    stx.w objectIndex
.ENDM

.MACRO .SetCurrentObjectXS
    lda.w objectIndex
    lsr
    lsr
    lsr
    lsr
    tay
    ldx.w objectIndex
    lda.l SpriteIndexToExtMaskXS,X
    ora.w objectDataExt,Y
    sta.w objectDataExt,Y
.ENDM

.MACRO .SetCurrentObjectXS_Inc
    .SetCurrentObjectXS
    inx
    inx
    inx
    inx
    stx.w objectIndex
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
    lda.w objectData.1.pos_x,X
    and #$FF
    eor #$FFFF
    sec
    adc #1
    bra @@@@@\.\@end
@@@@@\.\@pos:
    plx
    lda.w objectData.1.pos_x,X
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
    sta.w objectData.1.pos_x,X
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
    sta.w objectData.1.pos_x,X
    rep #$20 ; 16b A
@@@@@\.\@end:
    pla
    ply
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
.ENDM

; Clobbers A
.MACRO .VQueueOpIncX
    txa
    clc
    adc #8
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

.MACRO .PositionToTileIndex ARGS XACCESS, XADDR, YACCESS, YADDR, TMP
    .g_instruction lda, XACCESS, XADDR
    lsr
    lsr
    lsr
    lsr
    sta.b TMP
    .g_instruction lda, YACCESS, YADDR
    and #$FF00
    ora.b TMP
    tax
    lda.l GameTileToRoomTileIndexTable,X
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

; define tile
.FUNCTION deft(chr,pal) (chr | (pal << 10))
.DEFINE T_HIGHP 0x2000
.DEFINE T_FLIPH 0x4000
.DEFINE T_FLIPV 0x8000
.DEFINE T_FLIPVH 0xC000

.FUNCTION spriteoffset(spriteId) ((spriteId - 1) * 4)

.FUNCTION hirombankid(addr) (bankbyte(addr) & $3F)

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
        .IF do_cmp
            cmp #0
        .ENDIF
        bpl @@@@@\.\@pos
            sec
            .IF num > 1
                ora #((2^(num-1)) - 1)
            .ENDIF
            .REPT num
                ror
            .ENDR
            ; ora #((2^(num-1)) - 1) << num
            ; sec
            jmp @@@@@\.\@end
        @@@@@\.\@pos:
            .REPT num
                lsr
            .ENDR
        ; .REPT num
        ;     ror
        ; .ENDR
        @@@@@\.\@end:
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

; Entity Utilities

.MACRO .EntityEasySetBox ARGS width, height
    sep #$20

    lda.w entity_box_x1,Y
    clc
    adc #width
    sta.w entity_box_x2,Y

    lda.w entity_box_y1,Y
    clc
    adc #height
    sta.w entity_box_y2,Y
.ENDM

.MACRO .EntityEasyCheckPlayerCollision_Box ARGS addr
    sep #$20

    lda.w entity_box_x1,Y
    cmp.w player_box_x2
    bpl addr

    lda.w entity_box_x2,Y
    cmp.w player_box_x1
    bmi addr

    lda.w entity_box_y1,Y
    cmp.w player_box_y2
    bpl addr

    lda.w entity_box_y2,Y
    cmp.w player_box_y1
    bmi addr
.ENDM

.MACRO .EntityEasyCheckPlayerCollision_Rect ARGS addr, left, right, top, bottom
    sep #$20

    lda.w entity_box_x1,Y
    clc
    adc #left
    cmp.w player_box_x2
    bpl addr

    lda.w entity_box_x2,Y
    clc
    adc #right
    cmp.w player_box_x1
    bmi addr

    lda.w entity_box_y1,Y
    clc
    adc #top
    cmp.w player_box_y2
    bpl addr

    lda.w entity_box_y2,Y
    clc
    adc #bottom
    cmp.w player_box_y1
    bmi addr
.ENDM

.MACRO .EntityEasyCheckPlayerCollision_Center ARGS addr, offx, offy
    sep #$20

    lda.w entity_box_x1,Y
    clc
    adc #offx
    cmp.w player_box_x2
    bpl addr
    cmp.w player_box_x1
    bmi addr

    lda.w entity_box_y1,Y
    clc
    adc #offy
    cmp.w player_box_y2
    bpl addr
    cmp.w player_box_y1
    bmi addr
.ENDM

.FUNCTION entityvariant(e, v) (e | (v * $0100))

.MACRO .ChanceTableBegin ARGS x
    .DEFINE _ChanceTableV x
.ENDM

.MACRO .ChanceTableDW ARGS probability, value
    .REDEFINE _ChanceTableV (_ChanceTableV - probability)
    .REPT probability
        .dw value
    .ENDR
.ENDM

.MACRO .ChanceTableDB ARGS probability, value
    .REDEFINE _ChanceTableV (_ChanceTableV - probability)
    .REPT probability
        .db value
    .ENDR
.ENDM

.MACRO .ChanceTableRestDW ARGS value
    .IF _ChanceTableV < 0
        .ERROR "Chance table is overfilled"
    .ENDIF
    .REPT max(0, _ChanceTableV)
        .dw value
    .ENDR
.ENDM

.MACRO .ChanceTableRestDB ARGS value
    .IF _ChanceTableV < 0
        .ERROR "Chance table is overfilled"
    .ENDIF
    .REPT max(0, _ChanceTableV)
        .db value
    .ENDR
.ENDM

.MACRO .ChanceTableEnd
    .UNDEFINE _ChanceTableV
.ENDM