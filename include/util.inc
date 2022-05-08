; test argument against A.
; if argument > A, set A to argument
; as a general rule, macros should use +++++ and -----
.MACRO AMAX
    cmp \1
    bpl +++++
    lda \1
+++++:
.ENDM

.MACRO AMIN
    cmp \1
    bmi +++++
    lda \1
+++++:
.ENDM

.MACRO AMAXI
    cmp #\1
    bpl +++++
    lda #\1
+++++:
.ENDM

.MACRO AMINI
    cmp #\1
    bmi +++++
    lda #\1
+++++:
.ENDM

.MACRO AMAXU
    cmp \1
    bcs +++++
    lda \1
+++++:
.ENDM

.MACRO AMINU
    cmp \1
    bcc +++++
    lda \1
+++++:
.ENDM

.MACRO AMAXUI
    cmp #\1
    bcs +++++
    lda #\1
+++++:
.ENDM

.MACRO AMINUI
    cmp #\1
    bcc +++++
    lda #\1
+++++:
.ENDM

.define BYTES_PER_TILE16 32

; bcs: A >= arg
; bcc: A < arg