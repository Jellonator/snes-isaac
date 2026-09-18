.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "Main"

ReadInput:
    ; loop until controller allows itself to be read
    .ForceSetA 16
@read_input_loop:
    lda HVBJOY
    and #$01
    bne @read_input_loop ;0.14% -> 1.2%
    ; Read input
    .ForceSetAX 16, 16
    ldx.w joy1raw
    lda $4218
    sta.w joy1raw
    txa
    eor.w joy1raw
    and.w joy1raw
    sta.w joy1press
    txa
    and.w joy1raw
    sta.w joy1held
    ; Not worried about controller validity for now
    .ForceSetAX 8, 8
    rts

; Clear a section of WRAM
; push order:
;   wram address [dw] $07
;   wram bank    [db] $06
;   num bytes    [dw] $04
; MUST call with jsl
ClearWRam:
    .ForceSetA 16
    lda $04,s
    sta DMA0_SIZE
    lda #loword(EmptyData)
    sta DMA0_SRCL
    lda $07,s
    sta WMADDL
    .ForceSetA 8
    lda #bankbyte(EmptyData)
    sta DMA0_SRCH
    lda $06,s
    sta WMADDH
    ; Absolute address, no increment, 1 byte at a time
    lda #%00001000
    sta DMA0_CTL
    ; Write to WRAM
    lda #$80
    sta DMA0_DEST
    lda #$01
    sta MDMAEN
    rtl

.ENDS
