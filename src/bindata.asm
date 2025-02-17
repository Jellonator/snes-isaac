.include "base.inc"

.include "assets.inc"

.include "roompools.inc"

.SECTION "ExtraData" BANK ROMBANK_BASE SLOT "ROM" ORGA $8000 SEMIFREE
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
    ; row 1
    .REPT 32
        .dw 0
    .ENDR
    ; row 2
    .dw 0
    .dw deft($02,6) | T_HIGHP
    .dw deft($03,6) | T_HIGHP
    .dw deft($03,6) | T_HIGHP
    .dw deft($02,6) | T_HIGHP | T_FLIPH
    .REPT 27
        .dw 0
    .ENDR
    ; row 3
    .dw 0
    .dw deft($12,6) | T_HIGHP
    .dw deft($EE,4) | T_HIGHP
    .dw deft($EF,4) | T_HIGHP
    .dw deft($12,6) | T_HIGHP | T_FLIPH
    .dw deft($01,6) | T_HIGHP
    .dw deft($70,5) | T_HIGHP
    .dw deft($70,5) | T_HIGHP
    .REPT 24
        .dw 0
    .ENDR
    ; row 4
    .dw 0
    .dw deft($12,6) | T_HIGHP
    .dw deft($FE,4) | T_HIGHP
    .dw deft($FF,4) | T_HIGHP
    .dw deft($12,6) | T_HIGHP | T_FLIPH
    .dw deft($11,5) | T_HIGHP
    .dw deft($70,5) | T_HIGHP
    .dw deft($70,5) | T_HIGHP
    .REPT 24
        .dw 0
    .ENDR
    ; row 5
    .dw 0
    .dw deft($02,6) | T_HIGHP | T_FLIPV
    .dw deft($03,6) | T_HIGHP | T_FLIPV
    .dw deft($03,6) | T_HIGHP | T_FLIPV
    .dw deft($02,6) | T_HIGHP | T_FLIPH | T_FLIPV
    .dw deft($10,5) | T_HIGHP
    .dw deft($70,5) | T_HIGHP
    .dw deft($70,5) | T_HIGHP
    .REPT 24
        .dw 0
    .ENDR
    ; row 6-22
    .REPT 32*18
        .dw 0
    .ENDR
    ; row 23-27
    .REPT 4 INDEX iy
        .REPT 27
            .dw 0
        .ENDR
        .REPT 4 INDEX ix
            .dw deft($C0 + ix + iy*16, 7) | T_HIGHP
        .ENDR
        .dw 0
    .ENDR
    ; row 28-32
    .REPT 32*5
        .dw 0
    .ENDR

    @end:
MapTiles:
    .dw 0 ; empty
    .dw deft($08, 6) | T_HIGHP ; normal
    .dw deft($09, 6) | T_HIGHP ; item
    .dw deft($0A, 6) | T_HIGHP ; boss
    .dw deft($0B, 6) | T_HIGHP ; shop
    .dw deft($0C, 5) | T_HIGHP ; sacrifice
    .dw deft($0D, 5) | T_HIGHP ; curse
    .dw deft($0E, 6) | T_HIGHP ; secret
    .dw deft($08, 6) | T_HIGHP ; start
SpriteIndexToExtMaskXS:
    .REPT 128 / 4 INDEX i
        .db %00000011 0 i 0
        .db %00001100 0 i 0
        .db %00110000 0 i 0
        .db %11000000 0 i 0
    .ENDR
SpriteIndexToExtMaskX:
    .REPT 128 / 4 INDEX i
        .db %00000001 0 i 0
        .db %00000100 0 i 0
        .db %00010000 0 i 0
        .db %01000000 0 i 0
    .ENDR
SpriteIndexToExtMaskS:
    .REPT 128 / 4 INDEX i
        .db %00000010 0 i 0
        .db %00001000 0 i 0
        .db %00100000 0 i 0
        .db %10000000 0 i 0
    .ENDR

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
; MATH TABLES ;
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

; vector length
; INDEX: xxxxyyyy (x,y: signed value b/t -8 and 7)
; output is between 0 and 12
VecLenTableB:
    .REPT 8 INDEX ix
        .REPT 8 INDEX iy
            .IF (ix == 0) && (iy == 0)
                .db 0
            .ELSE
                .db sqrt((ix * ix) + (iy * iy))
            .ENDIF
        .ENDR
        .REPT 8 INDEX iy
            .db sqrt((ix * ix) + ((iy-8) * (iy-8)))
        .ENDR
    .ENDR
    .REPT 8 INDEX ix
        .REPT 8 INDEX iy
            .db sqrt(((ix - 8) * (ix - 8)) + (iy * iy))
        .ENDR
        .REPT 8 INDEX iy
            .db sqrt(((ix - 8) * (ix - 8)) + ((iy-8) * (iy-8)))
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

RoomTileToXTable:
    .REPT 8
        .REPT 12 INDEX i
            .db i
        .ENDR
    .ENDR
    .db 0
    .db 0

RoomTileToYTable:
    .REPT 8 INDEX i
        .REPT 12
            .db i
        .ENDR
    .ENDR
    .db 0
    .db 0

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

HitboxWidthToPartitionSize:
    .REPT 256 INDEX i
        .IF i == 0
            .db 1
        .ELIF i == 1
            .db 1
        .ELSE
            .db ceil((i + 16) / 16)
        .ENDIF
    .ENDR

Div16:
    .REPT 256 INDEX i
        .db floor(i / 16)
    .ENDR

    .REPT 256 INDEX i
        .db i
    .ENDR
OffsetTable:
    .REPT 256 INDEX i
        .db i
    .ENDR
    .REPT 256 INDEX i
        .db i
    .ENDR

PaletteDepthRequiredSlots:
    .REPT 17 INDEX i
        .IF i <= 4
            .db 0
        .ELIF i <= 8
            .db 1
        .ELIF i <= 12
            .db 2
        .ELSE
            .db 3
        .ENDIF
    .ENDR

PaletteIndexToPaletteSprite
    .REPT 8 INDEX i
        .REPT 4
            .dw (i << 2)
        .ENDR
    .ENDR
.ENDS

.bank $20
.SECTION "ExtraData2"

DefaultBackgroundTileData:
.REPT 32 INDEX iy ; 32 tiles
    .REPT 32 INDEX ix ; by 32 tiles
        .IF (iy < 8) || (iy >= 24) || (ix < 4) || (ix >= 28)
            ; Let's just trust that the first UI tile will always be empty
            .dw (BG1_CHARACTER_BASE_ADDR / 8)
        .ELSE
            .dw %0000000000000000 | ((iy - 8) * 24 + ix - 4)
        .ENDIF
    .ENDR
.ENDR

.ENDS