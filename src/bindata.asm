.include "base.inc"

.include "assets.inc"
.include "roompools.inc"
.include "tilemaps.inc"

.SECTION "ExtraData" BANK ROMBANK_BASE SLOT "ROM" ORGA $8000 SEMIFREE
EmptyData:
    .dw $0000
EmptyBackgroundTile:
    .dw deft($08, 2)
TransparentBackgroundTile:
    .dw deft($20, 2)
EmptySpriteData:
    .REPT 128
        .db $00 $F0 $00 $00
    .ENDR
    .REPT 32
        .db %00000000
    .ENDR
DefaultUiData:
    ; row 1
    .dsw 32, 0
    ; row 2
    .dw 0
    .dw deft($02,6) | T_HIGHP
    .dw deft($03,6) | T_HIGHP
    .dw deft($03,6) | T_HIGHP
    .dw deft($02,6) | T_HIGHP | T_FLIPH
    .dsw 19, 0
    .dw deft($42, 6) | T_HIGHP
    .dsw 5, deft($43, 6) | T_HIGHP
    .dw deft($42, 6) | T_FLIPH | T_HIGHP
    .dw 0
    ; row 3
    .dw 0
    .dw deft($12,6) | T_HIGHP
    .dw deft($EE,4) | T_HIGHP
    .dw deft($EF,4) | T_HIGHP
    .dw deft($12,6) | T_HIGHP | T_FLIPH
    .dw deft($01,6) | T_HIGHP
    .dw deft(TILE_TEXT_UINUMBER_BASE + 0,5) | T_HIGHP
    .dw deft(TILE_TEXT_UINUMBER_BASE + 0,5) | T_HIGHP
    .dsw 16, 0
    .dw deft($52, 6) | T_HIGHP
    .dsw 5, 0
    .dw deft($52, 6) | T_FLIPH | T_HIGHP
    .dw 0
    ; row 4
    .dw 0
    .dw deft($12,6) | T_HIGHP
    .dw deft($FE,4) | T_HIGHP
    .dw deft($FF,4) | T_HIGHP
    .dw deft($12,6) | T_HIGHP | T_FLIPH
    .dw deft($11,5) | T_HIGHP
    .dw deft(TILE_TEXT_UINUMBER_BASE + 0,5) | T_HIGHP
    .dw deft(TILE_TEXT_UINUMBER_BASE + 0,5) | T_HIGHP
    .dsw 16, 0
    .dw deft($52, 6) | T_HIGHP
    .dsw 5, 0
    .dw deft($52, 6) | T_FLIPH | T_HIGHP
    .dw 0
    ; row 5
    .dw 0
    .dw deft($02,6) | T_HIGHP | T_FLIPV
    .dw deft($03,6) | T_HIGHP | T_FLIPV
    .dw deft($03,6) | T_HIGHP | T_FLIPV
    .dw deft($02,6) | T_HIGHP | T_FLIPH | T_FLIPV
    .dw deft($21,5) | T_HIGHP
    .dw deft(TILE_TEXT_UINUMBER_BASE + 0,5) | T_HIGHP
    .dw deft(TILE_TEXT_UINUMBER_BASE + 0,5) | T_HIGHP
    .dsw 16, 0
    .dw deft($52, 6) | T_HIGHP
    .dsw 5, 0
    .dw deft($52, 6) | T_FLIPH | T_HIGHP
    .dw 0
    ; row 6
    .dsw 24, 0
    .dw deft($52, 6) | T_HIGHP
    .dsw 5, 0
    .dw deft($52, 6) | T_FLIPH | T_HIGHP
    .dw 0
    ; row 7
    .dsw 24, 0
    .dw deft($52, 6) | T_HIGHP
    .dsw 5, 0
    .dw deft($52, 6) | T_FLIPH | T_HIGHP
    .dw 0
    ; row 8
    .dsw 24, 0
    .dw deft($42, 6) | T_HIGHP | T_FLIPV
    .dsw 5, deft($43, 6) | T_HIGHP | T_FLIPV
    .dw deft($42, 6) | T_FLIPH | T_HIGHP | T_FLIPV
    .dw 0
    ; row 6-23
    .dsw 32*15, 0
    ; row 24-27
    .REPT 4 INDEX iy
        .dsw 27, 0
        .REPT 4 INDEX ix
            .dw deft($C0 + ix + iy*16, 7) | T_HIGHP
        .ENDR
        .dw 0
    .ENDR
    ; row 28-32
    .dsw 32*5, 0

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
    .dw 0 ; devil
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

SinTable8:
    .DBSIN 0.0, 63, (360.0/256.0), 127, 0
CosTable8:
    .DBCOS 0.0, 255, (360.0/256.0), 127, 0

TanTable16:
    .REPT 256 INDEX i
        .dw clamp(tan(i * 3.1415926535 / 128) * 256, -2^15, 2^15-1)
    .ENDR

; log₂(x) where x is 8b, rounded down
; Returns a value between 0 and 7
Log2Table8:
    .db 0 ; just treat log(0) as 0, this is fine :)
    .REPT 255 INDEX i
        .db floor(log2(i + 1))
    .ENDR

; 32log₂(x) where x is 8b, rounded down
; Returns a value between 0 and 255
Log2Mult32Table8:
    .db 0 ; just treat log(0) as 0, this is fine :)
    .REPT 255 INDEX i
        .db min(255,floor(32 * log2(i + 1)))
    .ENDR

; Table used for calculating atan using logarithms
AtanLogTable8:
    .REPT 256 INDEX i
        .db 64 - atan(2^((256 - i) / 32)) * 128 / 3.1415926535
    .ENDR

; Used to adjust result of atan. Used in various areas.
; See https://codebase64.org/doku.php?id=base:8bit_atan2_8-bit_angle for more information.
AtanOctantAdjustTable8:
    .db %00111111		;; x+,y+,|x|>|y|
    .db %00000000		;; x+,y+,|x|<|y|
    .db %11000000		;; x+,y-,|x|>|y|
    .db %11111111		;; x+,y-,|x|<|y|
    .db %01000000		;; x-,y+,|x|>|y|
    .db %01111111		;; x-,y+,|x|<|y|
    .db %10111111		;; x-,y-,|x|>|y|
    .db %10000000		;; x-,y-,|x|<|y|

Pow2Div32Table8:
    .REPT 256 INDEX i
        .db 2^(i / 32)
    .ENDR

; Flip nibble
NibbleFlip8:
.REPT 256 INDEX i
    .db ((i & $0F) << 4) | ((i & $F0) >> 4)
.ENDR

; Top nibble
NibbleTop8:
    .REPT 256 INDEX i
        .db (i & $F0)
    .ENDR

; Bottom nibble
NibbleBottom8:
    .REPT 256 INDEX i
        .db (i & $0F)
    .ENDR

; 256 words for squaring byte values
SquareTableU16:
    .REPT 256 INDEX i
        .dw i*i
    .ENDR

SquareTableS16:
    .REPT 128 INDEX i
        .dw i*i
    .ENDR
    .REPT 128 INDEX i
        .dw (128-i) * (128-i)
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

; $00 for tiles that are fully in bounds
; $01 for tiles that are walls
; $81 for tiles that are fully out of bounds
; To test if tile is considered partially in-bounds (floor and walls):
;     lda GameTileBoundaryCheck,X
;     bpl @tile_is_in_bounds
; To test if tile is considered totally in-bounds (floors only):
;     lda GameTileBoundaryCheck,X
;     beq @tile_is_in_bounds
GameTileBoundaryCheck:
    .REPT 3
        .dsb 16, $81
    .ENDR
    .db $81, $01
    .dsb 12, $01
    .db $01, $81
    .REPT 8
        .db $81, $01
        .dsb 12, $00
        .db $81, $01
    .ENDR
    .db $81, $01
    .dsb 12, $01
    .db $01, $81
    .REPT 3
        .dsb 16, $81
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

PaletteIndexToPaletteSprite:
    .REPT 8 INDEX i
        .REPT 4
            .dw (i << 2)
        .ENDR
    .ENDR

PaletteAllocNeedSwizzle:
    .db 0 ; PALLETE_ALLOC_NONE 0
    .db 0 ; PALLETE_ALLOC_8A  %00000001
    .db 1 ; PALLETE_ALLOC_8B  %00000010
    .db 0 ; PALLETE_ALLOC_12A %00000011
    .db 1 ; PALLETE_ALLOC_8C  %00000100
    .db 1 ; PALLETE_ALLOC_12C %00000101
    .db 1 ; PALLETE_ALLOC_12B %00000110
    .db 0 ; PALLETE_ALLOC_16  %00000111

PaletteIndexIsStatic:
    .REPT 8 INDEX iy
        .REPT 4 INDEX ix
            .IF ix == 0 || iy == 0 || iy == 4 || iy == 7
                .dw $01
            .ELSE
                .dw $00
            .ENDIF
        .ENDR
    .ENDR

RandTable:
    .SEED $B00B
    .DBRND (RANDTABLE_SIZE+1) 0 255

FractionBinToDec:
    .REPT 256 INDEX i
        .db bin2dec(floor(i / 2.56))
    .ENDR

PathOrthagonal_H:
    .db PATH_DIR_NULL  ; PATH_DIR_NULL
    .db PATH_DIR_DOWN  ; PATH_DIR_DOWN
    .db PATH_DIR_RIGHT ; PATH_DIR_RIGHT
    .db PATH_DIR_LEFT  ; PATH_DIR_LEFT
    .db PATH_DIR_UP    ; PATH_DIR_UP
    .db PATH_DIR_LEFT  ; PATH_DIR_UPLEFT
    .db PATH_DIR_RIGHT ; PATH_DIR_UPRIGHT
    .db PATH_DIR_LEFT  ; PATH_DIR_DOWNLEFT
    .db PATH_DIR_RIGHT ; PATH_DIR_DOWNRIGHT
    .db PATH_DIR_NONE  ; PATH_DIR_NONE

PathOrthagonal_V:
    .db PATH_DIR_NULL  ; PATH_DIR_NULL
    .db PATH_DIR_DOWN  ; PATH_DIR_DOWN
    .db PATH_DIR_RIGHT ; PATH_DIR_RIGHT
    .db PATH_DIR_LEFT  ; PATH_DIR_LEFT
    .db PATH_DIR_UP    ; PATH_DIR_UP
    .db PATH_DIR_UP    ; PATH_DIR_UPLEFT
    .db PATH_DIR_UP    ; PATH_DIR_UPRIGHT
    .db PATH_DIR_DOWN  ; PATH_DIR_DOWNLEFT
    .db PATH_DIR_DOWN  ; PATH_DIR_DOWNRIGHT
    .db PATH_DIR_NONE  ; PATH_DIR_NONE

PathValid:
    .db 0 ; PATH_DIR_NULL
    .db 1 ; PATH_DIR_DOWN
    .db 1 ; PATH_DIR_RIGHT
    .db 1 ; PATH_DIR_LEFT
    .db 1 ; PATH_DIR_UP
    .db 1 ; PATH_DIR_UPLEFT
    .db 1 ; PATH_DIR_UPRIGHT
    .db 1 ; PATH_DIR_DOWNLEFT
    .db 1 ; PATH_DIR_DOWNRIGHT
    .db 0 ; PATH_DIR_NONE

Path_X:
    .db  0 ; PATH_DIR_NULL
    .db  0 ; PATH_DIR_DOWN
    .db  1 ; PATH_DIR_RIGHT
    .db -1 ; PATH_DIR_LEFT
    .db  0 ; PATH_DIR_UP
    .db -1 ; PATH_DIR_UPLEFT
    .db  1 ; PATH_DIR_UPRIGHT
    .db -1 ; PATH_DIR_DOWNLEFT
    .db  1 ; PATH_DIR_DOWNRIGHT
    .db  0 ; PATH_DIR_NONE

Path_Y:
    .db  0 ; PATH_DIR_NULL
    .db  1 ; PATH_DIR_DOWN
    .db  0 ; PATH_DIR_RIGHT
    .db  0 ; PATH_DIR_LEFT
    .db -1 ; PATH_DIR_UP
    .db -1 ; PATH_DIR_UPLEFT
    .db -1 ; PATH_DIR_UPRIGHT
    .db  1 ; PATH_DIR_DOWNLEFT
    .db  1 ; PATH_DIR_DOWNRIGHT
    .db  0 ; PATH_DIR_NONE

Path_Angle:
    .db $00 ; PATH_DIR_NULL
    .db $40 ; PATH_DIR_DOWN
    .db $00 ; PATH_DIR_RIGHT
    .db $80 ; PATH_DIR_LEFT
    .db $C0 ; PATH_DIR_UP
    .db $A0 ; PATH_DIR_UPLEFT
    .db $E0 ; PATH_DIR_UPRIGHT
    .db $60 ; PATH_DIR_DOWNLEFT
    .db $20 ; PATH_DIR_DOWNRIGHT
    .db $00 ; PATH_DIR_NONE

Path_TileOffset:
    .db $00 ; PATH_DIR_NULL
    .db $10 ; PATH_DIR_DOWN
    .db $01 ; PATH_DIR_RIGHT
    .db $FF ; PATH_DIR_LEFT
    .db $F0 ; PATH_DIR_UP
    .db $EF ; PATH_DIR_UPLEFT
    .db $F1 ; PATH_DIR_UPRIGHT
    .db $0F ; PATH_DIR_DOWNLEFT
    .db $11 ; PATH_DIR_DOWNRIGHT
    .db $00 ; PATH_DIR_NONE

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