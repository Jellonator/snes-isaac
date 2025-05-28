.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "Player" FREE

; Decompress LZ4 data from ROM to RAM
; X: source addr [16b]
; Y:   dest addr [16b]
; A  low byte: source bank [8b]
; A high byte:   dest bank [8b]
; Note that a custom Lz4 format is used. The differences are:
; * The header is only two bytes, and indicates the number of blocks.
Decompress.Lz4FromROM:
    .INDEX 16
    .DEFINE NUM_BLOCKS $30
    .DEFINE LEN_LITERAL $32
    .DEFINE LEN_MATCH $34
    .DEFINE DEST_ADDR $36
    .DEFINE DEST_OFFSET $38
; backup bank
    phb
; initialize registers
    sep #$20
    pha
    plb ; B = source bank
    sta.l DMA0_SRCH ; SRCH = source bank
    xba
    sta.l WMADDH ; WMADDH = dest bank
    sta.l tempWritableCode+1 ; mvn source bank is dest (this is for dest -> dest copy)
    sta.l tempWritableCode+2 ; mvn dest bank is dest
    lda #$54 ; mvn src,dest
    sta.l tempWritableCode+0
    lda #$5C ; jmp long
    sta.l tempWritableCode+3
    lda #bankbyte(Decompress.Lz4FromROM@match_copy_end)
    sta.l tempWritableCode+6
    ; continue setting registers
    rep #$30
    tya
    sta.l WMADDL ; WMADDL = dest addr
    sta.b DEST_ADDR ; since reading WMADDL is open bus, we need to track it separately
    lda #$8000 ; auto increment, 1B at a time, dest=WM
    sta.l DMA0_CTL
    lda #loword(Decompress.Lz4FromROM@match_copy_end)
    sta.l tempWritableCode+4
; Read header
    lda.w $0000,X ; first two bytes are the number of blocks
    sta.b NUM_BLOCKS
    inx
    inx
; Begin reading blocks
@read_token:
    ; get length of match block
    lda.w $0000,X
    and #$000F
    clc
    adc #4
    sta.b LEN_MATCH
    ; get length of literal block
    lda.w $0000,X
    and #$00F0
    inx
    .ShiftRight 4
    ; if literal block == $0, skip literal block
    beq @skip_write_literal
    sta.b LEN_LITERAL
    ; if literal block == $F, read bytes of literal length until they are not $FF
    cmp #$000F
    bne @end_read_literal_len
    @loop_read_literal_len:
        ; len += *x
        lda.w $0000,X
        and #$00FF
        tay
        clc
        adc.b LEN_LITERAL
        sta.b LEN_LITERAL
        ; ++x
        inx
        ; loop
        cpy #$00FF
        beq @loop_read_literal_len
    @end_read_literal_len:
    ; write literal block
    sta.l DMA0_SIZE
    clc ; interlude: increment DEST_ADDR
    adc.b DEST_ADDR
    sta.b DEST_ADDR
    txa
    sta.l DMA0_SRCL
    lda #$0100
    sta.l MDMAEN-1
    ; increment source pointer
    txa
    clc
    adc.b LEN_LITERAL
    tax
@skip_write_literal:
    ; decrement blocks. If this is the last block (--NUM_BLOCKS == 0), then exit
    dec.b NUM_BLOCKS
    beq @end
    ; get match offset (source address). Note that index is 'current position - offset'
    lda.b DEST_ADDR
    sec
    sbc.w $0000,X
    sta.b DEST_OFFSET
    inx
    inx
    ; determine full length of match block
    lda.b LEN_MATCH
    cmp #$000F+4
    bne @end_read_match_len
    @loop_read_match_len:
        ; len += *x
        lda.w $0000,X
        and #$00FF
        tay
        clc
        adc.b LEN_MATCH
        sta.b LEN_MATCH
        ; ++x
        inx
        ; loop
        cpy #$00FF
        beq @loop_read_match_len
    @end_read_match_len:
    ; write match block
    ; can't use DMA, because WRAM -> WRAM is forbidden
    ; MVP/MVN is tricky, since they require banks as arguments
    ; will use MVP since it's faster than a loop copy
    ; This would be a few cycles faster per block if we copied the entire
    ; routine into ram (saving the two jml instructions), but this isn't necessary.
    phx
    phb
    ldy.b DEST_ADDR
    ldx.b DEST_OFFSET
    dec A
    jml tempWritableCode
@match_copy_end:
    plb ; bank was changed to DEST, but bank needs to be SRC
    plx
    ; update DEST_ADDR
    sty.b DEST_ADDR
    tya
    sta.l WMADDL
    ; loop
    jmp @read_token
; end
@end:
    plb
    rtl
    .UNDEFINE NUM_BLOCKS
    .UNDEFINE LEN_LITERAL
    .UNDEFINE LEN_MATCH
    .UNDEFINE DEST_ADDR
    .UNDEFINE DEST_OFFSET

.ENDS