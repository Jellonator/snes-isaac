.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "MATH" FREE

ConvertBinaryToDecimalU16:
    .DEFINE RESULT $00
    .INDEX 16
    .ACCU 16
    ; special case: A<10
    cmp.w #10
    bcs +
        rtl
    +:
    .REPT 4 INDEX i
        sta.l DIVU_DIVIDEND
        sep #$20
        lda.b #10
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

.ENDS