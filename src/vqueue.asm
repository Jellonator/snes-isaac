.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "VQueue" FREE

ClearVQueue:
    rep #$20 ; 16b A
    stz.w vqueueNumOps
    lda #loword(vqueueBinData)
    sta.w vqueueBinOffset
    stz.w vqueueNumMiniOps
    rtl

ProcessVQueue:
    sep #$20 ; 8b A
    lda.w vqueueNumOps
    beq @process_vqueue_end
    lda #$80
    sta.w VMAIN
    rep #$30 ; 16b AXY
    ldx #loword(vqueueOps)
@process_vqueue_loop: ; do {
    lda.l vqueueOps,X
    sta.w VMADDR
    inx
    inx
    lda #6
    ldy #DMA0_CTL
    mvn $7F,$00
    lda #$0001
    sta.w MDMAEN
    ; while (--vqueueNumOps != 0);
    dec.w vqueueNumOps
    bne @process_vqueue_loop
@process_vqueue_end:
    rep #$30 ; 16b AXY
    stz.w vqueueNumOps
    lda.w #loword(vqueueBinData)
    sta.w vqueueBinOffset
; Process miniqueue
    lda.w vqueueNumMiniOps
    beq @process_mini_end
    asl
    asl
    sta.w DMA0_SIZE
    lda #%0000100 + 256*lobyte(VMADDR)
    sta.w DMA0_CTL
    lda #loword(vqueueMiniOps)
    sta.w DMA0_SRCL
    sep #$20 ; 8b A
    lda #bankbyte(vqueueMiniOps)
    sta DMA0_SRCH
    lda #$01
    sta.w MDMAEN
@process_mini_end:
    rtl
.ENDS