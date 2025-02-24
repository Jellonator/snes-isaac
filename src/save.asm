.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "MENU" FREE

; boring, I know
_save_key:
    .db "ISAAC SAVE $0001"
        ;----------------; 16B

; Return A==1 if save key does not match
_Save.CheckKey:
    sep #$20
    .REPT 16 INDEX i
        lda.l _save_key+i
        cmp.l saveCheck+i
        bnel @fail
    .ENDR
    lda #0
    rtl
@fail:
    lda #1
    rtl

Save.Init:
    jsl _Save.CheckKey
    .ACCU 8
    cmp #0
    beq +
        jsl _Save.ClearAll
    +:
    rep #$30
    lda #0
    sta.l currentSaveSlot
    rtl

_Save.ClearAll:
    ; init seed timers with random noise from RAM
    rep #$30
    ldx #0
    lda #0
@loop_seed_low:
    adc.l $7E0000,X
    inx
    inx
    bne @loop_seed_low
    sta.l seed_timer_low
    ldx #0
    lda #0
@loop_seed_high:
    adc.l $7F0000,X
    inx
    inx
    bne @loop_seed_high
    sta.l seed_timer_high
    ; clear each save slot
    rep #$20
    lda #0
    jsl Save.EraseSlot
    rep #$20
    lda #1
    jsl Save.EraseSlot
    rep #$20
    lda #2
    jsl Save.EraseSlot
    ; clear each save state
    sep #$20
    lda #0
    jsl Save.EraseSaveState
    sep #$20
    lda #1
    jsl Save.EraseSaveState
    sep #$20
    lda #2
    jsl Save.EraseSaveState
    ; finally, copy save key:
    sep #$20
    .REPT 16 INDEX i
        lda.l _save_key+i
        sta.l saveCheck+i
    .ENDR
    rtl

; erase slot A
Save.EraseSlot:
    rep #$30
    and #$00FF
    .MultiplyStatic $0800
    tax
    lda #SAVESLOT_STATE_EMPTY
    sta.l saveslot.0.state,X
    rtl

; erase save state A
Save.EraseSaveState:
    ; set up bank
    sep #$20
    clc
    adc #$21
    phb
    pha
    plb
    ; write save state
    lda #SAVESTATE_STATE_EMPTY
    sta.w loword(savestate.0.state)
    ; end
    plb
    rtl

.ENDS