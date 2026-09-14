; Context management for subroutines
; The goal of this is to minimize context switching, primarily sep/rep.
; This mostly only saves a few instructions, but there is value in that.

; Current width of the A register
.DEFINE D_FLAG_A -1
; Current width of the INDEX registers
.DEFINE D_FLAG_X -1
; Current value of the BANK register
.DEFINE D_BANK -1
; Current value of the DIRECT PAGE register
.DEFINE D_DIRECT -1

; Indicates that a register's value is currently unknown
; For a procedure's input, indicates that the register value is not important.
; For a procedure's output, indicates that the register value could be anything.
.DEFINE D_UNK -1
; Indicates that a register's value is not important.
; For a procedure, indicates that the register value is not important,
; will not be modified, and its value is not used.
.DEFINE D_IGNORE -2
; Indicates that a register's value is parameterized.
; For a procedure's input, indicates that the register's value is a paramter.
; For a procedure's output, indicates that the register's value is a return.
.DEFINE D_PARAMETER -3
; Special bank value: anything that has mirrored access to $0000-$1FFF; i.e.:
; banks $00-3F, $80-BF, $7E
.DEFINE D_BANK_MIRROR_LOWRAM $10000
; Special bank value: anything that has mirrored access to $0000-$7FFF
; banks $00-3F, $80-BF
.DEFINE D_BANK_MIRROR_IO $10001

.DEFINE PROC_CALL_LONG 1
.DEFINE PROC_CALL_SHORT 2

.DEFINE _CONTEXT_STACK_SIZE 0

.FUNCTION is_bank_io(bank) (bank == D_BANK_MIRROR_IO) || ((bank >= $00) && (bank <= $3F)) || ((bank >= $80) && (bank <= $BF))
.FUNCTION is_bank_lowram(bank) (bank == D_BANK_MIRROR_LOWRAM) || is_bank_io(bank) || (bank == $7E)
.FUNCTION is_bank_specific(bank) (bank >= $00) && (bank <= $FF)
.FUNCTION is_direct_specific(dp) (dp >= $0000) && (dp <= $FFFF)
.FUNCTION is_flag_specific(flag) (flag >= 0)
.FUNCTION is_valid_inout_pair(inflag, outflag) ((inflag != D_IGNORE) && (outflag != D_IGNORE)) || ((inflag == D_IGNORE) && (outflag == D_IGNORE))

; Set the 'A' flag to the given number of bits
.MACRO .SetA ARGS p_a
    .ASSERT (p_a == 16) || (p_a == 8)
    .IF (p_a != D_FLAG_A) && (p_a == 16)
        rep #$20
    .ELIF (p_a != D_FLAG_A) && (p_a == 8)
        sep #$20
    .ENDIF
    .REDEFINE D_FLAG_A p_a
.ENDM

; Set the 'X' flag to the given number of bits
.MACRO .SetX ARGS p_x
    .ASSERT (p_x == 16) || (p_x == 8)
    .IF (p_x != D_FLAG_X) && (p_x == 16)
        rep #$10
    .ELIF (p_x != D_FLAG_X) && (p_x == 8)
        sep #$10
    .ENDIF
    .REDEFINE D_FLAG_X p_x
.ENDM

; Set the 'A' and 'X' flags to the given number of bits
.MACRO .SetAX ARGS p_a, p_x
    .ASSERT (p_a == 16) || (p_a == 8)
    .ASSERT (p_x == 16) || (p_x == 8)
    ; widening both A and X
    .IF (p_a != D_FLAG_A) && (p_x != D_FLAG_X) && (p_a == 16) && (p_x == 16)
        rep #$30
    ; narrowing both A and X
    .ELIF (p_a != D_FLAG_A) && (p_x != D_FLAG_X) && (p_a == 8) && (p_x == 8)
        sep #$30
    .ELSE
        ; change A
        .IF (p_a != D_FLAG_A) && (p_a == 16)
            rep #$20
        .ELIF (p_a != D_FLAG_A) && (p_a == 8)
            sep #$20
        .ENDIF
        ; Change X
        .IF (p_x != D_FLAG_X) && (p_x == 16)
            rep #$10
        .ELIF (p_x != D_FLAG_X) && (p_x == 8)
            sep #$10
        .ENDIF
    .ENDIF
    .REDEFINE D_FLAG_A p_a
    .REDEFINE D_FLAG_X p_x
.ENDM

; Set the 'B' register to the given value
.MACRO .SetBank ARGS p_b
    .ASSERT ((p_b >= $00) && (p_b <= $FF))
    ; Technically not the fastest method, but this guarantees A is kept
    .IF (p_b != D_BANK) && (p_b != -1)
        pea p_b * $0101
        plb
        plb
    .ENDIF
    .REDEFINE D_BANK p_b
.ENDM

; Set the 'direct' register to the given value
.MACRO .SetDirect ARGS p_d
    .ASSERT ((p_d >= $00) && (p_d <= $FFFF))
    .IF (p_d != D_DIRECT) && (p_d != -1)
        pea p_d
        pld
    .ENDIF
    .REDEFINE D_DIRECT p_d
.ENDM

; Set the 'A' flag to the given number of bits.
; Guarantees a `rep` or `sep` instruction
.MACRO .ForceSetA ARGS p_a
    .ASSERT (p_a == 16) || (p_a == 8)
    .IF p_a == 16
        rep #$20
    .ELIF p_a == 8
        sep #$20
    .ENDIF
    .REDEFINE D_FLAG_A p_a
.ENDM

; Set the 'X' flag to the given number of bits
; Guarantees a `rep` or `sep` instruction
.MACRO .ForceSetX ARGS p_x
    .ASSERT (p_x == 16) || (p_x == 8)
    .IF p_x == 16
        rep #$10
    .ELIF p_x == 8
        sep #$10
    .ENDIF
    .REDEFINE D_FLAG_X p_x
.ENDM

; Set the 'A' and 'X' flags to the given number of bits
; Guarantees a `rep` and/or `sep` instruction
.MACRO .ForceSetAX ARGS p_a, p_x
    .ASSERT (p_a == 16) || (p_a == 8)
    .ASSERT (p_x == 16) || (p_x == 8)
    ; widening both A and X
    .IF (p_a == 16) && (p_x == 16)
        rep #$30
    ; narrowing both A and X
    .ELIF (p_a == 8) && (p_x == 8)
        sep #$30
    .ELSE
        ; change A
        .IF p_a == 16
            rep #$20
        .ELIF p_a == 8
            sep #$20
        .ENDIF
        ; Change X
        .IF p_x == 16
            rep #$10
        .ELIF p_x == 8
            sep #$10
        .ENDIF
    .ENDIF
    .REDEFINE D_FLAG_A p_a
    .REDEFINE D_FLAG_X p_x
.ENDM

; Set the 'B' register to the given value
; Guaranteed to generate instructions to update the bank
.MACRO .ForceSetBank ARGS p_b
    ; .ASSERT (p_b >= $00) && (p_b <= $FF)
    ; Technically not the fastest method, but this guarantees A is kept
    pea p_b * $0101
    plb
    plb
    .REDEFINE D_BANK p_b
.ENDM

; Set the 'direct' register to the given value
; Guaranteed to generate instructions to update the direct page
.MACRO .ForceSetDirect ARGS p_d
    .ASSERT (p_d >= $00) && (p_d <= $FFFF)
    pea p_d
    pld
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
; Invalidate the accumulator width
.MACRO .InvalidateA
    .REDEFINE D_FLAG_A -1
.ENDM
; Invalidate the index width
.MACRO .InvalidateX
    .REDEFINE D_FLAG_X -1
.ENDM
; Invalidate the accumulator and index widths
.MACRO .InvalidateAX
    .REDEFINE D_FLAG_A -1
    .REDEFINE D_FLAG_X -1
.ENDM
; Invalidate the bank value. Use after setting the bank to an arbitrary value
.MACRO .InvalidateBank
    .REDEFINE D_BANK -1
.ENDM
; Invalidate the direct page register. Use after setting the direct page to
; an arbitrary value.
.MACRO .InvalidateDirect
    .REDEFINE D_DIRECT -1
.ENDM

; Ignore all register and flag values
; Use in procedures which don't affect the accumulator width, index width,
; data bank value, or direct page value.
.MACRO .IgnoreFlags
    .REDEFINE D_DIRECT -2
    .REDEFINE D_BANK -2
    .REDEFINE D_FLAG_A -2
    .REDEFINE D_FLAG_X -2
.ENDM
; Ignore the accumulator width
.MACRO .IgnoreA
    .REDEFINE D_FLAG_A -2
.ENDM
; Ignore the index width
.MACRO .IgnoreX
    .REDEFINE D_FLAG_X -2
.ENDM
; Ignore the accumulator and index widths
.MACRO .IgnoreAX
    .REDEFINE D_FLAG_A -2
    .REDEFINE D_FLAG_X -2
.ENDM
; Ignore the bank value.
.MACRO .IgnoreBank
    .REDEFINE D_BANK -2
.ENDM
; Ignore the direct page register.
.MACRO .IgnoreDirect
    .REDEFINE D_DIRECT -2
.ENDM

; Indicate that bank register is a parameter
.MACRO .ParameterBank
    .REDEFINE D_BANK -3
.ENDM
; Indicate that direct register is a parameter
.MACRO .ParameterDirect
    .REDEFINE D_DIRECT -3
.ENDM

; Set the 'A' flag to the given number of bits, without inserting instructions
.MACRO .SoftSetA ARGS p_a
    .ASSERT p_a == 16 || p_a == 8 || p_a == -1
    .IF p_a == 16
        .ACCU 16
    .ELIF p_a == 8
        .ACCU 8
    .ENDIF
    .REDEFINE D_FLAG_A p_a
.ENDM

; Set the 'X' flag to the given number of bits, without inserting instructions
.MACRO .SoftSetX ARGS p_x
    .ASSERT p_x == 16 || p_x == 8 || p_x == -1
    .IF p_x == 16
        .INDEX 16
    .ELIF p_x == 8
        .INDEX 8
    .ENDIF
    .REDEFINE D_FLAG_X p_x
.ENDM

; Set the 'A' and 'X' flags to the given number of bits, without inserting instructions
.MACRO .SoftSetAX ARGS p_a, p_x
    .ASSERT (p_a == 16) || (p_a == 8) || (p_a == -1)
    .ASSERT (p_x == 16) || (p_x == 8) || (p_x == -1)
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
.MACRO .SoftSetBank ARGS p_b
    .ASSERT ((p_b >= $00) && (p_b <= $FF)) || (p_b == -1) || (p_b == D_BANK_MIRROR_LOWRAM) || (p_b == D_BANK_MIRROR_IO)
    .REDEFINE D_BANK p_b
.ENDM

; Set the 'direct' register to the given value, without inserting instructions
.MACRO .SoftSetDirect ARGS p_d
    .ASSERT ((p_d >= $00) && (p_d <= $FFFF)) || (p_d == -1)
    .REDEFINE D_DIRECT p_d
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

; If set, a 'phb' instruction will be inserted.
; A later .PopContextForce will insert a plb
; A later .PopContextSoft will fail
.DEFINE PUSH_BANK 1
; If set, a 'phd' instruction will be inserted.
; A later .PopContextForce will insert a pld
; A later .PopContextSoft will fail
.DEFINE PUSH_DIRECT 2
; If set, a 'php' instruction will be inserted.
; A later .PopContextForce will insert a plp
; A later .PopContextSoft will fail
.DEFINE PUSH_FLAGS 4

; Push the current context to the context stack.
; Accepts `PUSH_*` macros as parameter flags.
; Note that the `PUSH_*` macros are a method that can be used to preserve
; ignored registers.
.MACRO .PushContext ARGS pushflags
    ; check pushflags
    .IF NARGS == 1
        .DEFINE _CONTEXT_STACK_INFO_{_CONTEXT_STACK_SIZE} pushflags
        .IF (pushflags & PUSH_BANK) != 0
            phb
        .ENDIF
        .IF (pushflags & PUSH_DIRECT) != 0
            phd
        .ENDIF
        .IF (pushflags & PUSH_FLAGS) != 0
            php
        .ENDIF
    .ELSE
        .DEFINE _CONTEXT_STACK_INFO_{_CONTEXT_STACK_SIZE} 0
    .ENDIF
    ; define stack context
    .DEFINE _CONTEXT_STACK_FLAG_A_{_CONTEXT_STACK_SIZE} D_FLAG_A
    .DEFINE _CONTEXT_STACK_FLAG_X_{_CONTEXT_STACK_SIZE} D_FLAG_X
    .DEFINE _CONTEXT_STACK_BANK_{_CONTEXT_STACK_SIZE} D_BANK
    .DEFINE _CONTEXT_STACK_DIRECT_{_CONTEXT_STACK_SIZE} D_DIRECT
    ; increment stack count
    .REDEFINE _CONTEXT_STACK_SIZE (_CONTEXT_STACK_SIZE + 1)
.ENDM

; Pop the current context without inserting any instructions
.MACRO .PopContextSoft
    .ASSERT _CONTEXT_STACK_SIZE > 0
    ; reduce stack count
    .REDEFINE _CONTEXT_STACK_SIZE (_CONTEXT_STACK_SIZE - 1)
    ; check push flags are not set
    .ASSERT _CONTEXT_STACK_INFO_{_CONTEXT_STACK_SIZE} == 0
    ; copy stack values to flags
    .REDEFINE D_FLAG_A _CONTEXT_STACK_FLAG_A_{_CONTEXT_STACK_SIZE}
    .REDEFINE D_FLAG_X _CONTEXT_STACK_FLAG_X_{_CONTEXT_STACK_SIZE}
    .REDEFINE D_BANK _CONTEXT_STACK_BANK_{_CONTEXT_STACK_SIZE}
    .REDEFINE D_DIRECT _CONTEXT_STACK_DIRECT_{_CONTEXT_STACK_SIZE}
    ; undefine context stack
    .UNDEFINE _CONTEXT_STACK_FLAG_A_{_CONTEXT_STACK_SIZE}
    .UNDEFINE _CONTEXT_STACK_FLAG_X_{_CONTEXT_STACK_SIZE}
    .UNDEFINE _CONTEXT_STACK_BANK_{_CONTEXT_STACK_SIZE}
    .UNDEFINE _CONTEXT_STACK_DIRECT_{_CONTEXT_STACK_SIZE}
    .UNDEFINE _CONTEXT_STACK_INFO_{_CONTEXT_STACK_SIZE}
.ENDM

; Pop the current context, inserting instructions to do so
.MACRO .PopContextForce
    .ASSERT _CONTEXT_STACK_SIZE > 0
    ; reduce stack count
    .REDEFINE _CONTEXT_STACK_SIZE (_CONTEXT_STACK_SIZE - 1)
    ; set bank
    .IF (_CONTEXT_STACK_INFO_{_CONTEXT_STACK_SIZE} & PUSH_BANK) != 0
        plb
        .IF (_CONTEXT_STACK_BANK_{_CONTEXT_STACK_SIZE} == D_BANK) && is_bank_specific(_CONTEXT_STACK_INFO_{_CONTEXT_STACK_SIZE})
            .PRINT "Earlier .PushContext may not need PUSH_BANK flag\n"
        .ENDIF
    .ELIF _CONTEXT_STACK_INFO_{_CONTEXT_STACK_SIZE} != D_BANK
        .IF is_bank_specific(_CONTEXT_STACK_INFO_{_CONTEXT_STACK_SIZE})
            .SetBank _CONTEXT_STACK_INFO_{_CONTEXT_STACK_SIZE}
            .PRINT "Using PUSH_BANK with earlier .PushContext may result in faster code\n"
        .ELIF (_CONTEXT_STACK_INFO_{_CONTEXT_STACK_SIZE} == D_BANK_MIRROR_IO) && !is_bank_io(D_BANK)
            .PRINT "Can not return to generic 'io' bank. Use .PushContext PUSH_BANK\n"
            .FAIL 1
        .ELIF (_CONTEXT_STACK_INFO_{_CONTEXT_STACK_SIZE} == D_BANK_MIRROR_LOWRAM) && !is_bank_lowram(D_BANK)
            .PRINT "Can not return to generic 'lowram' bank. Use .PushContext PUSH_BANK\n"
            .FAIL 1
        .ENDIF
    .ENDIF
    ; set direct page
    .IF (_CONTEXT_STACK_INFO_{_CONTEXT_STACK_SIZE} & PUSH_DIRECT) != 0
        pld
        .IF (_CONTEXT_STACK_DIRECT_{_CONTEXT_STACK_SIZE} == D_DIRECT) && (D_DIRECT >= 0)
            .PRINT "Earlier .PushContext may not need PUSH_DIRECT flag\n"
        .ENDIF
    .ELSE
        .IF _CONTEXT_STACK_DIRECT_{_CONTEXT_STACK_SIZE} >= 0
            pea _CONTEXT_STACK_DIRECT_{_CONTEXT_STACK_SIZE}
            pld
        .ENDIF
    .ENDIF
    ; set flags
    .IF (_CONTEXT_STACK_INFO_{_CONTEXT_STACK_SIZE} & PUSH_FLAGS) != 0
        plp
        .IF (_CONTEXT_STACK_FLAG_A_{_CONTEXT_STACK_SIZE} == D_FLAG_A) && _CONTEXT_STACK_FLAG_X_{_CONTEXT_STACK_SIZE} == D_FLAG_X))
            .PRINT "Earlier .PushContext may not need PUSH_FLAGS flag\n"
        .ENDIF
    .ELSE
        .IF (_CONTEXT_STACK_FLAG_A_{_CONTEXT_STACK_SIZE} >= 0) && (_CONTEXT_STACK_FLAG_X_{_CONTEXT_STACK_SIZE} >= 0)
            .SetAX _CONTEXT_STACK_FLAG_A_{_CONTEXT_STACK_SIZE}, _CONTEXT_STACK_FLAG_X_{_CONTEXT_STACK_SIZE}
        .ELIF _CONTEXT_STACK_FLAG_A_{_CONTEXT_STACK_SIZE} >= 0
            .SetA _CONTEXT_STACK_FLAG_A_{_CONTEXT_STACK_SIZE}
        .ELIF _CONTEXT_STACK_FLAG_X_{_CONTEXT_STACK_SIZE} >= 0
            .SetX _CONTEXT_STACK_FLAG_X_{_CONTEXT_STACK_SIZE}
        .ENDIF
    .ENDIF
    ; copy stack values to flags
    .REDEFINE D_FLAG_A _CONTEXT_STACK_FLAG_A_{_CONTEXT_STACK_SIZE}
    .REDEFINE D_FLAG_X _CONTEXT_STACK_FLAG_X_{_CONTEXT_STACK_SIZE}
    .REDEFINE D_BANK _CONTEXT_STACK_BANK_{_CONTEXT_STACK_SIZE}
    .REDEFINE D_DIRECT _CONTEXT_STACK_DIRECT_{_CONTEXT_STACK_SIZE}
    ; undefine context stack
    .UNDEFINE _CONTEXT_STACK_FLAG_A_{_CONTEXT_STACK_SIZE}
    .UNDEFINE _CONTEXT_STACK_FLAG_X_{_CONTEXT_STACK_SIZE}
    .UNDEFINE _CONTEXT_STACK_BANK_{_CONTEXT_STACK_SIZE}
    .UNDEFINE _CONTEXT_STACK_DIRECT_{_CONTEXT_STACK_SIZE}
    .UNDEFINE _CONTEXT_STACK_INFO_{_CONTEXT_STACK_SIZE}
.ENDM

; Define a procedure without its implementation
.MACRO .procheader ARGS name, callconvention
    .IFDEF _IN_CONTEXT_FUNC_DEF
        .FAIL ".procheader can not be used within another procedure definition"
    .ENDIF
    .IFDEF {name}_PROC_
        .PRINT "Procedure ", name, " is already defined\n"
        .FAIL
    .ELSE
    ; setup procedure temporary defines
        .DEFINE _IN_CONTEXT_FUNC_DEF callconvention
        .DEFINE _FUNC_CONTEXT_NAME name
    ; setup call convention
        .DEFINE {name}_PROC_ 1
        .DEFINE {name}_CALL_ callconvention
    ; define 'in' flags for procedure. These indicate to the callee what these
    ; flags should be set to before calling
        .DEFINE {name}_IN_FLAG_A_ D_FLAG_A
        .DEFINE {name}_IN_FLAG_X_ D_FLAG_X
        .DEFINE {name}_IN_BANK_ D_BANK
        .DEFINE {name}_IN_DIRECT_ D_DIRECT
    .ENDIF
.ENDM

.MACRO .procheaderl ARGS name
    .procheader name, PROC_CALL_LONG
.ENDM

.MACRO .procheaders ARGS name
    .procheader name, PROC_CALL_SHORT
.ENDM

; Implement a procedure that was previously defined with .procheader
.MACRO .procimpl ARGS name, callconvention
    .DEFINE _IN_CONTEXT_FUNC_IMPL
; check that procedure is defined
    .IF !defined({name}_PROC_)
        .PRINT "Procedure ", name, " is not defined\n"
        .FAIL 1
    .ENDIF
; check that calling conventions match
    .IF ({name}_CALL_ != callconvention)
        .PRINT "Mismatched calling convention for ", name, "\n"
        .FAIL
    .ENDIF
; check that in flags match
    .IF ({name}_IN_FLAG_A_ != D_FLAG_A) || ({name}_IN_FLAG_X_ != D_FLAG_X) || ({name}_IN_BANK_ != D_BANK) || ({name}_IN_DIRECT_ != D_DIRECT)
        .PRINT "Mismatched in flags for ", name, "\n"
        .FAIL
    .ENDIF
; procedure definition
    .DEFINE _FUNC_CONTEXT_NAME name
{name}:
.ENDM

.MACRO .procimpll ARGS name
    .procimpl name, PROC_CALL_LONG
.ENDM

.MACRO .procimpls ARGS name
    .procimpl name, PROC_CALL_SHORT
.ENDM

; Define a procedure with the given calling convention
; Before defining a procedure, use the `SoftSet...` macros to set up this
; procedure's context. This context will be saved to this procedure's metadata.
; When the procedure is called with `.call`, this metadata will be compared to
; the current context, and compilation will fail if there is a mismatch.
; After calling the function, the accumulator/index width, bank value, and DP
; value will be updated to match the function's output values for this state.
.MACRO .procdefine ARGS name, callconvention
    .IFDEF _IN_CONTEXT_FUNC_DEF
        .FAIL ".procdefine can not be used within another procedure definition"
    .ENDIF
    .IFDEF {name}_PROC_
        .PRINT "Procedure ", name, " is already defined; use .procimpl instead\n"
        .FAIL
    .ENDIF
    .procheader name, callconvention
    ; define function (simplified .procimpl)
    {name}:
.ENDM

; Define a procedure which can be called from any bank.
.MACRO .procdefinel ARGS name
    .procdefine name, PROC_CALL_LONG
.ENDM

; Define a procedure which is called within the same bank.
.MACRO .procdefines ARGS name
    .procdefine name, PROC_CALL_SHORT
.ENDM

; End procedure definition
.MACRO .endproc
    .IF defined(_IN_CONTEXT_FUNC_DEF)
        ; define 'out' flags for procedure.
        .DEFINE {_FUNC_CONTEXT_NAME}_OUT_FLAG_A_ D_FLAG_A
        .DEFINE {_FUNC_CONTEXT_NAME}_OUT_FLAG_X_ D_FLAG_X
        .DEFINE {_FUNC_CONTEXT_NAME}_OUT_BANK_ D_BANK
        .DEFINE {_FUNC_CONTEXT_NAME}_OUT_DIRECT_ D_DIRECT
        .UNDEFINE _IN_CONTEXT_FUNC_DEF
    .ELIF defined(_IN_CONTEXT_FUNC_IMPL)
        ; check that out flags match
        .IF ({_FUNC_CONTEXT_NAME}_OUT_FLAG_A_ != D_FLAG_A) || ({_FUNC_CONTEXT_NAME}_OUT_FLAG_X_ != D_FLAG_X) || ({_FUNC_CONTEXT_NAME}_OUT_BANK_ != D_BANK) || ({_FUNC_CONTEXT_NAME}_OUT_DIRECT_ != D_DIRECT)
            .PRINT "Mismatched out flags for ", _FUNC_CONTEXT_NAME, "\n"
            .FAIL
        .ENDIF
        .UNDEFINE _IN_CONTEXT_FUNC_IMPL
    .ELSE
        .PRINT ".endproc used without opening procedure macro"
        .FAIL 1
    .ENDIF
; check that either IN and OUT flags are both D_IGNORE, or neither
    .IF !is_valid_inout_pair({_FUNC_CONTEXT_NAME}_IN_FLAG_A_, {_FUNC_CONTEXT_NAME}_OUT_FLAG_A_)
        .PRINT "IN and OUT must both or neither be ignored (A flag)\n"
        .PRINT "in ", _FUNC_CONTEXT_NAME, "\n"
        .FAIL
    .ENDIF
    .IF !is_valid_inout_pair({_FUNC_CONTEXT_NAME}_IN_FLAG_X_, {_FUNC_CONTEXT_NAME}_OUT_FLAG_X_)
        .PRINT "IN and OUT must both or neither be ignored (X flag)\n"
        .PRINT "in ", _FUNC_CONTEXT_NAME, "\n"
        .FAIL
    .ENDIF
    .IF !is_valid_inout_pair({_FUNC_CONTEXT_NAME}_IN_BANK_, {_FUNC_CONTEXT_NAME}_OUT_BANK_)
        .PRINT "IN and OUT must both or neither be ignored (bank)\n"
        .PRINT "in ", _FUNC_CONTEXT_NAME, "\n"
        .FAIL
    .ENDIF
    .IF !is_valid_inout_pair({_FUNC_CONTEXT_NAME}_IN_DIRECT_, {_FUNC_CONTEXT_NAME}_OUT_DIRECT_)
        .PRINT "IN and OUT must both or neither be ignored (direct page)\n"
        .PRINT "in ", _FUNC_CONTEXT_NAME, "\n"
        .FAIL
    .ENDIF
; check that, if OUT flag is D_IGNORE, that value has not been set
    .IF ({_FUNC_CONTEXT_NAME}_OUT_FLAG_A_ == D_IGNORE) && (D_FLAG_A != D_IGNORE)
        .PRINT "A flag was modified in procure where it should be ignored\n"
        .PRINT "in ", _FUNC_CONTEXT_NAME, "\n"
        .FAIL
    .ENDIF
    .IF ({_FUNC_CONTEXT_NAME}_OUT_FLAG_X_ == D_IGNORE) && (D_FLAG_X != D_IGNORE)
        .PRINT "X flag was modified in procure where it should be ignored\n"
        .PRINT "in ", _FUNC_CONTEXT_NAME, "\n"
        .FAIL
    .ENDIF
    .IF ({_FUNC_CONTEXT_NAME}_OUT_BANK_ == D_IGNORE) && (D_BANK != D_IGNORE)
        .PRINT "bank was modified in procure where it should be ignored\n"
        .PRINT "in ", _FUNC_CONTEXT_NAME, "\n"
        .FAIL
    .ENDIF
    .IF ({_FUNC_CONTEXT_NAME}_OUT_DIRECT_ == D_IGNORE) && (D_DIRECT != D_IGNORE)
        .PRINT "direct page was modified in procure where it should be ignored\n"
        .PRINT "in ", _FUNC_CONTEXT_NAME, "\n"
        .FAIL
    .ENDIF
; clear flags, since presumably, we are no longer in a procedure context.
    .UNDEFINE _FUNC_CONTEXT_NAME
    .InvalidateFlags
.ENDM

; Call the given procedure
; Prints an error and fails if the context does not match before calling
.MACRO .call ARGS func
; check that context is correct for calling this function
    .IF ({func}_IN_FLAG_A_ >= 0) && (D_FLAG_A != {func}_IN_FLAG_A_)
        .PRINT "A is ", DEC D_FLAG_A, "; should be ", DEC {func}_IN_FLAG_A_, " to call ", func, "\n"
        .FAIL
    .ENDIF
    .IF ({func}_IN_FLAG_X_ >= 0) && (D_FLAG_X != {func}_IN_FLAG_X_)
        .PRINT "X is ", DEC D_FLAG_X, "; should be ", DEC {func}_IN_FLAG_X_, " to call ", func, "\n"
        .FAIL
    .ENDIF
    .IF ({func}_IN_BANK_ == D_BANK_MIRROR_LOWRAM)
        .IF !is_bank_lowram(D_BANK)
            .PRINT "DB is $", HEX D_BANK, "; should be have access to lowram to call ", func, "\n"
            .FAIL
        .ENDIF
    .ELIF ({func}_IN_BANK_ == D_BANK_MIRROR_IO)
        .IF !is_bank_io(D_BANK)
            .PRINT "DB is $", HEX D_BANK, "; should be have access to IO registers to call ", func, "\n"
            .FAIL
        .ENDIF
    .ELIF ({func}_IN_BANK_ >= 0) && (D_BANK != {func}_IN_BANK_)
        .PRINT "DB is $", HEX D_BANK, "; should be $", HEX {func}_IN_BANK_, " to call ", func, "\n"
        .FAIL
    .ENDIF
    .IF ({func}_IN_DIRECT_ >= 0) && (D_DIRECT != {func}_IN_DIRECT_)
        .PRINT "DP is $", HEX D_DIRECT, "; should be $", HEX {func}_IN_DIRECT_, " to call ", func, "\n"
        .FAIL
    .ENDIF
; call function
    .IF ({func}_CALL_ == PROC_CALL_LONG)
        jsl {func}
    .ELIF ({func}_CALL_ == PROC_CALL_SHORT)
        ; .IF bank() != bank(func)
        ;     .PRINT "Can not call ", func, " from bank $", HEX bank(), "\n"
        ;     .FAIL
        ; .ENDIF
        jsr {func}
    .ELSE
        .PRINT func, " has no valid calling convention\n"
        .FAIL
    .ENDIF
; indicate that flags and registers have been modified by the function
    .IF {func}_OUT_FLAG_A_ != -2
        .REDEFINE D_FLAG_A {func}_OUT_FLAG_A_
    .ENDIF
    .IF {func}_OUT_FLAG_X_ != -2
        .REDEFINE D_FLAG_X {func}_OUT_FLAG_X_
    .ENDIF
    .IF ({func}_OUT_BANK_ != -2) && ({func}_OUT_BANK_ != D_BANK_MIRROR_IO) && ({func}_OUT_BANK_ != D_BANK_MIRROR_LOWRAM)
        .REDEFINE D_BANK {func}_OUT_BANK_
    .ENDIF
    .IF {func}_OUT_DIRECT_ != -2
        .REDEFINE D_DIRECT {func}_OUT_DIRECT_
    .ENDIF
    .RefreshFlags
.ENDM
