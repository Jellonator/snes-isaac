.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "MENU" FREE

; Enter menu
Menu.Begin:

; Main loop for menu
_Menu.Loop:
    jmp _Menu.Loop

.ENDS