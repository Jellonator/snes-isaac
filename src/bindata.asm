.include "base.inc"

.bank $40
.SECTION "Graphics" SUPERFREE
.include "assets.inc"
.ENDS

.bank $41
.SECTION "ExtraData"
EmptyData:
    .dw $0000
EmptySpriteData:
    .REPT 128
        .db $00 $F0 $00 $00
    .ENDR
    .REPT 32
        .db %00000000
    .ENDR
DefaultUiData:
    .dw $0000 $2C02 $2C03 $2C03 $6C02
    .dw $2C20 $2830 $2830 $2830 $2830 $2831 $2832
    .REPT 20
        .dw $0000
    .ENDR
    .dw $0000 $2C12 $0000 $0000 $6C12
    .dw $2C21 $2832 $2832 $2C30 $2C33 $0000 $0000
    .REPT 20
        .dw $0000
    .ENDR
    .dw $0000 $2C12 $0000 $0000 $6C12
    .dw $2C22
    .REPT 26
        .dw $0000
    .ENDR
    .dw $0000 $AC02 $AC03 $AC03 $EC02
    .dw $0000
    .REPT 26
        .dw $0000
    .ENDR
    @end:
MapTiles:
    .dw $2000 ; empty
    .dw $2C08 ; normal
    .dw $2C09 ; item
    .dw $2C0A ; boss
    .dw $2C0B ; shop
    .dw $280C ; sacrifice
    .dw $280D ; curse
    .dw $2C0E ; secret
SpriteIndexToExtMaskXS:
    .db %00000011 %00001100 %00110000 %11000000
SpriteIndexToExtMaskX:
    .db %00000001 %00000100 %00010000 %01000000
SpriteIndexToExtMaskS:
    .db %00000010 %00001000 %00100000 %10000000
.ENDS