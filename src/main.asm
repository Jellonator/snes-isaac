.include "Header.inc"
.include "Snes_Init.asm"

.bank 0
.section "MainCode"

Start:
    sei ; Disabled interrupts
    Snes_Init
    ; Disable rendering temporarily
    sep #$20
    lda #%10000000
    sta $2100
    ; Set background color
    lda #%11100000
    sta $2122
    lda #%00000011
    sta $2122
    ; Set up tilemap mode
    lda #%00010001
    sta $2105
    lda #%01100000 ; tile data at $6000 (>>10)
    sta $2107
    lda #%00000100 ; tile character data at $4000 (>>12)
    sta $210B
    ; Set up sprite mode
    lda #%00000000
    sta $2101
    ; copy palette to CGRAM
    rep #$20 ; 16 bit A
    lda #32.w
    sta $4305 ; 32 bytes for palette
    lda #palettes@base.w
    sta $4302 ; source address
    sep #$20 ; 8 bit A
    lda #$01
    sta $4304 ; source bank
    lda #$80
    sta $2121 ; destination is first sprite palette
    stz $4300 ; write to PPU, absolute address, auto increment, 1 byte at a time
    lda #$22
    sta $4301 ; Write to CGRAM
    lda #$01
    sta $420B ; Begin transfer
    ; copy palette 2 to CGRAM
    rep #$20 ; 16 bit A
    lda #32.w
    sta $4305
    lda #palettes@basement.w
    sta $4302
    sep #$20 ; 8 bit A
    lda #$01
    sta $4304
    lda #$00
    sta $2121
    stz $4300
    lda #$22
    sta $4301
    lda #$01
    sta $420B
    ; copy sprite to VRAM
    rep #$20 ; 16 bit A
    lda #1024.w
    sta $4305
    lda #sprites@isaac.w
    sta $4302
    lda #$0000
    sta $2116
    sep #$20 ; 8 bit A
    lda #$01
    sta $4304
    lda #$80
    sta $2115
    lda #$01
    sta $4300 ; write to PPU, absolute address, auto increment, 2 bytes at a time
    lda #$18
    sta $4301
    lda #$01
    sta $420B
    ; copy tilemap to VRAM
    rep #$20 ; 16 bit A
    lda #8192.w
    sta $4305
    lda #sprites@basement.w
    sta $4302
    lda #$4000 ; put character data in $4000 of VRAM
    sta $2116
    sep #$20 ; 8 bit A
    lda #$01
    sta $4304
    lda #$80
    sta $2115
    lda #$01
    sta $4300
    lda #$18
    sta $4301
    lda #$01
    sta $420B

    ; Set up tilemap. First, write empty in all slots
    rep #$30 ; 16 bit X, Y, Z
    lda #$6000
    sta $2116
    lda #$0020
    ldx #$0000
tile_map_loop:
    sta $2118
    inx
    cpx #$0400 ; overwrite entire tile map
    bne tile_map_loop

    ; now, copy data for room layout
    ; room is 16x12, game is 32x32
    lda #$6000
    sta $2116
    ldx #$0000 ; rom tile data index
    ldy #$0000 ; vram tile data index
tile_data_loop:
    ; lda TileData.w,x
    ; sta $2118
    tya
    and #%0000000000111111
    cmp #32.w
    bcs tile_data_loop@copyzero
    lda TileData.w,x
    inx
    inx
    jmp @store
@copyzero:
    lda #$0020
@store:
    sta $2118
    iny
    iny
    cpy #$0300 ; 32 * 12 tiles
    bne tile_data_loop
    sep #$30 ; 8 bit X, Y, Z
    ; put a sprite in the center
    stz $2102
    stz $2103
    lda #120
    sta $2104
    lda #104
    sta $2104
    stz $2104
    stz $2104
    lda #120
    sta $2104
    lda #114
    sta $2104
    lda #$02
    sta $2104
    stz $2104
    ; show sprites and layer 1
    lda #$11
    sta $212c
    ; re-enable rendering
    lda #%00001111
    sta $2100
    cli ; Enable interrupts
    lda #$81
    sta $4200
    lda #120 ; Store X position
    sta $10
    lda #$E0
    sta $210E
    lda #$FF
    sta $210E
    jmp UpdateLoop

UpdateLoop:
    wai
    lda $10
    inc A
    sta $10
    jmp UpdateLoop

VBlank:
    lda $4210

    stz $2102
    stz $2103
    lda $10
    sta $2104
    lda #100
    sta $2104
    stz $2104
    lda #%00110000
    sta $2104
    lda $10
    sta $2104
    lda #110
    sta $2104
    lda #$02
    sta $2104
    lda #%00110000
    sta $2104

    sep #$10 ; 8 bit x
    ldx #2
    lda #240
clear_sprites_loop:
    stz $2104
    sta $2104
    stz $2104
    stz $2104
    INX
    cpx #128
    bne clear_sprites_loop
    lda #%00001010
    sta $2104

    RTI

TileData:
.dw $0002 $0004 $0004 $0004 $0004 $0004 $0004 $000C $000E $0004 $0004 $0004 $0004 $0004 $0004 $4002
.dw $0022 $0024 $0026 $0026 $0026 $0026 $0026 $002C $002E $0026 $0026 $0026 $0026 $0026 $4024 $4022
;              [                                                                       ]
.dw $0022 $0006 $0008 $000A $000A $000A $000A $000A $000A $000A $000A $000A $000A $4008 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0040 $0042 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4042 $4040
.dw $0060 $0062 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4062 $4060
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $8008 $800A $800A $800A $800A $800A $800A $800A $800A $800A $800A $C008 $4006 $4022
;              [                                                                       ]
.dw $0022 $8024 $8026 $8026 $8026 $8026 $8026 $802C $802E $8026 $8026 $8026 $8026 $8026 $C024 $4022
.dw $8002 $8004 $8004 $8004 $8004 $8004 $8004 $800C $800E $8004 $8004 $8004 $8004 $8004 $8004 $C002

.ends

.bank 1
.section "Graphics"

.include "assets.inc"

.ends
