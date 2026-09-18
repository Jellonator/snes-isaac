.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "Hooks" FREE

Hook.PlayerDamage:
    .ForceSetAX 8, 8
    ; fish head
    .PlayerHasTrinketEffect TRINKET_FISH_HEAD
    beq +
        lda #2
        jsl HelperFly.Add
        .ForceSetAX 8, 8
    +:
    rtl

.ENDS