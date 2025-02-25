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

.ENDS