.include "base.inc"

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

.DefineSprite "enemy.attack_fly", sprites@enemy_attack_fly, 1, 2