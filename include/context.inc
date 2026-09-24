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
.DEFINE D_DIRECT $0000
; Current offset of the stack pointer
.DEFINE D_STACKOFFS 0

; Indicates that a register's value is currently unknown
; For a procedure's input, indicates that the register value is not important.
; For a procedure's output, indicates that the register value could be anything.
.DEFINE D_UNK -1
; Indicates that a register's value is not important.
; For a procedure, indicates that the register value is not important,
; will not be modified, and its value is not used.
.DEFINE D_IGNORE -2
; Indicates that a register's value is parameterized.
; For a procedure's input, indicates that the register's value is a parameter.
; For a procedure's output, indicates that the register's value is a return.
.DEFINE D_PARAMETER -3
; Special bank value: anything that has mirrored access to $0000-$1FFF; i.e.:
; banks $00-3F, $80-BF, $7E
.DEFINE D_BANK_MIRROR_LOWRAM $10000
; Special bank value: anything that has mirrored access to $0000-$7FFF
; banks $00-3F, $80-BF
.DEFINE D_BANK_MIRROR_IO $10001

; This procedure may be called from any bank
.DEFINE PROC_CALL_LONG 1
; This procedure may only be called from matching banks
.DEFINE PROC_CALL_SHORT 2

; This procedure is a fully-defined procedure
.DEFINE PROC_TYPE_PROCEDURE 1
; This procedure is an interface
.DEFINE PROC_TYPE_INTERFACE 2

; Returns true if the given bank/metabank can access IO registers in $0000-$7FFF
.FUNCTION is_bank_io(bank) (bank == D_BANK_MIRROR_IO) || ((bank >= $00) && (bank <= $3F)) || ((bank >= $80) && (bank <= $BF))
; Returns true if the given bank/metabank can access loram in $0000-$1FFF
.FUNCTION is_bank_lowram(bank) (bank == D_BANK_MIRROR_LOWRAM) || is_bank_io(bank) || (bank == $7E)
; Returns true if the given bank is specific (not a metabank)
.FUNCTION is_bank_specific(bank) (bank >= $00) && (bank <= $FF)
; Returns true if the given direct page is specific
.FUNCTION is_direct_specific(dp) (dp >= $0000) && (dp <= $FFFF)
; Returns true if the given flag value is specific
.FUNCTION is_flag_specific(flag) (flag >= 0)
; returns true if the IN and OUT values are compatible
.FUNCTION is_valid_inout_pair(inflag, outflag) ((inflag != D_IGNORE) && (outflag != D_IGNORE)) || ((inflag == D_IGNORE) && (outflag == D_IGNORE))

; Returns true if the flag 'flag' is compatible with base flags 'base'
; e.g., when inheriting an interface:
; INFLAGS: call `is_compatible_inflag(self_in_flags, interface_in_flags)`
; OUTFLAGS: call `is_compatible_outflag(self_out_flags, interface_out_flags)`
.FUNCTION is_compatible_inflag(flag, base) (base == flag) || ((base == D_UNK) && (flag == D_IGNORE)) || ((base == D_PARAMETER) && (flag == D_IGNORE)) || ((base >= 0) && (flag < 0))
.FUNCTION is_compatible_outflag(flag, base) (base == flag) || ((base == D_PARAMETER) && (flag >= 0)) || ((base == D_UNK) && ((flag == D_IGNORE) || (flag >= 0)))
.FUNCTION is_compatible_bank_inflag(flag, base) is_compatible_inflag(flag, base) || ((flag == D_BANK_MIRROR_IO) && is_bank_io(base)) || ((flag == D_BANK_MIRROR_LOWRAM) && is_bank_lowram(base))
.FUNCTION is_compatible_bank_outflag(flag, base) is_compatible_outflag(flag, base) || ((base == D_BANK_MIRROR_IO) && is_bank_io(flag)) || ((base == D_BANK_MIRROR_LOWRAM) && is_bank_lowram(flag))

.DEFINE _STACKELEM_COUNT 0

.MACRO .__STACKPUSH ARGS count, name
    .ASSERT (NARGS == 1) || (NARGS == 2)
    ; push stack offset
    .REDEFINE D_STACKOFFS (D_STACKOFFS - count)
    ; track size of this value
    .DEFINE _STACKVALUE_{_STACKELEM_COUNT}_SIZE count
    ; create define for this element's name
    .IF NARGS == 2
        .DEFINE _STACKVALUE_{_STACKELEM_COUNT}_NAME name
        ; set define for this variable's position, which is DP + 1
        ; we *also* add a huge number to this value, to ensure it can not be
        ; accidentally used directly as a stack parameter
        .DEFINE {name} (D_STACKOFFS + $10000001)
    .ENDIF
    ; increment stack element count
    .REDEFINE _STACKELEM_COUNT (_STACKELEM_COUNT + 1)
.ENDM

; Get the offset for the given named stack value
.FUNCTION stk(parameter) (parameter - $10000000) - D_STACKOFFS

.MACRO .__STACKPOP ARGS count
    ; decrement stack count
    .REDEFINE _STACKELEM_COUNT (_STACKELEM_COUNT - 1)
    ; assert that this is the correct element
    .ASSERT count == _STACKVALUE_{_STACKELEM_COUNT}_SIZE
    ; remove defines
    .UNDEFINE _STACKVALUE_{_STACKELEM_COUNT}_SIZE
    .IFDEF _STACKVALUE_{_STACKELEM_COUNT}_NAME
        .DEFINE __TEMP__ _STACKVALUE_{_STACKELEM_COUNT}_NAME
        .UNDEFINE {__TEMP__}
        .UNDEFINE __TEMP__
        .UNDEFINE _STACKVALUE_{_STACKELEM_COUNT}_NAME
    .ENDIF
    ; pop stack offset
    .REDEFINE D_STACKOFFS (D_STACKOFFS + count)
.ENDM

; Context-aware pea
.MACRO .pea ARGS value, name
    .ASSERT (NARGS == 1) || (NARGS == 2)
    pea value
    .IF NARGS == 2
        .__STACKPUSH 2, name
    .ELSE
        .__STACKPUSH 2
    .ENDIF
.ENDM

; Context-aware pei
.MACRO .pei ARGS value, name
    .ASSERT (NARGS == 1) || (NARGS == 2)
    pei (value)
    .IF NARGS == 2
        .__STACKPUSH 2, name
    .ELSE
        .__STACKPUSH 2
    .ENDIF
.ENDM

; Context-aware per
.MACRO .per ARGS value, name
    .ASSERT (NARGS == 1) || (NARGS == 2)
    per value
    .IF NARGS == 2
        .__STACKPUSH 2, name
    .ELSE
        .__STACKPUSH 2
    .ENDIF
.ENDM

; Context-aware phk
.MACRO .phk ARGS name
    .ASSERT NARGS <= 1
    phk
    .IF NARGS == 1
        .__STACKPUSH 1, name
    .ELSE
        .__STACKPUSH 1
    .ENDIF
.ENDM

; Context-aware soft push (generates no instructions)
.MACRO .PushSoft ARGS size, name
    .ASSERT NARGS <= 2
    .ASSERT size > 0
    .IF NARGS == 2
        .__STACKPUSH size, name
    .ELSE
        .__STACKPUSH size
    .ENDIF
.ENDM

; Context-aware soft pull (generates no instructions)
.MACRO .PullSoft ARGS size
    .ASSERT NARGS == 1
    .ASSERT size > 0
    .__STACKPOP size
.ENDM

; Context-aware pha
.MACRO .pha ARGS name
    .ASSERT NARGS <= 1
    .ASSERT (D_FLAG_A == 8) || (D_FLAG_A == 16)
    pha
    .IF NARGS == 1
        .__STACKPUSH (D_FLAG_A / 8), name
    .ELSE
        .__STACKPUSH (D_FLAG_A / 8)
    .ENDIF
.ENDM

; Context-aware pla
.MACRO .pla
    .ASSERT (D_FLAG_A == 8) || (D_FLAG_A == 16)
    pla
    .__STACKPOP (D_FLAG_A / 8)
.ENDM

; Context-aware phx
.MACRO .phx ARGS name
    .ASSERT NARGS <= 1
    .ASSERT (D_FLAG_X == 8) || (D_FLAG_X == 16)
    phx
    .IF NARGS == 1
        .__STACKPUSH (D_FLAG_X / 8), name
    .ELSE
        .__STACKPUSH (D_FLAG_X / 8)
    .ENDIF
.ENDM

; Context-aware plx
.MACRO .plx
    .ASSERT (D_FLAG_X == 8) || (D_FLAG_X == 16)
    plx
    .__STACKPOP (D_FLAG_X / 8)
.ENDM

; Context-aware phy
.MACRO .phy ARGS name
    .ASSERT NARGS <= 1
    .ASSERT (D_FLAG_X == 8) || (D_FLAG_X == 16)
    phy
    .IF NARGS == 1
        .__STACKPUSH (D_FLAG_X / 8), name
    .ELSE
        .__STACKPUSH (D_FLAG_X / 8)
    .ENDIF
.ENDM

; Context-aware ply
.MACRO .ply
    .ASSERT (D_FLAG_X == 8) || (D_FLAG_X == 16)
    ply
    .__STACKPOP (D_FLAG_X / 8)
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

; Set the 'A' flag to the given number of bits
.MACRO .SetA ARGS p_a
    .ASSERT (p_a == 16) || (p_a == 8)
    .IF (p_a != D_FLAG_A) && (p_a == 16)
        rep #$20
    .ELIF (p_a != D_FLAG_A) && (p_a == 8)
        sep #$20
    .ENDIF
    .REDEFINE D_FLAG_A p_a
    .RefreshFlags
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
    .RefreshFlags
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
    .RefreshFlags
.ENDM

; Set the bank via `pea : plb : plb`.
; Not the fastest, but guarantees registers aren't clobbered.
; This is the default.
.DEFINE SETBANKMODE_PEA 0
; Set the bank via `lda : pha : plb`.
; Faster, but clobbers A register, A must be in 8-bit mode.
.DEFINE SETBANKMODE_A 1
; Set the bank via `ldx : phx : plb`.
; Faster, but clobbers X register, X must be in 8-bit mode.
.DEFINE SETBANKMODE_X 2
; Set the bank via `ldy : phy : plb`.
; Faster, but clobbers Y register, X must be in 8-bit mode.
.DEFINE SETBANKMODE_Y 3

.MACRO .__SET_BANK ARGS p_b, mode
    .IF NARGS == 1
        pea p_b * $0101
        plb
        plb
    .ELIF mode == SETBANKMODE_PEA
        pea p_b * $0101
        plb
        plb
    .ELIF mode == SETBANKMODE_A
        .ASSERT D_FLAG_A == 8
        lda #p_b
        pha
        plb
    .ELIF mode == SETBANKMODE_X
        .ASSERT D_FLAG_X == 8
        ldx #p_b
        phx
        plb
    .ELIF mode == SETBANKMODE_Y
        .ASSERT D_FLAG_X == 8
        ldy #p_b
        phy
        plb
    .ELSE
        .FAIL
    .ENDIF
.ENDM

; Set the 'B' register to the given value
.MACRO .SetBank ARGS p_b, mode
    .ASSERT ((p_b >= $00) && (p_b <= $FF))
    .IF NARGS == 1
        .__SET_BANK p_b
    .ELSE
        .__SET_BANK p_b, mode
    .ENDIF
    .REDEFINE D_BANK p_b
.ENDM

; Set the 'direct' register to the given value
.MACRO .SetDirect ARGS p_d
    .ASSERT ((p_d >= $00) && (p_d <= $FFFF))
    .IF (p_d != D_DIRECT) && (p_d != D_UNK)
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
    .RefreshFlags
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
    .RefreshFlags
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
    .RefreshFlags
.ENDM

; Set the 'B' register to the given value
; Guaranteed to generate instructions to update the bank
.MACRO .ForceSetBank ARGS p_b
    ; .ASSERT (p_b >= $00) && (p_b <= $FF)
    .IF NARGS == 1
        .__SET_BANK p_b
    .ELSE
        .__SET_BANK p_b, mode
    .ENDIF
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
.MACRO .InvalidateContext
    .REDEFINE D_DIRECT D_UNK
    .REDEFINE D_BANK D_UNK
    .REDEFINE D_FLAG_A D_UNK
    .REDEFINE D_FLAG_X D_UNK
    .RefreshFlags
.ENDM

; Reset register and flag values to their defaults.
; i.e., direct page is $0000, and the rest are unknown.
.MACRO .ClearContext
    .REDEFINE D_DIRECT $0000
    .REDEFINE D_BANK D_UNK
    .REDEFINE D_FLAG_A D_UNK
    .REDEFINE D_FLAG_X D_UNK
    .RefreshFlags
.ENDM

; Invalidate the accumulator width
.MACRO .InvalidateA
    .REDEFINE D_FLAG_A D_UNK
    .RefreshFlags
.ENDM
; Invalidate the index width
.MACRO .InvalidateX
    .REDEFINE D_FLAG_X D_UNK
    .RefreshFlags
.ENDM
; Invalidate the accumulator and index widths
.MACRO .InvalidateAX
    .REDEFINE D_FLAG_A D_UNK
    .REDEFINE D_FLAG_X D_UNK
    .RefreshFlags
.ENDM
; Invalidate the bank value. Use after setting the bank to an arbitrary value
.MACRO .InvalidateBank
    .REDEFINE D_BANK D_UNK
.ENDM
; Invalidate the direct page register. Use after setting the direct page to
; an arbitrary value.
.MACRO .InvalidateDirect
    .REDEFINE D_DIRECT D_UNK
.ENDM

; Ignore all register and flag values
; Use in procedures which don't affect the accumulator width, index width,
; data bank value, or direct page value.
.MACRO .IgnoreContext
    .REDEFINE D_DIRECT D_IGNORE
    .REDEFINE D_BANK D_IGNORE
    .REDEFINE D_FLAG_A D_IGNORE
    .REDEFINE D_FLAG_X D_IGNORE
    .RefreshFlags
.ENDM
; Ignore the accumulator width
.MACRO .IgnoreA
    .REDEFINE D_FLAG_A D_IGNORE
    .RefreshFlags
.ENDM
; Ignore the index width
.MACRO .IgnoreX
    .REDEFINE D_FLAG_X D_IGNORE
    .RefreshFlags
.ENDM
; Ignore the accumulator and index widths
.MACRO .IgnoreAX
    .REDEFINE D_FLAG_A D_IGNORE
    .REDEFINE D_FLAG_X D_IGNORE
    .RefreshFlags
.ENDM
; Ignore the bank value.
.MACRO .IgnoreBank
    .REDEFINE D_BANK D_IGNORE
.ENDM
; Ignore the direct page register.
.MACRO .IgnoreDirect
    .REDEFINE D_DIRECT D_IGNORE
.ENDM

; Indicate that bank register is a parameter
.MACRO .ParameterBank
    .REDEFINE D_BANK D_PARAMETER
.ENDM
; Indicate that direct register is a parameter
.MACRO .ParameterDirect
    .REDEFINE D_DIRECT D_PARAMETER
.ENDM

; Set the 'A' flag to the given number of bits, without inserting instructions
.MACRO .SoftSetA ARGS p_a
    .ASSERT (p_a == 16) || (p_a == 8) || (p_a == D_UNK)
    .REDEFINE D_FLAG_A p_a
    .RefreshFlags
.ENDM

; Set the 'X' flag to the given number of bits, without inserting instructions
.MACRO .SoftSetX ARGS p_x
    .ASSERT (p_x == 16) || (p_x == 8) || (p_x == D_UNK)
    .REDEFINE D_FLAG_X p_x
    .RefreshFlags
.ENDM

; Set the 'A' and 'X' flags to the given number of bits, without inserting instructions
.MACRO .SoftSetAX ARGS p_a, p_x
    .ASSERT (p_a == 16) || (p_a == 8) || (p_a == D_UNK)
    .ASSERT (p_x == 16) || (p_x == 8) || (p_x == D_UNK)
    .REDEFINE D_FLAG_A p_a
    .REDEFINE D_FLAG_X p_x
    .RefreshFlags
.ENDM

; Set the 'B' register to the given value, without inserting instructions
.MACRO .SoftSetBank ARGS p_b
    .ASSERT ((p_b >= $00) && (p_b <= $FF)) || (p_b == D_UNK) || (p_b == D_BANK_MIRROR_LOWRAM) || (p_b == D_BANK_MIRROR_IO)
    .REDEFINE D_BANK p_b
.ENDM

; Set the 'direct' register to the given value, without inserting instructions
.MACRO .SoftSetDirect ARGS p_d
    .ASSERT ((p_d >= $00) && (p_d <= $FFFF)) || (p_d == D_UNK)
    .REDEFINE D_DIRECT p_d
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

.DEFINE _CONTEXT_STACK_SIZE 0

; Push the current context to the context stack.
; Accepts `PUSH_*` macros as parameter flags.
; Note that the `PUSH_*` macros are a method that can be used to preserve
; ignored registers.
.MACRO .PushContext ARGS pushflags
    ; check pushflags
    .IF NARGS == 1
        .DEFINE _CONTEXT_STACK_INFO_{_CONTEXT_STACK_SIZE} pushflags
        .IF (pushflags & PUSH_BANK) != 0
            .__STACKPUSH 1
            phb
        .ENDIF
        .IF (pushflags & PUSH_DIRECT) != 0
            .__STACKPUSH 1
            phd
        .ENDIF
        .IF (pushflags & PUSH_FLAGS) != 0
            .__STACKPUSH 1
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
    .RefreshFlags
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
        .__STACKPOP 1
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
        .__STACKPOP 1
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
        .__STACKPOP 1
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
    .RefreshFlags
    ; undefine context stack
    .UNDEFINE _CONTEXT_STACK_FLAG_A_{_CONTEXT_STACK_SIZE}
    .UNDEFINE _CONTEXT_STACK_FLAG_X_{_CONTEXT_STACK_SIZE}
    .UNDEFINE _CONTEXT_STACK_BANK_{_CONTEXT_STACK_SIZE}
    .UNDEFINE _CONTEXT_STACK_DIRECT_{_CONTEXT_STACK_SIZE}
    .UNDEFINE _CONTEXT_STACK_INFO_{_CONTEXT_STACK_SIZE}
.ENDM

.DEFINE _CBANK_STACK_SIZE 0
; Context-aware bank push
.MACRO .PushBank
    .__STACKPUSH 1
    phb
    .DEFINE _CBANK_VALUE_{_CBANK_STACK_SIZE} D_BANK
    .REDEFINE _CBANK_STACK_SIZE (_CBANK_STACK_SIZE + 1)
.ENDM

; Context-aware bank pop
.MACRO .PopBank
    .ASSERT _CBANK_STACK_SIZE > 0
    .REDEFINE _CBANK_STACK_SIZE (_CBANK_STACK_SIZE - 1)
    .REDEFINE D_BANK _CBANK_VALUE_{_CBANK_STACK_SIZE}
    .UNDEFINE _CBANK_VALUE_{_CBANK_STACK_SIZE}
    plb
    .__STACKPOP 1
.ENDM

.DEFINE _CDIRECT_STACK_SIZE 0
; Context aware DP push
.MACRO .PushDirect
    .__STACKPUSH 1
    phd
    .DEFINE _CDIRECT_VALUE_{_CDIRECT_STACK_SIZE} D_DIRECT
    .REDEFINE _CDIRECT_STACK_SIZE (_CDIRECT_STACK_SIZE + 1)
.ENDM

; Context aware DP pop
.MACRO .PopDirect
    .ASSERT _CDIRECT_STACK_SIZE > 0
    .REDEFINE _CDIRECT_STACK_SIZE (_CDIRECT_STACK_SIZE - 1)
    .REDEFINE D_DIRECT _CDIRECT_VALUE_{_CDIRECT_STACK_SIZE}
    .UNDEFINE _CDIRECT_VALUE_{_CDIRECT_STACK_SIZE}
    pld
    .__STACKPOP 1
.ENDM

.DEFINE _CFLAGS_STACK_SIZE 0
; Context aware flag push
.MACRO .PushP
    .__STACKPUSH 1
    php
    .DEFINE _CFLAGS_VALUE_A_{_CFLAGS_STACK_SIZE} D_FLAG_A
    .DEFINE _CFLAGS_VALUE_X_{_CFLAGS_STACK_SIZE} D_FLAG_X
    .REDEFINE _CFLAGS_STACK_SIZE (_CFLAGS_STACK_SIZE + 1)
.ENDM

; Context aware flag pop
.MACRO .PopP
    .ASSERT _CFLAGS_STACK_SIZE > 0
    .REDEFINE _CFLAGS_STACK_SIZE (_CFLAGS_STACK_SIZE - 1)
    .REDEFINE D_FLAG_A _CFLAGS_VALUE_A_{_CFLAGS_STACK_SIZE}
    .REDEFINE D_FLAG_X _CFLAGS_VALUE_X_{_CFLAGS_STACK_SIZE}
    .UNDEFINE _CFLAGS_VALUE_A_{_CFLAGS_STACK_SIZE}
    .UNDEFINE _CFLAGS_VALUE_X_{_CFLAGS_STACK_SIZE}
    plp
    .__STACKPOP 1
    .RefreshFlags
.ENDM

; Define a procedure without its implementation.
; This is useful for declaring procedures in header files, so they can
; be accessed from other assemblies.
.MACRO .procheader ARGS name, callconvention, interface
    .IFDEF _IN_CONTEXT_FUNC_DEF
        .FAIL ".procheader can not be used within another procedure definition"
    .ENDIF
    .IFDEF {name}_PROC_
        .PRINT "Procedure ", name, " is already defined\n"
        .FAIL
    .ELSE
    ; setup procedure temporary defines
        .DEFINE _IN_CONTEXT_FUNC_DEF 1
        .DEFINE _FUNC_CONTEXT_NAME name
    ; setup call convention
        .DEFINE {name}_PROC_ PROC_TYPE_PROCEDURE
        .DEFINE {name}_CALL_ callconvention
        .DEFINE {name}_LABEL_ name
    ; define 'in' flags for procedure. These indicate to the callee what these
    ; flags should be set to before calling
        .DEFINE {name}_IN_FLAG_A_ D_FLAG_A
        .DEFINE {name}_IN_FLAG_X_ D_FLAG_X
        .DEFINE {name}_IN_BANK_ D_BANK
        .DEFINE {name}_IN_DIRECT_ D_DIRECT
    ; setup and check interface
        .IF NARGS >= 3
            .DEFINE {name}_INTERFACE_ interface
            .IF {name}_CALL_ != {interface}_CALL_
                .PRINT "Procedure CALL CONVENTION ", name, " does not match interface ", interface, "\n"
                .FAIL
            .ENDIF
            .IF !is_compatible_inflag({name}_IN_FLAG_A_, {interface}_IN_FLAG_A_)
                .PRINT "Procedure IN FLAG A ", name, " does not match interface ", interface, "\n"
                .FAIL
            .ENDIF
            .IF !is_compatible_inflag({name}_IN_FLAG_X_, {interface}_IN_FLAG_X_)
                .PRINT "Procedure IN FLAG X ", name, " does not match interface ", interface, "\n"
                .FAIL
            .ENDIF
            .IF !is_compatible_bank_inflag({name}_IN_BANK_, {interface}_IN_BANK_)
                .PRINT "Procedure IN BANK ", name, " does not match interface ", interface, "\n"
                .FAIL
            .ENDIF
            .IF !is_compatible_inflag({name}_IN_DIRECT_, {interface}_IN_DIRECT_)
                .PRINT "Procedure IN DIRECT ", name, " does not match interface ", interface, "\n"
                .FAIL
            .ENDIF
        .ENDIF
    .ENDIF
.ENDM

.MACRO .procheaderl ARGS name, interface
    .IF NARGS >= 2
        .procheader name, PROC_CALL_LONG, interface
    .ELSE
        .procheader name, PROC_CALL_LONG
    .ENDIF
.ENDM

.MACRO .procheaders ARGS name, interface
    .IF NARGS >= 2
        .procheader name, PROC_CALL_SHORT, interface
    .ELSE
        .procheader name, PROC_CALL_SHORT
    .ENDIF
.ENDM

; Define a procedure interface. These can not have an implementation.
; This is useful for declaring a calling convention that other procedures must
; implement, e.g. for dynamic dispatch.
; Implementing procedures must only be compatible with the interface.
.MACRO .procinterface ARGS name, callconvention
    .IFDEF _IN_CONTEXT_FUNC_DEF
        .FAIL ".procheader can not be used within another procedure definition"
    .ENDIF
    .IFDEF {name}_PROC_
        .PRINT "Procedure ", name, " is already defined\n"
        .FAIL
    .ELSE
    ; setup procedure temporary defines
        .DEFINE _IN_CONTEXT_FUNC_DEF 1
        .DEFINE _FUNC_CONTEXT_NAME name
    ; setup call convention
        .DEFINE {name}_PROC_ PROC_TYPE_INTERFACE
        .DEFINE {name}_CALL_ callconvention
    ; define 'in' flags for procedure. These indicate to the callee what these
    ; flags should be set to before calling
        .DEFINE {name}_IN_FLAG_A_ D_FLAG_A
        .DEFINE {name}_IN_FLAG_X_ D_FLAG_X
        .DEFINE {name}_IN_BANK_ D_BANK
        .DEFINE {name}_IN_DIRECT_ D_DIRECT
    .ENDIF
.ENDM

.MACRO .procinterfacel ARGS name
    .procinterface name, PROC_CALL_LONG
.ENDM

.MACRO .procinterfaces ARGS name
    .procinterface name, PROC_CALL_SHORT
.ENDM

.MACRO .__begin_proc_impl ARGS name
    .DEFINE _IN_CONTEXT_FUNC_IMPL
    .DEFINE _PARAM_COUNT 0
    .IF {name}_CALL_ == PROC_CALL_SHORT
        .DEFINE _PARAM_OFFSET 2
    .ELIF {name}_CALL_ == PROC_CALL_LONG
        .DEFINE _PARAM_OFFSET 3
    .ENDIF
    .ASSERT D_STACKOFFS == 0
{name}:
.ENDM

.MACRO .__pushprocparams ARGS size, index
    .IF index < _PARAM_COUNT
        .__pushprocparams size, (index + 1)
        .DEFINE __TEMP__ _PARAM_{index}_NAME
        .REDEFINE {__TEMP__} ( {__TEMP__} + size )
        .UNDEFINE __TEMP__
    .ENDIF
.ENDM

; Define a stack parameter for this procedure, with the given name and size (in bytes).
; This will create a define with the given name to use with `stk`.
; Parameters should be defined in push-order; that is, the order in which
; parameters should be pushed to the stack.
.MACRO .procparam ARGS name, size
    ; check that we are in a function implementation
    .ASSERT defined(_IN_CONTEXT_FUNC_IMPL)
    ; create define for this parameter
    .DEFINE {name} (_PARAM_OFFSET + $10000001)
    .DEFINE _PARAM_{_PARAM_COUNT}_NAME name
    ; push other parameters back
    .__pushprocparams size, 0
    ; increment parameter count
    .REDEFINE _PARAM_COUNT (_PARAM_COUNT + 1)
.ENDM

; Implement a procedure that was previously defined with .procheader
; Only one implementation may exist for any procedure.
.MACRO .procimpl ARGS name, callconvention
    .DEFINE _FUNC_CONTEXT_NAME name
; check that procedure is defined
    .IF !defined({name}_PROC_)
        .PRINT "Procedure ", name, " is not defined\n"
        .FAIL 1
    .ENDIF
; check that procedure is not an interface
    .IF {name}_PROC_ == PROC_TYPE_INTERFACE
        .PRINT "Can not implement procedure for interface ", name, "\n"
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
    .__begin_proc_impl name
.ENDM

.MACRO .procimpll ARGS name
    .procimpl name, PROC_CALL_LONG, interface
.ENDM

.MACRO .procimpls ARGS name
    .procimpl name, PROC_CALL_SHORT, interface
.ENDM

; Define a procedure with the given calling convention
; Before defining a procedure, use the `SoftSet...` macros to set up this
; procedure's context. This context will be saved to this procedure's metadata.
; When the procedure is called with `.call`, this metadata will be compared to
; the current context, and compilation will fail if there is a mismatch.
; After calling the function, the accumulator/index width, bank value, and DP
; value will be updated to match the function's output values for this state.
.MACRO .procdefine ARGS name, callconvention, interface
    .IFDEF _IN_CONTEXT_FUNC_DEF
        .FAIL ".procdefine can not be used within another procedure definition"
    .ENDIF
    .IFDEF {name}_PROC_
        .PRINT "Procedure ", name, " is already defined; use .procimpl instead\n"
        .FAIL
    .ENDIF
    ; setup procedure header
    .IF NARGS >= 3
        .procheader name, callconvention, interface
    .ELSE
        .procheader name, callconvention
    .ENDIF
    ; define function (simplified .procimpl)
    .__begin_proc_impl name
.ENDM

; Define a procedure which can be called from any bank.
.MACRO .procdefinel ARGS name, interface
    .IF NARGS >= 2
        .procdefine name, PROC_CALL_LONG, interface
    .ELSE
        .procdefine name, PROC_CALL_LONG
    .ENDIF
.ENDM

; Define a procedure which is called within the same bank.
.MACRO .procdefines ARGS name, interface
    .IF NARGS >= 2
        .procdefine name, PROC_CALL_SHORT, interface
    .ELSE
        .procdefine name, PROC_CALL_SHORT
    .ENDIF
.ENDM

.MACRO .__undef_param
    .IF _PARAM_COUNT > 0
        .REDEFINE _PARAM_COUNT (_PARAM_COUNT - 1)
        .DEFINE __TEMP__ _PARAM_{_PARAM_COUNT}_NAME
        .UNDEFINE {__TEMP__}
        .UNDEFINE __TEMP__
        .UNDEFINE _PARAM_{_PARAM_COUNT}_NAME
        .__undef_param
    .ENDIF
.ENDM

; End procedure definition
.MACRO .endproc
    .ASSERT D_STACKOFFS == 0
    .IF !defined(_IN_CONTEXT_FUNC_DEF) && !defined(_IN_CONTEXT_FUNC_IMPL)
        .PRINT ".endproc used without opening procedure macro\n"
        .FAIL 1
    .ENDIF
    .IF defined(_IN_CONTEXT_FUNC_DEF)
        ; define 'out' flags for procedure.
        .DEFINE {_FUNC_CONTEXT_NAME}_OUT_FLAG_A_ D_FLAG_A
        .DEFINE {_FUNC_CONTEXT_NAME}_OUT_FLAG_X_ D_FLAG_X
        .DEFINE {_FUNC_CONTEXT_NAME}_OUT_BANK_ D_BANK
        .DEFINE {_FUNC_CONTEXT_NAME}_OUT_DIRECT_ D_DIRECT
        .UNDEFINE _IN_CONTEXT_FUNC_DEF
    .ENDIF
    .IF defined(_IN_CONTEXT_FUNC_IMPL)
        ; check that out flags match
        .IF ({_FUNC_CONTEXT_NAME}_OUT_FLAG_A_ != D_FLAG_A) || ({_FUNC_CONTEXT_NAME}_OUT_FLAG_X_ != D_FLAG_X) || ({_FUNC_CONTEXT_NAME}_OUT_BANK_ != D_BANK) || ({_FUNC_CONTEXT_NAME}_OUT_DIRECT_ != D_DIRECT)
            .PRINT "Mismatched out flags for ", _FUNC_CONTEXT_NAME, "\n"
            .FAIL
        .ENDIF
        .__undef_param
        .UNDEFINE _IN_CONTEXT_FUNC_IMPL
        .UNDEFINE _PARAM_COUNT
        .UNDEFINE _PARAM_OFFSET
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
; if this implements an interface, check that we match interface
    .IFDEF {_FUNC_CONTEXT_NAME}_INTERFACE_
        .DEFINE _interface_ {_FUNC_CONTEXT_NAME}_INTERFACE_
        .IF !is_compatible_outflag({_FUNC_CONTEXT_NAME}_OUT_FLAG_A_, {_interface_}_OUT_FLAG_A_)
            .PRINT "Procedure OUT FLAG A ", _FUNC_CONTEXT_NAME, " does not match interface ", _interface_, "\n"
            .FAIL
        .ENDIF
        .IF !is_compatible_outflag({_FUNC_CONTEXT_NAME}_OUT_FLAG_X_, {_interface_}_OUT_FLAG_X_)
            .PRINT "Procedure OUT FLAG X ", _FUNC_CONTEXT_NAME, " does not match interface ", _interface_, "\n"
            .FAIL
        .ENDIF
        .IF !is_compatible_bank_outflag({_FUNC_CONTEXT_NAME}_OUT_BANK_, {_interface_}_OUT_BANK_)
            .PRINT "Procedure OUT BANK ", _FUNC_CONTEXT_NAME, " does not match interface ", _interface_, "\n"
            .FAIL
        .ENDIF
        .IF !is_compatible_outflag({_FUNC_CONTEXT_NAME}_OUT_DIRECT_, {_interface_}_OUT_DIRECT_)
            .PRINT "Procedure OUT DIRECT ", _FUNC_CONTEXT_NAME, " does not match interface ", _interface_, "\n"
            .FAIL
        .ENDIF
        .UNDEFINE _interface_
    .ENDIF
; clear flags, since presumably, we are no longer in a procedure context.
    .UNDEFINE _FUNC_CONTEXT_NAME
    .ClearContext
.ENDM

.DEFINE SETUP_FLAG_A $01
.DEFINE SETUP_FLAG_X $02
.DEFINE SETUP_FLAGS $03
.DEFINE SETUP_BANK $04
.DEFINE SETUP_DIRECT $08

; set up for calling the function 'func'
; this may update AX flags, bank, and direct page registers,
; depending on passed flags.
.MACRO .callsetup ARGS func, setupflags
    .IFNDEF {func}_PROC_
        .PRINT "No such procedure ", func, "\n"
        .FAIL
    .ENDIF
    .IF (setupflags & SETUP_FLAGS) == SETUP_FLAGS
        .SetAX {func}_IN_FLAG_A_, {func}_IN_FLAG_X_
    .ELSE
        .IF (setupflags & SETUP_FLAG_A) != 0
            .SetA {func}_IN_FLAG_A_
        .ENDIF
        .IF (setupflags & SETUP_FLAG_X) != 0
            .SetX {func}_IN_FLAG_X_
        .ENDIF
    .ENDIF
    .IF (setupflags & SETUP_BANK) != 0
        .SetBank {func}_IN_BANK_
    .ENDIF
    .IF (setupflags & SETUP_DIRECT) != 0
        .SetDirect {func}_IN_DIRECT_
    .ENDIF
.ENDM

.MACRO .setupcall_in ARGS func
    .IFNDEF {func}_PROC_
        .PRINT "No such procedure ", func, "\n"
        .FAIL
    .ENDIF
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
.ENDM

.MACRO .setupcall_out ARGS func
; indicate that flags and registers have been modified by the function
    .IF {func}_OUT_FLAG_A_ != D_IGNORE
        .REDEFINE D_FLAG_A {func}_OUT_FLAG_A_
    .ENDIF
    .IF {func}_OUT_FLAG_X_ != D_IGNORE
        .REDEFINE D_FLAG_X {func}_OUT_FLAG_X_
    .ENDIF
    .IF ({func}_OUT_BANK_ != D_IGNORE) && ({func}_OUT_BANK_ != D_BANK_MIRROR_IO) && ({func}_OUT_BANK_ != D_BANK_MIRROR_LOWRAM)
        .REDEFINE D_BANK {func}_OUT_BANK_
    .ENDIF
    .IF {func}_OUT_DIRECT_ != D_IGNORE
        .REDEFINE D_DIRECT {func}_OUT_DIRECT_
    .ENDIF
    .RefreshFlags
.ENDM

; Call the given procedure
; Prints an error and fails if the context does not match before calling
.MACRO .call ARGS func
    .setupcall_in func
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
    .setupcall_out func
.ENDM

; Jump to the given procedure
; Prints an error and fails if the context does not match before calling
.MACRO .tailcall ARGS func
    .setupcall_in func
    .IF ({func}_CALL_ == PROC_CALL_LONG)
        jml {func}
    .ELIF ({func}_CALL_ == PROC_CALL_SHORT)
        ; .IF bank() != bank(func)
        ;     .PRINT "Can not call ", func, " from bank $", HEX bank(), "\n"
        ;     .FAIL
        ; .ENDIF
        jmp {func}
    .ELSE
        .PRINT func, " has no valid calling convention\n"
        .FAIL
    .ENDIF
    .setupcall_out func
.ENDM