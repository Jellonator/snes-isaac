; Context management for subroutines
; The goal of this is to minimize context switching, primarily sep/rep.
; This mostly only saves a few instructions, but there is value in that.

.DEFINE D_FLAG_A -1
.DEFINE D_FLAG_X -1
.DEFINE D_BANK -1
.DEFINE D_DIRECT -1

; Indicates that a register's value is currently unknown
.DEFINE D_UNK -1
; Indicates, in the context of a function, that the register's value is not
; modified by said function.
.DEFINE D_IGNORE -2

; Set the 'A' flag to the given number of bits
.MACRO .SetA ARGS p_a
    .ASSERT p_a == 16 || p_a == 8 || p_a == -1
    .IF p_a != D_FLAG_A && p_a == 16
        rep #$20
    .ELIF p_a != D_FLAG_A && p_a == 8
        sep #$20
    .ENDIF
    .REDEFINE D_FLAG_A p_a
.ENDM

; Set the 'X' flag to the given number of bits
.MACRO .SetX ARGS p_x
    .ASSERT p_x == 16 || p_x == 8 || p_x == -1
    .IF p_x != D_FLAG_X && p_x == 16
        rep #$10
    .ELIF p_x != D_FLAG_X && p_x == 8
        sep #$10
    .ENDIF
    .REDEFINE D_FLAG_X p_x
.ENDM

; Set the 'A' and 'X' flags to the given number of bits
.MACRO .SetAX ARGS p_a, p_x
    .ASSERT p_a == 16 || p_a == 8 || p_a == -1
    .ASSERT p_x == 16 || p_x == 8 || p_x == -1
    .IF p_a != D_FLAG_A && p_x != D_FLAG_X && p_a == 16 && p_x == 16
        rep #$30
    .ELIF p_a != D_FLAG_A && p_x != D_FLAG_X && p_a == 8 && p_x == 8
        sep #$30
    .ELSE
        .IF p_a != D_FLAG_A && p_a == 16
            rep #$20
        .ELIF p_a != D_FLAG_A && p_a == 8
            sep #$20
        .ENDIF
        .IF p_x != D_FLAG_X && p_x == 16
            rep #$10
        .ELIF p_x != D_FLAG_X && p_x == 8
            sep #$10
        .ENDIF
    .ENDIF
    .REDEFINE D_FLAG_A p_a
    .REDEFINE D_FLAG_X p_x
.ENDM

; Set the 'B' register to the given value
.MACRO .SetBank ARGS p_b
    .ASSERT p_b >= $00 && p_b <= $FF || p_b == -1
    .IF p_b != D_BANK && p_b != -1
        pea p_b * $0101
        plb
        plb
    .ENDIF
    .REDEFINE D_BANK p_b
.ENDM

; Set the 'direct' register to the given value
.MACRO .SetDirect ARGS p_d
    .ASSERT p_d >= $00 && p_d <= $FFFF || p_d == -1
    .IF p_d != D_DIRECT && p_d != -1
        pea p_d
        pld
    .ENDIF
    .REDEFINE D_DIRECT p_d
.ENDM

; Clear all register and flag values
; Use this before sections where you don't know what the context will be,
; e.g. before non-context managed functions.
.MACRO .InvalidateFlags
    .REDEFINE D_DIRECT -1
    .REDEFINE D_BANK -1
    .REDEFINE D_FLAG_A -1
    .REDEFINE D_FLAG_X -1
.ENDM

.MACRO .InvalidateA
    .REDEFINE D_FLAG_A -1
.ENDM

.MACRO .InvalidateX
    .REDEFINE D_FLAG_X -1
.ENDM

.MACRO .InvalidateAX
    .REDEFINE D_FLAG_A -1
    .REDEFINE D_FLAG_X -1
.ENDM

.MACRO .InvalidateBank
    .REDEFINE D_BANK -1
.ENDM

.MACRO .InvalidateDirect
    .REDEFINE D_DIRECT -1
.ENDM

; Update INDEX and ACCU without inserting instructions
.MACRO .RefreshFlags
    .IF D_FLAG_A == 8
        .ACCU 8
    .ELIF D_FLAG_A == 16
        .ACCU 16
    .ENDIF
    .IF D_FLAG_X == 8
        .INDEX 8
    .ELIF D_FLAG_X == 16
        .INDEX 16
    .ENDIF
.ENDM

; Set the 'A' flag to the given number of bits, without inserting instructions
.MACRO .UpdateA ARGS p_a
    .ASSERT p_a == 16 || p_a == 8 || p_a == -1
    .IF p_a == 16
        .ACCU 16
    .ELIF p_a == 8
        .ACCU 8
    .ENDIF
    .REDEFINE D_FLAG_A p_a
.ENDM

; Set the 'X' flag to the given number of bits, without inserting instructions
.MACRO .UpdateX ARGS p_x
    .ASSERT p_x == 16 || p_x == 8 || p_x == -1
    .IF p_x == 16
        .INDEX 16
    .ELIF p_x == 8
        .INDEX 8
    .ENDIF
    .REDEFINE D_FLAG_X p_x
.ENDM

; Set the 'A' and 'X' flags to the given number of bits, without inserting instructions
.MACRO .UpdateAX ARGS p_a, p_x
    .ASSERT p_a == 16 || p_a == 8 || p_a == -1
    .ASSERT p_x == 16 || p_x == 8 || p_x == -1
    .IF p_a == 16
        .ACCU 16
    .ELIF p_a == 8
        .ACCU 8
    .ENDIF
    .IF p_x == 16
        .INDEX 16
    .ELIF p_x == 8
        .INDEX 8
    .ENDIF
    .REDEFINE D_FLAG_A p_a
    .REDEFINE D_FLAG_X p_x
.ENDM

; Set the 'B' register to the given value, without inserting instructions
.MACRO .UpdateBank ARGS p_b
    .ASSERT p_b >= $00 && p_b <= $FF || p_b == -1
    .REDEFINE D_BANK p_b
.ENDM

; Set the 'direct' register to the given value, without inserting instructions
.MACRO .UpdateDirect ARGS p_d
    .ASSERT p_d >= $00 && p_d <= $FFFF || p_d == -1
    .REDEFINE D_DIRECT p_d
.ENDM

; Define a context-managed function
; The advantage of using context-managed functions is that they reduce the need
; to switch context flags and registers, saving a few instructions, and
; helping to prevent certain classes of bugs.
; The disadvantage is that these functions must have their definitions included
; before they can be called.
.MACRO .FuncDefine ARGS name
    .IFDEF _IN_CONTEXT_FUNC_DEF
        .FAIL ".FuncDefine can not be used within another .FuncDefine"
    .ENDIF
    .DEFINE _IN_CONTEXT_FUNC_DEF 1

    .DEFINE _FUNC_CONTEXT_NAME name
    ; define 'in' flags for function. These are 'unknown' by default. These
    ; indicate to the callee what these flags should be set to before calling
    .DEFINE {name}_IN_FLAG_A_ -1
    .DEFINE {name}_IN_FLAG_X_ -1
    .DEFINE {name}_IN_BANK_ -1
    .DEFINE {name}_IN_DIRECT_ -1
    ; define 'out' flags for function. These are 'unknown' by default. These
    ; indicate to the callee what these flags will be set to after calling.
    .DEFINE {name}_OUT_FLAG_A_ -3
    .DEFINE {name}_OUT_FLAG_X_ -3
    .DEFINE {name}_OUT_BANK_ -3
    .DEFINE {name}_OUT_DIRECT_ -3
    ; call distance; 0 = jsr, 1 = jsl
    ; when calling a function, this value is asserted to match current bank
    ; Assumed long call by default
    .DEFINE {name}_CALL_ 1
.ENDM

; Within a '.Func', indicates the input value of the 'X' flag.
.MACRO .FuncInX ARGS value
    .ASSERT value == 8 || value == 16 || value == -1
    .REDEFINE {_FUNC_CONTEXT_NAME}_IN_FLAG_X_ value
.ENDM

; Within a '.Func', indicates the input value of the 'A' flag.
.MACRO .FuncInA ARGS value
    .ASSERT value == 8 || value == 16 || value == -1
    .REDEFINE {_FUNC_CONTEXT_NAME}_IN_FLAG_A_ value
.ENDM

; Within a '.Func', indicates the input value of the data bank register.
.MACRO .FuncInBank ARGS value
    .ASSERT value >= $00 && value <= $FF || value == -1
    .REDEFINE {_FUNC_CONTEXT_NAME}_IN_BANK_ value
.ENDM

; Within a '.Func', indicates the input value of the direct register.
.MACRO .FuncInDirect ARGS value
    .ASSERT value >= $0000 && value <= $FFFF || value == -1
    .REDEFINE {_FUNC_CONTEXT_NAME}_IN_DIRECT_ value
.ENDM

; Within a '.Func', indicates the output value of the 'X' flag.
.MACRO .FuncOutX ARGS value
    .ASSERT value == 8 || value == 16 || value == -1
    .REDEFINE {_FUNC_CONTEXT_NAME}_OUT_FLAG_X_ value
.ENDM

; Within a '.Func', indicates the output value of the 'A' flag.
.MACRO .FuncOutA ARGS value
    .ASSERT value == 8 || value == 16 || value == -1
    .REDEFINE {_FUNC_CONTEXT_NAME}_OUT_FLAG_A_ value
.ENDM

; Within a '.Func', indicates the output value of the data bank register.
.MACRO .FuncOutBank ARGS value
    .ASSERT value >= $00 && value <= $FF || value == -1
    .REDEFINE {_FUNC_CONTEXT_NAME}_OUT_BANK_ value
.ENDM

; Within a '.Func', indicates the output value of the direct register.
.MACRO .FuncOutDirect ARGS value
    .ASSERT value >= $0000 && value <= $FFFF || value == -1
    .REDEFINE {_FUNC_CONTEXT_NAME}_OUT_DIRECT_ value
.ENDM

; Within a '.Func', indicates that the 'A' flag is not modified by the function.
.MACRO .FuncIgnoreA
    .REDEFINE {_FUNC_CONTEXT_NAME}_IN_FLAG_A_ -2
    .REDEFINE {_FUNC_CONTEXT_NAME}_OUT_FLAG_A_ -2
.ENDM

; Within a '.Func', indicates that the 'X' flag is not modified by the function.
.MACRO .FuncIgnoreX
    .REDEFINE {_FUNC_CONTEXT_NAME}_IN_FLAG_X_ -2
    .REDEFINE {_FUNC_CONTEXT_NAME}_OUT_FLAG_X_ -2
.ENDM

; Within a '.Func', indicates that the data bank register is not modified
; by the function.
.MACRO .FuncIgnoreBank
    .REDEFINE {_FUNC_CONTEXT_NAME}_IN_BANK_ -2
    .REDEFINE {_FUNC_CONTEXT_NAME}_OUT_BANK_ -2
.ENDM

; Within a '.Func', indicates that the direct register is not modified
; by the function.
.MACRO .FuncIgnoreDirect
    .REDEFINE {_FUNC_CONTEXT_NAME}_IN_DIRECT_ -2
    .REDEFINE {_FUNC_CONTEXT_NAME}_OUT_DIRECT_ -2
.ENDM

; Indicate that this function is a short-call
.MACRO .FuncSetCallShort
    .REDEFINE {_FUNC_CONTEXT_NAME}_CALL_ 0
.ENDM

; Indicate that this function is a long-call
.MACRO .FuncSetCallLong
    .REDEFINE {_FUNC_CONTEXT_NAME}_CALL_ 1
.ENDM

; End a context-managed function definition.
.MACRO .FuncDefineEnd
    .IFNDEF _IN_CONTEXT_FUNC_DEF
        .FAIL ".FuncDefineEnd must be used after .FuncDefine"
    .ENDIF
    .UNDEFINE _IN_CONTEXT_FUNC_DEF
    .IF {_FUNC_CONTEXT_NAME}_OUT_FLAG_A_ == -3
        .REDEFINE {_FUNC_CONTEXT_NAME}_OUT_FLAG_A_ {_FUNC_CONTEXT_NAME}_IN_FLAG_A_
    .ENDIF
    .IF {_FUNC_CONTEXT_NAME}_OUT_FLAG_X_ == -3
        .REDEFINE {_FUNC_CONTEXT_NAME}_OUT_FLAG_X_ {_FUNC_CONTEXT_NAME}_IN_FLAG_X_
    .ENDIF
    .IF {_FUNC_CONTEXT_NAME}_OUT_BANK_ == -3
        .REDEFINE {_FUNC_CONTEXT_NAME}_OUT_BANK_ {_FUNC_CONTEXT_NAME}_IN_BANK_
    .ENDIF
    .IF {_FUNC_CONTEXT_NAME}_OUT_DIRECT_ == -3
        .REDEFINE {_FUNC_CONTEXT_NAME}_OUT_DIRECT_ {_FUNC_CONTEXT_NAME}_IN_DIRECT_
    .ENDIF
    .UNDEFINE _FUNC_CONTEXT_NAME
.ENDM

; Call the context-managed function 'func'
.MACRO .Call ARGS func
    ; set up flags and registers
    .IF {func}_IN_FLAG_A_ != -2 && {func}_IN_FLAG_X_ != -2
        .SetAX {func}_IN_FLAG_A_, {func}_IN_FLAG_X_
    .ELIF {func}_IN_FLAG_A_ != -2
        .SetA {func}_IN_FLAG_A_
    .ELIF {func}_IN_FLAG_X_ != -2
        .SetX {func}_IN_FLAG_X_
    .ENDIF
    .IF {func}_IN_BANK_ != -2
        .SetBank {func}_IN_BANK_
    .ENDIF
    .IF {func}_IN_DIRECT_ != -2
        .SetDirect {func}_IN_DIRECT_
    .ENDIF
    ; call function
    .IF {func}_CALL_ == 1
        jsl {func}
    .ELSE
        jsr {func}
    .ENDIF
    ; indicate that flags and registers have been modified by the function
    .IF {func}_OUT_FLAG_A_ != -2
        .REDEFINE D_FLAG_A {func}_OUT_FLAG_A_
    .ENDIF
    .IF {func}_OUT_FLAG_X_ != -2
        .REDEFINE D_FLAG_X {func}_OUT_FLAG_X_
    .ENDIF
    .IF {func}_OUT_BANK_ != -2
        .REDEFINE D_BANK {func}_OUT_BANK_
    .ENDIF
    .IF {func}_OUT_DIRECT_ != -2
        .REDEFINE D_DIRECT {func}_OUT_DIRECT_
    .ENDIF
    .IF D_FLAG_A == 8
        .ACCU 8
    .ELIF D_FLAG_A == 16
        .ACCU 16
    .ENDIF
    .IF D_FLAG_X == 8
        .INDEX 8
    .ELIF D_FLAG_X == 16
        .INDEX 16
    .ENDIF
.ENDM

; Begin function implementation
.MACRO .FuncImpl ARGS func
    .IFDEF _IN_CONTEXT_FUNC_IMPL
        .FAIL ".FuncImpl can not be used within another .FuncImpl"
    .ENDIF
    .DEFINE _IN_CONTEXT_FUNC_IMPL 1

    .DEFINE _FUNC_CONTEXT_NAME func
    ; set flags to input
    .REDEFINE D_FLAG_A {func}_IN_FLAG_A_
    .REDEFINE D_FLAG_X {func}_IN_FLAG_X_
    .REDEFINE D_BANK {func}_IN_BANK_
    .REDEFINE D_DIRECT {func}_IN_DIRECT_
    .IF D_FLAG_A == 8
        .ACCU 8
    .ELIF D_FLAG_A == 16
        .ACCU 16
    .ENDIF
    .IF D_FLAG_X == 8
        .INDEX 8
    .ELIF D_FLAG_X == 16
        .INDEX 16
    .ENDIF
    ; Stack offset to first parameter
    .IF {func}_CALL_ == 1
        .DEFINE STACK $04
    .ELSE
        .DEFINE STACK $03
    .ENDIF
    {func}:
.ENDM

; End function implementation
.MACRO .FuncImplEnd
    .IFNDEF _IN_CONTEXT_FUNC_IMPL
        .FAIL ".FuncImplEnd must be used after .FuncImpl"
    .ENDIF
    .UNDEFINE _IN_CONTEXT_FUNC_IMPL
    ; validate that flags match output
    .IF {_FUNC_CONTEXT_NAME}_OUT_FLAG_A_ >= 0 && D_FLAG_A != {_FUNC_CONTEXT_NAME}_OUT_FLAG_A_
        .FAIL "Mismatch between defined output and used output of 'A' flag"
    .ENDIF
    .IF {_FUNC_CONTEXT_NAME}_OUT_FLAG_X_ >= 0 && D_FLAG_X != {_FUNC_CONTEXT_NAME}_OUT_FLAG_X_
        .FAIL "Mismatch between defined output and used output of 'X' flag"
    .ENDIF
    .IF {_FUNC_CONTEXT_NAME}_OUT_BANK_ >= 0 && D_BANK != {_FUNC_CONTEXT_NAME}_OUT_BANK_
        .FAIL "Mismatch between defined output and used output of 'data bank' register"
    .ENDIF
    .IF {_FUNC_CONTEXT_NAME}_OUT_DIRECT_ >= 0 && D_DIRECT != {_FUNC_CONTEXT_NAME}_OUT_DIRECT_
        .FAIL "Mismatch between defined output and used output of 'direct' register"
    .ENDIF
    ; invalidate flags now that function has ended
    .InvalidateFlags
    .UNDEFINE STACK
    .UNDEFINE _FUNC_CONTEXT_NAME
.ENDM

; Increment 'STACK' by N
.MACRO .FuncPush ARGS n
    .REDEFINE STACK (STACK+n)
.ENDM

; Decrement 'STACK' by N
.MACRO .FuncPull ARGS n
    .REDEFINE STACK (STACK-n)
.ENDM

; Set 'STACK' to N
.MACRO .FuncSetStack ARGS n
    .REDEFINE STACK n
.ENDM