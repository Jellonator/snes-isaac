.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "MATH" FREE

ConvertBinaryToDecimalU16:
    .DEFINE RESULT $00
    .INDEX 16
    .ACCU 16
    ; special case: A<10
    cmp #10
    bcs +
        rtl
    +:
    .REPT 4 INDEX i
        sta.l DIVU_DIVIDEND
        sep #$20
        lda #10
        sta.l DIVU_DIVISOR
        rep #$20
        rep #$20
        .REPT 5
            nop
        .ENDR
        lda.l DIVU_REMAINDER
        .IF i == 0
            sta.b RESULT
        .ELIF i == 1
            asl
            asl
            asl
            asl
            tsb.b RESULT
        .ELIF i == 2
            xba
            tsb.b RESULT
        .ELSE
            asl
            asl
            asl
            asl
            xba
            tsb.b RESULT
        .ENDIF
        .IF i != 3
            lda.l DIVU_QUOTIENT
        .ENDIF
    .ENDR
    lda.b RESULT
    rtl
    .UNDEFINE RESULT

ConvertBinaryToDecimalU8:
    .DEFINE RESULT $00
    .ACCU 8
    ; special case: A<10
    cmp #10
    bcs +
        rtl
    +:
    xba
    lda #0
    .REPT 2 INDEX i
        sta.l DIVU_DIVIDEND+1
        xba
        sta.l DIVU_DIVIDEND
        lda #10
        sta.l DIVU_DIVISOR
        .REPT 8
            nop
        .ENDR
        lda.l DIVU_REMAINDER
        .IF i == 0
            sta.b RESULT
        .ELSE
            asl
            asl
            asl
            asl
            tsb.b RESULT
        .ENDIF
        .IF i != 1
            lda.l DIVU_QUOTIENT
        .ENDIF
        xba
    .ENDR
    lda.b RESULT
    rtl
    .UNDEFINE RESULT

; Get square root of 16b accumulator, rounded down
; Since there are only 256 possible values, we can just use a binary search
; powered by far too many compare instructions
Sqrt16:
    rep #$30
    cmp #2
    bcs +
        rtl
    +:
; first bisection
    cmp #128*128
    bcc @iter2_ls_128
    jmp @iter2_ge_128
    .REPT 6 INDEX bisection
        .DEFINE BASE pow(2, 6-bisection)
        .REPT pow(2, bisection) INDEX i
            .DEFINE SECTION (4*BASE*i + 2*BASE)
            @iter{bisection+2}_ls_{SECTION}:
                cmp #pow(SECTION - BASE, 2)
                bccl @iter{bisection+3}_ls_{SECTION - BASE}
                jmp @iter{bisection+3}_ge_{SECTION - BASE}
            @iter{bisection+2}_ge_{SECTION}:
                cmp #pow(SECTION + BASE, 2)
                bccl @iter{bisection+3}_ls_{SECTION + BASE}
                jmp @iter{bisection+3}_ge_{SECTION + BASE}
            .UNDEFINE SECTION
        .ENDR
        .UNDEFINE BASE
    .ENDR
    .REPT 64 INDEX i
        .DEFINE SECTION (4*i + 2)
        @iter8_ls_{SECTION}:
            cmp #pow(SECTION - 1, 2)
            bcs +
                lda #SECTION - 2
                rtl
            +:
                lda #SECTION - 1
                rtl
        @iter8_ge_{SECTION}:
            cmp #pow(SECTION+  1, 2)
            bcs +
                lda #SECTION
                rtl
            +:
                lda #SECTION + 1
                rtl
        .UNDEFINE SECTION
    .ENDR
.ENDS