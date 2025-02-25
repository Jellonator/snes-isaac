; as a general rule, macro labels should begin with @@@@@
; that way, these labels don't mess with those in code

; META INSTRUCTIONS

; BRANCH EQUAL LONG
.MACRO beql ARGS addr
    bne +++++
        jmp addr
    +++++:
.ENDM
; BRANCH NOT EQUAL LONG
.MACRO bnel ARGS addr
    beq +++++
        jmp addr
    +++++:
.ENDM
; BRANCH CARRY CLEAR LONG
.MACRO bccl ARGS addr
    bcs +++++
        jmp addr
    +++++:
.ENDM
; BRANCH CARRY SET LONG
.MACRO bcsl ARGS addr
    bcc +++++
        jmp addr
    +++++:
.ENDM
; BRANCH OVERFLOW CLEAR LONG
.MACRO bvcl ARGS addr
    bvs +++++
        jmp addr
    +++++:
.ENDM
; BRANCH OVERFLOW SET LONG
.MACRO bvsl ARGS addr
    bvc +++++
        jmp addr
    +++++:
.ENDM
; BRANCH MINUS LONG / BRANCH NEGATIVE SET LONG
.MACRO bmil ARGS addr
    bpl +++++
        jmp addr
    +++++:
.ENDM
; BRANCH PLUS LONG / BRANCH NEGATIVE CLEAR LONG
.MACRO bpll ARGS addr
    bmi +++++
        jmp addr
    +++++:
.ENDM
; BRANCH LESS THAN UNSIGNED
.MACRO blsu ARGS addr
    bcc addr
.ENDM
; BRANCH LESS THAN SIGNED
.MACRO blss ARGS addr
    bmi addr
.ENDM
; BRANCH LESS THAN OR EQUAL UNSIGNED
.MACRO bleu ARGS addr
    bcc addr
    beq addr
.ENDM
; BRANCH LESS THAN OR EQUAL SIGNED
.MACRO bles ARGS addr
    bmi addr
    beq addr
.ENDM
; BRANCH GREATER THAN UNSIGNED
.MACRO bgru ARGS addr
    beq +++++
        bcs addr
    +++++:
.ENDM
; BRANCH GREATER THAN SIGNED
.MACRO bgrs ARGS addr
    beq +++++
        bpl addr
    +++++:
.ENDM
; BRANCH GREATER THAN OR EQUAL UNSIGNED
.MACRO bgeu ARGS addr
    bcs addr
.ENDM
; BRANCH GREATER THAN OR EQUAL SIGNED
.MACRO bges ARGS addr
    bpl addr
.ENDM
; BRANCH LESS THAN UNSIGNED LONG
.MACRO blsul ARGS addr
    bccl addr
.ENDM
; BRANCH LESS THAN SIGNED LONG
.MACRO blssl ARGS addr
    bmil addr
.ENDM
; BRANCH LESS THAN OR EQUAL UNSIGNED LONG
.MACRO bleul ARGS addr
    bccl addr
    beql addr
.ENDM
; BRANCH LESS THAN OR EQUAL SIGNED LONG
.MACRO blesl ARGS addr
    bmil addr
    beql addr
.ENDM
; BRANCH GREATER THAN UNSIGNED LONG
.MACRO bgrul ARGS addr
    beq +++++
        bcsl addr
    +++++:
.ENDM
; BRANCH GREATER THAN SIGNED LONG
.MACRO bgrsl ARGS addr
    beq +++++
        bpll addr
    +++++:
.ENDM
; BRANCH GREATER THAN OR EQUAL UNSIGNED LONG
.MACRO bgeul ARGS addr
    bcsl addr
.ENDM
; BRANCH GREATER THAN OR EQUAL SIGNED LONG
.MACRO bgesl ARGS addr
    bpll addr
.ENDM

; GENERIC INSTRUCTIONS

; Generic instruction types
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

; Generic Instruction invocation
; Note that many instruction,method pairs are invalid.
; Parameters:
;   inst   - the instruction
;   method - address mode
;   arg    - address/value
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

; COMPARE

; Begin signed compare: IF less than
.MACRO .CMPS_BEGIN ARGS method, addr
    sec
    .g_instruction sbc, method, addr
    bvs @@@@@\@cmps_invert
    bpl @@@@@\@cmps_greater
@@@@@\@cmps_lesser:
.ENDM

; Signed Compare: IF greather than
.MACRO .CMPS_GREATER
    bra @@@@@\@cmps_end
@@@@@\@cmps_invert:
    bpl @@@@@\@cmps_lesser
@@@@@\@cmps_greater:
.ENDM


; Signed Compare: IF equal to than
.MACRO .CMPS_EQUAL
    bra @@@@@\@cmps_end
@@@@@\@cmps_equal:
.ENDM

; End signed compare
.MACRO .CMPS_END
@@@@@\@cmps_end:
.ENDM

; MATH

; Generic signed MAXIMUM
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

; Generic signed MINIMUM
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

; Generic unsigned MAXIMUM
.MACRO .AMAXU ARGS method, addr
    .g_instruction cmp, method, addr
    bcs @@@@@\.\@
        .g_instruction lda, method, addr
    @@@@@\.\@:
.ENDM

; Generic unsigned MINIMUM
.MACRO .AMINU ARGS method, addr
    .g_instruction cmp, method, addr
    bcc @@@@@\.\@
        .g_instruction lda, method, addr
    @@@@@\.\@:
.ENDM

; Calculate the absolute value of A, in 16b mode
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

; Negate 16b A register
.MACRO .NEG_A16
    eor.w #$FFFF
    inc A
.ENDM

; Calculate the absolute value of A, in 8b mode
; ONLY use after an instruction that loads the value into A (checks N flag)
.MACRO .ABS_A8_POSTLOAD
    bpl @@@@@\.\@
    eor.b #$FF
    inc A
@@@@@\.\@:
.ENDM

; Negate 8b register
.MACRO .NEG_A8
    eor.w #$FF
    inc A
.ENDM

; TRUE if x is a power of 2
.FUNCTION IS_POW2(x) !(x & (x - 1))

; returns log₂x
.FUNCTION log2(x) log(x) / log(2.0)

; Cheap method of (A % num), in 8b mode
; only works if 'num' is a power of 2
.MACRO .CheapModA8 ARGS num
    .IF num == 1
    .ELIF num > 0 && num <= (2^7) && IS_POW2(num)
        and.b #(num - 1)
    .ELSE
        .FAIL "CheapModA8: invalid num"
    .ENDIF
.ENDM

; Cheap modulo (A % num), in 16b mode
; only works if 'num' is a power of 2
.MACRO .CheapModA16 ARGS num
    .IF num == 1
    .ELIF num > 1 && num <= (2^15) && IS_POW2(num)
        and.w #(num - 1)
    .ELSE
        .FAIL "CheapModA16: invalid num"
    .ENDIF
.ENDM

; shift accumulator left by 'num' (A << num)
.MACRO .ShiftLeft ARGS num
    .REPT num
        asl
    .ENDR
.ENDM

; shift accumulator right by 'num' (A >> num)
.MACRO .ShiftRight ARGS num
    .REPT num
        lsr
    .ENDR
.ENDM

; Cheap multiplication (A * num)
; only works if 'num' is a power of 2
.MACRO .MultiplyStatic ARGS num
    .IF num == 0
    .ELIF IS_POW2(num)
        .ShiftLeft round(log2(num))
    .ELSE
        .FAIL "MultiplyStatic: invalid num"
    .ENDIF
.ENDM

; Cheap division (A / num)
; only works if 'num' is a power of 2
; Rounds down
.MACRO .DivideStatic ARGS num
    .IF num == 0
    .ELIF IS_POW2(num)
        .ShiftRight round(log2(num))
    .ELSE
        .FAIL "DivideStatic: invalid num"
    .ENDIF
.ENDM

; Signed right-shift of accumulator (A >> num)
; e.g. (-16 >> 2) => -4
; set 'do_cmp' if A was not just loaded into accumulator
; kinda slow
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

; Signed left-shift of accumulator (A << num)
; e.g. (-16 < 2) => -64
; will break if value overflows :)
.MACRO .ShiftLeft_SIGN ARGS num
    .REPT num
        asl
    .ENDR
.ENDM

; Convert signed 8B to 16B
; Assuming that we are currently in 8B mode
; set 'do_cmp' if A was not just loaded into the accumulator
; set 'b_is_zero' if top half of A is known to be 0
.MACRO .Convert8To16_SIGNED ARGS do_cmp, b_is_zero
    .IF do_cmp
        cmp #0
    .ENDIF
    rep #$20
    bpl @@@@@\.\@pos
        ora #$FF00
        .IF !b_is_zero
            jmp @@@@@\.\@end
        .ENDIF
    @@@@@\.\@pos:
    .IF !b_is_zero
        and #$00FF
    .ENDIF
    @@@@@\.\@end:
.ENDM

.FUNCTION bin2dec(x) ((x # 10) | (((x / 10) # 10) << 4) | (((x / 100) # 10) << 8) | (((x / 1000) # 10) << 12))

; UTILITY

; Change data bank to value
.MACRO .ChangeDataBank ARGS bank
    pea bank + ($0100*(bank))
    plb
    plb
.ENDM

; Pop N bytes
.MACRO .POPN ARGS NUM
    .IF NUM == 0
    .ELIF NUM == 1
        sep #$20
        pla
    .ELIF NUM == 2
        rep #$20
        pla
    .ELIF NUM == 4
        rep #$20
        pla
        pla
    .ELSE
        rep #$21
        tsc
        adc #NUM
        tcs
    .ENDIF
.ENDM

.FUNCTION spriteoffset(spriteId) ((spriteId - 1) * 4)

.FUNCTION hirombankid(addr) (bankbyte(addr) & $3F)

.FUNCTION spriteoffs(bit_depth, num_tiles, frame) (num_tiles * bit_depth * frame * 8)

.FUNCTION spritesize(bit_depth, num_tiles) (num_tiles * bit_depth * 8)

.FUNCTION bankaddr(addr) (bankbyte(addr) * $10000)

; Pathing

.MACRO .DefinePathSpeedTable ARGS tblName, speed, is_wide
    {tblName}_X:
        .IF is_wide == 1
            .dw 0, 0, speed, -speed, 0, -speed/SQRT2, speed/SQRT2, -speed/SQRT2, speed/SQRT2, 0
        .ELSE
            .db 0, 0, speed, -speed, 0, -speed/SQRT2, speed/SQRT2, -speed/SQRT2, speed/SQRT2, 0
        .ENDIF
    {tblName}_Y:
        .IF is_wide == 1
            .dw 0, speed, 0, 0, -speed, -speed/SQRT2, -speed/SQRT2, speed/SQRT2, speed/SQRT2, 0
        .ELSE
            .db 0, speed, 0, 0, -speed, -speed/SQRT2, -speed/SQRT2, speed/SQRT2, speed/SQRT2, 0
        .ENDIF

.ENDM

; RNG

; Begin chance table, with 'x' chance units (usually 256)
.MACRO .ChanceTableBegin ARGS x
    .DEFINE _ChanceTableV x
.ENDM

; Add 'probability' chances for 'value', 16b
.MACRO .ChanceTableDW ARGS probability, value
    .REDEFINE _ChanceTableV (_ChanceTableV - probability)
    .REPT probability
        .dw value
    .ENDR
.ENDM

; Add 'probability' chances for 'value', 8b
.MACRO .ChanceTableDB ARGS probability, value
    .REDEFINE _ChanceTableV (_ChanceTableV - probability)
    .REPT probability
        .db value
    .ENDR
.ENDM

; Set remaining changes to 'value', 16b
.MACRO .ChanceTableRestDW ARGS value
    .IF _ChanceTableV < 0
        .ERROR "Chance table is overfilled"
    .ENDIF
    .REPT max(0, _ChanceTableV)
        .dw value
    .ENDR
.ENDM

; Set remaining changes to 'value', 8b
.MACRO .ChanceTableRestDB ARGS value
    .IF _ChanceTableV < 0
        .ERROR "Chance table is overfilled"
    .ENDIF
    .REPT max(0, _ChanceTableV)
        .db value
    .ENDR
.ENDM

; End chance table
.MACRO .ChanceTableEnd
    .UNDEFINE _ChanceTableV
.ENDM

; Reset all registers and state to know values
.MACRO .ClearCPU
    clc
    xce ; disable emulation mode
    rep #$38 ; disable binary mode
    ldx #$1FFF
    txs ; reset stack pointer
    pea $0000
    plb
    plb ; Set BANK to $0000
    lda #0
    tcd
    jsl ResetRegisters
    sep #$20
    lda #$01
    sta MEMSEL ; set FastROM
.ENDM

.MACRO .DisableINT
    sei
    sep #$20
    lda #1
    sta.w NMITIMEN
.ENDM

.MACRO .EnableINT
    sep #$20
    cli
    lda #$81
    sta NMITIMEN
.ENDM

.MACRO .DisableRENDER
    sep #$20
    lda #%10000000
    sta.w INIDISP
.ENDM

.MACRO .EnableRENDER
    sep #$20
    lda.w roomBrightness
    sta.w INIDISP
.ENDM