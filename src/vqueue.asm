.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "VQueue" FREE

ClearVQueue:
    rep #$20 ; 16b A
    stz.w vqueueNumOps
    lda #loword(vqueueBinData)
    sta.w vqueueBinOffset
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
    lda.w vqueueNumOps
    bne @process_vqueue_loop
@process_vqueue_end:
    rep #$30 ; 16b AXY
    stz.w vqueueNumOps
    lda.w #loword(vqueueBinData)
    sta.w vqueueBinOffset
    rtl
.ENDS