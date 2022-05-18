; test argument against A.
; if argument > A, set A to argument
; as a general rule, macro labels should begin with @@@@@
; that way, these labels don't mess with those in code
.MACRO AMAX
    cmp \1
    bpl @@@@@\.\@
    lda \1
@@@@@\.\@:
.ENDM

.MACRO AMIN
    cmp \1
    bmi @@@@@\.\@
    lda \1
@@@@@\.\@:
.ENDM

.MACRO AMAXI
    cmp #\1
    bpl @@@@@\.\@
    lda #\1
@@@@@\.\@:
.ENDM

.MACRO AMINI
    cmp #\1
    bmi @@@@@\.\@
    lda #\1
@@@@@\.\@:
.ENDM

.MACRO AMAXU
    cmp \1
    bcs @@@@@\.\@
    lda \1
@@@@@\.\@:
.ENDM

.MACRO AMINU
    cmp \1
    bcc @@@@@\.\@
    lda \1
@@@@@\.\@:
.ENDM

.MACRO AMAXUI
    cmp #\1
    bcs @@@@@\.\@
    lda #\1
@@@@@\.\@:
.ENDM

.MACRO AMINUI
    cmp #\1
    bcc @@@@@\.\@
    lda #\1
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
    PHB
    LDA.B #bank
    STA.B $01,s
    PLB
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

; bcs: A >= arg
; bcc: A < arg