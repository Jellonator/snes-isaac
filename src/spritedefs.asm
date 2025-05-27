.include "base.inc"

; Definitions for sprites which are not uploaded manually to VRAM directly from ROM.
; This includes:
;  * static sprites which are only uploaded once when an entity loads (e.g. items)
;  * compressed sprites
;  * animated sprites which require swizzling

.SECTION "SpriteDefs" BANK ROMBANK_BASE SLOT "ROM" ORGA $8000 SEMIFREE

.DEFINE currid 1
SpriteDefs:
.db 0, 0, 0, 0, 0

; Define a new sprite.
; spritename - the exported name of the sprite
;   baseaddr - the address of the sprite's data
;     ntiles - number of 16x16px tiles in one single frame
;    nframes - number of frames to export as separate sprites. These additional
;              sprites can be accessed as {spritename}.{frameid}, and their
;              address will be `baseaddr` + 128*{ntiles}*{frameid}
.MACRO .DefineSprite ARGS spritename, baseaddr, ntiles, nframes, mode
    .DEFINE {spritename} currid EXPORT
    .IFDEF mode ; workaround because 'IFDEF causes issues inside DSTRUCT'
        .DEFINE MODE_REAL_NOT_CLICKBAIT mode
    .ELSE
        .DEFINE MODE_REAL_NOT_CLICKBAIT 0
    .ENDIF
    .REPT nframes INDEX i
        .DSTRUCT INSTANCEOF entityspriteinfo_t VALUES
            sprite_addr: .dw loword(baseaddr) + 128*ntiles*i ; 128b per 16x tile
            sprite_bank: .db bankbyte(baseaddr)
            ntiles: .db ntiles
            mode: .db MODE_REAL_NOT_CLICKBAIT
        .ENDST
        .DEFINE {spritename}.{i} (currid + i) EXPORT
    .ENDR
    .UNDEFINE MODE_REAL_NOT_CLICKBAIT
    .REDEFINE currid (currid + nframes)
.ENDM

; Define a new sprite from a split frames sprite
.MACRO .DefineSpriteSplit ARGS spritename, dataname, ntiles, nframes, mode
    .DEFINE {spritename} currid EXPORT
    .IFDEF mode ; workaround because 'IFDEF causes issues inside DSTRUCT'
        .DEFINE MODE_REAL_NOT_CLICKBAIT mode
    .ELSE
        .DEFINE MODE_REAL_NOT_CLICKBAIT 0
    .ENDIF
    .REPT nframes INDEX i
        .DSTRUCT INSTANCEOF entityspriteinfo_t VALUES
            sprite_addr: .dw loword({dataname}.{i})
            sprite_bank: .db bankbyte({dataname}.{i})
            ntiles: .db ntiles
            mode: .db MODE_REAL_NOT_CLICKBAIT
        .ENDST
        .DEFINE {spritename}.{i} (currid + i) EXPORT
    .ENDR
    .UNDEFINE MODE_REAL_NOT_CLICKBAIT
    .REDEFINE currid (currid + nframes)
.ENDM

.DefineSpriteSplit "sprite.enemy.attack_fly",\
    "spritedata.enemy_attack_fly", 1, 2,\
    SPRITEALLOCMODE_COMPRESSED_LZ4

.DefineSprite "sprite.item",\
    spritedata.items, 1, 255

.DefineSprite "sprite.item_pedastal",\
    spritedata.item_pedastal, 1, 1

.DefineSprite "sprite.shopkeepers",\
    spritedata.shopkeepers, 1, 8,\
    SPRITEALLOCMODE_COMPRESSED_LZ4

.DefineSprite "sprite.tilesprite_fire",\
    spritedata.tilesprite_fire, 1, 4,\
    SPRITEALLOCMODE_COMPRESSED_LZ4

.DefineSprite "sprite.familiar.brother_bobby",\
    spritedata.familiar.brother_bobby, 5, 1,\
    SPRITEALLOCMODE_SWIZZLE | SPRITEALLOCMODE_COMPRESSED_LZ4

.DefineSprite "sprite.enemy.isaac_cube",\
    spritedata.enemy.isaac_cube, 24, 1,\
    SPRITEALLOCMODE_SWIZZLE | SPRITEALLOCMODE_COMPRESSED_LZ4

.ENDS