.include "base.inc"

; Definitions for sprites which are not uploaded manually to VRAM directly from ROM.
; This includes:
;  * static sprites which are only uploaded once when an entity loads (e.g. items)
;  * compressed sprites
;  * animated sprites which require swizzling

.SECTION "SpriteDefs" BANK ROMBANK_BASE SLOT "ROM" ORGA $8000 SEMIFREE

.DEFINE currid 1
SpriteDefs:
.db 0, 0, 0, 0

; Define a new sprite.
; spritename - the exported name of the sprite
;   baseaddr - the address of the sprite's data
;     ntiles - number of 16x16px tiles in one single frame
;    nframes - number of frames to export as separate sprites. These additional
;              sprites can be accessed as {spritename}.{frameid}, and their
;              address will be `baseaddr` + 128*{ntiles}*{frameid}
.MACRO .DefineSprite ARGS spritename, baseaddr, ntiles, nframes
    .DEFINE {spritename} currid
    .EXPORT {spritename}
    .REPT nframes INDEX i
        .DSTRUCT INSTANCEOF entityspriteinfo_t VALUES
            sprite_addr: .dw loword(baseaddr) + 128*ntiles*i ; 128b per 16x tile
            sprite_bank: .db bankbyte(baseaddr)
            ntiles: .db ntiles
        .ENDST
        .DEFINE {spritename}.{i} (currid + i)
        .EXPORT {spritename}.{i}
    .ENDR
    .REDEFINE currid (currid + nframes)
.ENDM

.DefineSprite "sprite.enemy.attack_fly", spritedata.enemy_attack_fly, 1, 2

.DefineSprite "sprite.item", spritedata.items, 1, 255

.DefineSprite "sprite.item_pedastal", spritedata.item_pedastal, 1, 1

.DefineSprite "sprite.shopkeepers", spritedata.shopkeepers, 1, 8

.DefineSprite "sprite.tilesprite_fire", spritedata.tilesprite_fire, 1, 4

.DefineSprite "sprite.familiar.brother_bobby", spritedata.familiar.brother_bobby, 5, 1

.ENDS