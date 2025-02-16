.include "base.inc"

.SECTION "SpriteDefs" BANK ROMBANK_BASE SLOT "ROM" ORGA $8000 SEMIFREE

.DEFINE currid 1
SpriteDefs:
.MACRO .DefineSprite ARGS spritename, baseaddr, ntiles, nframes
    .DEFINE {spritename} currid
    .EXPORT {spritename}
    .REPT nframes INDEX i
        .DSTRUCT INSTANCEOF entityspriteinfo_t VALUES
            sprite_addr: .dw loword(baseaddr) + ntiles*i*128 ; 128b per 16x tile
            sprite_bank: .db bankbyte(baseaddr)
            nframes: .db nframes
        .ENDST
        .DEFINE {spritename}.{i} (currid + i)
        .EXPORT {spritename}.{i}
    .ENDR
    .REDEFINE currid (currid + nframes)
.ENDM

.DefineSprite "sprite.enemy.attack_fly", spritedata.enemy_attack_fly, 1, 2

.DefineSprite "sprite.enemy.zombie", spritedata.enemy_zombie, 1, 2

.DefineSprite "sprite.boss.monstro", spritedata.boss_monstro, 12, 1

.DefineSprite "sprite.item", spritedata.items, 1, 64

.DefineSprite "sprite.item_pedastal", spritedata.item_pedastal, 1, 1

.DefineSprite "sprite.shopkeepers", spritedata.shopkeepers, 1, 8

.DefineSprite "sprite.tilesprite_fire", spritedata.tilesprite_fire, 1, 8

.ENDS