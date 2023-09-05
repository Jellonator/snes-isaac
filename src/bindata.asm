.include "base.inc"

.bank $40
.SECTION "Graphics" FREE
.include "assets.inc"
.ENDS

.include "roompools.inc"

.bank $00
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
    .REPT 32
        .dw $0000
    .ENDR
    .dw $0000 $2C02 $2C03 $2C03 $6C02
    .REPT 8
        .dw 0
    .ENDR
    .dw 0, 0, 0
    .REPT 16
        .dw $0000
    .ENDR
    .dw $0000 $2C12 $0000 $0000 $6C12
    .dw deft($01,3) | T_HIGHP, deft($70, 4) | T_HIGHP, deft($70, 4) | T_HIGHP
    .REPT 24
        .dw $0000
    .ENDR
    .dw $0000 $2C12 $0000 $0000 $6C12
    .dw deft($11,4) | T_HIGHP, deft($70, 4) | T_HIGHP, deft($70, 4) | T_HIGHP
    .REPT 24
        .dw $0000
    .ENDR
    .dw $0000 $AC02 $AC03 $AC03 $EC02
    .dw deft($10,2) | T_HIGHP, deft($70, 4) | T_HIGHP, deft($70, 4) | T_HIGHP
    .REPT 24
        .dw $0000
    .ENDR
    .dw $0000
    .dw $0000
    .dw $2C16
    .REPT 31
        .dw $0000
    .ENDR
    .dw $2C25
    .REPT 31
        .dw $0000
    .ENDR
    .dw $2C34
    .REPT 29
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

;-------------;
; DATA TABLES ;
;-------------;

; sin/cos
; INDEX: angle b/t 0 and 255
; OUTPUT: signed sin or cos value with magnitude of 127

SinTableB:
    .DBSIN 0.0, 63, (360.0/256.0), 127, 0
CosTableB:
    .DBCOS 0.0, 255, (360.0/256.0), 127, 0

; vector norm
; INDEX: xxxxyyyy (x,y: signed value b/t -8 and 7)
VecNormTableB_X:
    .REPT 8 INDEX ix
        .REPT 8 INDEX iy
            .IF (ix == 0) && (iy == 0)
                .db 0
            .ELSE
                .db ((127 * ix) / sqrt((ix * ix) + (iy * iy)))
            .ENDIF
        .ENDR
        .REPT 8 INDEX iy
            .db ((127 * ix) / sqrt((ix * ix) + ((iy-8) * (iy-8))))
        .ENDR
    .ENDR
    .REPT 8 INDEX ix
        .REPT 8 INDEX iy
            .db ((127 * (ix - 8)) / sqrt(((ix - 8) * (ix - 8)) + (iy * iy)))
        .ENDR
        .REPT 8 INDEX iy
            .db ((127 * (ix - 8)) / sqrt(((ix - 8) * (ix - 8)) + ((iy-8) * (iy-8))))
        .ENDR
    .ENDR
VecNormTableB_Y:
    .REPT 8 INDEX ix
        .REPT 8 INDEX iy
            .IF (ix == 0) && (iy == 0)
                .db 0
            .ELSE
                .db ((127 * iy) / sqrt((ix * ix) + (iy * iy)))
            .ENDIF
        .ENDR
        .REPT 8 INDEX iy
            .db ((127 * (iy - 8)) / sqrt((ix * ix) + ((iy-8) * (iy-8))))
        .ENDR
    .ENDR
    .REPT 8 INDEX ix
        .REPT 8 INDEX iy
            .db ((127 * iy) / sqrt(((ix - 8) * (ix - 8)) + (iy * iy)))
        .ENDR
        .REPT 8 INDEX iy
            .db ((127 * (iy - 8)) / sqrt(((ix - 8) * (ix - 8)) + ((iy-8) * (iy-8))))
        .ENDR
    .ENDR

GameTileToRoomTileIndexTable:
    .REPT 16*3
        .db 97
    .ENDR
    .REPT 16
        .db 96
    .ENDR
    .REPT 8 INDEX iy
        .db 97, 96
        .REPT 12 INDEX ix
            .db (iy * 12) + ix
        .ENDR
        .db 96, 97
    .ENDR
    .REPT 16
        .db 96
    .ENDR
    .REPT 16*3
        .db 97
    .ENDR

InitialPathfindingData:
.REPT 16*4
    .db $01 ; down
.ENDR
.REPT 8
    .db $02, $02 ; right
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; empty
    .db $03, $03 ; left
.ENDR
.REPT 16*4
    .db $04 ; up
.ENDR

.ENDS