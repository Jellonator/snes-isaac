.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "VQueue" FREE

ClearVQueue:
    rep #$20 ; 16b A
    stz.w vqueueNumOps
    lda #loword(vqueueBinData_End)
    sta.w vqueueBinOffset
    stz.w vqueueNumMiniOps
    stz.w vqueueNumRegOps
    rtl

_proc_vqueue_vram:
    .ACCU 16
    .INDEX 16
    lda #(%00000001 + ($0100 * $18))
    sta.l DMA0_CTL
    lda.w vqueueOps.1.vramAddr,Y
    sta.l VMADDR
    lda.w vqueueOps.1.aAddr,Y
    sta.l DMA0_SRCL
    lda.w vqueueOps.1.aAddr+2,Y
    sta.l DMA0_SRCH
    lda.w vqueueOps.1.numBytes,Y
    sta.l DMA0_SIZE
    ; we can avoid switching to 8b to set MDMAEN here while also avoiding
    ; accidentally overwriting MDMAEN by writing to VTIMEH. Since IRQ is
    ; disabled anyways and probably will see no use, we can overwrite it with
    ; no issue.
    lda #$0100
    sta.l MDMAEN-1
    jmp ProcessVQueue@process_vqueue_loop_continue

_proc_vqueue_cgram:
    .ACCU 16
    .INDEX 16
    lda #(%00000000 + ($0100 * $22))
    sta.l DMA0_CTL
    lda.w vqueueOps.1.vramAddr,Y
    sep #$20
    sta.l CGADDR
    rep #$20
    lda.w vqueueOps.1.aAddr,Y
    sta.l DMA0_SRCL
    lda.w vqueueOps.1.aAddr+2,Y
    sta.l DMA0_SRCH
    lda.w vqueueOps.1.numBytes,Y
    sta.l DMA0_SIZE
    lda #$0100
    sta.l MDMAEN-1
    jmp ProcessVQueue@process_vqueue_loop_continue

_proc_vqueue_vram_clear:
    .ACCU 16
    .INDEX 16
    lda #(%00001001 + ($0100 * $18))
    sta.l DMA0_CTL
    lda.w vqueueOps.1.vramAddr,Y
    sta.l VMADDR
    lda #loword(EmptyData)
    sta.l DMA0_SRCL
    lda.w #bankbyte(EmptyData)
    sta.l DMA0_SRCH
    lda.w vqueueOps.1.numBytes,Y
    sta.l DMA0_SIZE
    lda #$0100
    sta.l MDMAEN-1
    jmp ProcessVQueue@process_vqueue_loop_continue

_proc_modes:
    .dw _proc_vqueue_vram
    .dw _proc_vqueue_cgram
    .dw _proc_vqueue_vram_clear

ProcessVQueue:
    phb
    .ChangeDataBank $7F
    rep #$30 ; 8b A
    lda.l vqueueNumOps
    beq @process_vqueue_end
    sta.b $00
    ; Assume that most vqueue operations are going to use standard increment.
    lda #$80
    sta.l VMAIN
    ldy #0
@process_vqueue_loop: ; do {
    lda.w vqueueOps.1.mode,Y
    and #$00FF
    tax
    jmp (_proc_modes,X)
@process_vqueue_loop_continue:
    tya
    clc
    adc #_sizeof_vqueueop_t
    tay
    ; while (--vqueueNumOps != 0);
    dec.b $00
    bne @process_vqueue_loop
@process_vqueue_end:
; Process register queue
    lda.l vqueueNumRegOps
    beq @process_reg_end
    asl
    sta.b $00
    sep #$20
    ldy #0
@process_reg_loop:
    ldx.w vqueueRegOps_Addr,Y
    lda.w vqueueRegOps_Value,Y
    sta.b $00,X
    iny
    iny
    cpy.b $00
    bcc @process_reg_loop
@process_reg_end:
; Clear vqueue and reset bank
    plb
    rep #$30
    stz.w vqueueNumOps
    stz.w vqueueNumRegOps
    lda.w #loword(vqueueBinData_End)
    sta.w vqueueBinOffset
; Process miniqueue
    lda.w vqueueNumMiniOps
    beq @process_mini_end
    stz.w vqueueNumMiniOps
    asl
    asl
    sta.w DMA0_SIZE
    lda #%0000100 + (256*lobyte(VMADDR))
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