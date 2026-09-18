; Palette allocation mode
; bit 1 indicates that [X+0] is allocated
; bit 2 indicates that [X+1] is allocated
; bit 3 indicates that [X+2] is allocated
.DEFINE PALETTE_ALLOC_NONE 0
.DEFINE PALETTE_ALLOC_8A  %00000001
.DEFINE PALETTE_ALLOC_8B  %00000010
.DEFINE PALETTE_ALLOC_8C  %00000100
.DEFINE PALETTE_ALLOC_12A %00000011
.DEFINE PALETTE_ALLOC_12B %00000110
.DEFINE PALETTE_ALLOC_12C %00000101
.DEFINE PALETTE_ALLOC_16  %00000111

; Palette swizzle mode
.DEFINE PALETTE_SWIZZLE_NONE %00 ; (A', B') = (A, B)
.DEFINE PALETTE_SWIZZLE_A_A  %01 ; (A', B') = (A, A)
.DEFINE PALETTE_SWIZZLE_AB_A %10 ; (A', B') = (A | B, A)
.DEFINE PALETTE_SWIZZLE_B_AB %11 ; (A', B') = (B, A | B)

; Tile palette allocation
.DEFINE PALETTE_TILESET.0 $0000 ; ground palette
.DEFINE PALETTE_TILESET.1 $4000 ; unused (currently)
.DEFINE PALETTE_TILESET.2 $2000 ; tileset 1
.DEFINE PALETTE_TILESET.3 $3000 ; tileset 2

; UI palette allocation
.DEFINE PALETTE_UI.0 $1000 ; item slot
.DEFINE PALETTE_UI.1 $5000 ; base UI 1
.DEFINE PALETTE_UI.2 $6000 ; base UI 2
.DEFINE PALETTE_UI.3 $7000 ; consumable slot

.STRUCT hdmapalettebufferentry_t
    lines db
    ignored db
    cgaddr db
    color dw
.ENDST

.MACRO .PaletteIndexToPaletteSpriteA
    .DivideStatic 4
.ENDM

.MACRO .PaletteIndex_X_ToSpriteDef_A
    lda.w paletteAllocMode+1,X
    and #$00FE
    tax
    lda.l PaletteAllocToSpriteSwizzleDef,X
    and #$C000
.ENDM

; PROCEDURE DEFINITIONS

