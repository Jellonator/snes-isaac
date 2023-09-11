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
        .dw 0
    .ENDR
    .dw 0
    .dw deft($02,6) | T_HIGHP
    .dw deft($03,6) | T_HIGHP
    .dw deft($03,6) | T_HIGHP
    .dw deft($02,6) | T_HIGHP | T_FLIPH
    .REPT 8
        .dw 0
    .ENDR
    .dw 0, 0, 0
    .REPT 16
        .dw 0
    .ENDR
    .dw 0
    .dw deft($12,6) | T_HIGHP
    .dw 0
    .dw 0
    .dw deft($12,6) | T_HIGHP | T_FLIPH
    .dw deft($01,6) | T_HIGHP
    .dw deft($70,7) | T_HIGHP
    .dw deft($70,7) | T_HIGHP
    .REPT 24
        .dw 0
    .ENDR
    .dw 0
    .dw deft($12,6) | T_HIGHP
    .dw 0
    .dw 0
    .dw deft($12,6) | T_HIGHP | T_FLIPH
    .dw deft($11,7) | T_HIGHP
    .dw deft($70,7) | T_HIGHP
    .dw deft($70,7) | T_HIGHP
    .REPT 24
        .dw 0
    .ENDR
    .dw 0
    .dw deft($02,6) | T_HIGHP | T_FLIPV
    .dw deft($03,6) | T_HIGHP | T_FLIPV
    .dw deft($03,6) | T_HIGHP | T_FLIPV
    .dw deft($02,6) | T_HIGHP | T_FLIPH | T_FLIPV
    .dw deft($10,5) | T_HIGHP
    .dw deft($70,7) | T_HIGHP
    .dw deft($70,7) | T_HIGHP
    .REPT 24
        .dw 0
    .ENDR
    .dw 0
    .dw 0
    .dw deft($16,6) | T_HIGHP
    .REPT 31
        .dw 0
    .ENDR
    .dw deft($25,6) | T_HIGHP
    .REPT 31
        .dw 0
    .ENDR
    .dw deft($34,6) | T_HIGHP
    .REPT 29
        .dw 0
    .ENDR
    @end:
MapTiles:
    .dw deft($00, 0) | T_HIGHP ; empty
    .dw deft($08, 6) | T_HIGHP ; normal
    .dw deft($09, 6) | T_HIGHP ; item
    .dw deft($0A, 6) | T_HIGHP ; boss
    .dw deft($0B, 6) | T_HIGHP ; shop
    .dw deft($0C, 5) | T_HIGHP ; sacrifice
    .dw deft($0D, 5) | T_HIGHP ; curse
    .dw deft($0E, 6) | T_HIGHP ; secret
SpriteIndexToExtMaskXS:
    .db %00000011 %00001100 %00110000 %11000000
SpriteIndexToExtMaskX:
    .db %00000001 %00000100 %00010000 %01000000
SpriteIndexToExtMaskS:
    .db %00000010 %00001000 %00100000 %10000000

SpriteIndexToExtMaskXS_16:
    .REPT 8 INDEX i
        .dw (%00000011 << (i * 2))
    .ENDR
SpriteIndexToExtMaskX_16:
    .REPT 8 INDEX i
        .dw (%00000001 << (i * 2))
    .ENDR
SpriteIndexToExtMaskS_16:
    .REPT 8 INDEX i
        .dw (%00000010 << (i * 2))
    .ENDR

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

.bank $20
.SECTION "ExtraData2"

DefaultBackgroundTileData:
.REPT 32 INDEX iy ; 32 tiles
    .REPT 32 INDEX ix ; by 32 tiles
        .IF (iy < 8) || (iy >= 24) || (ix < 4) || (ix >= 28)
            ; Let's just trust that the first UI tile will always be empty
            .dw 24*16 + $100
        .ELSE
            .dw %0000000000000000 | ((iy - 8) * 24 + ix - 4)
        .ENDIF
    .ENDR
.ENDR

.ENDS