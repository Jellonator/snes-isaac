.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "Hooks" FREE

Hook.PlayerDamage:
    sep #$30
    ; fish head
    .PlayerHasTrinketEffect TRINKET_FISH_HEAD
    beq +
        lda #2
        jsl HelperFly.Add
        sep #$30
    +:
    rtl

.ENDS