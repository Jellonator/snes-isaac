.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "MENU" FREE

; boring, I know
_save_key:
    .db "ISAAC SAVE $0000"
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
    rtl

_Save.ClearAll:
    ; init seed timers with random noise from RAM
    rep #$20
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
    ; finally, copy save key:
    sep #$20
    .REPT 16 INDEX i
        lda.l _save_key+i
        sta.l saveCheck+i
    .ENDR
    rtl

.ENDS