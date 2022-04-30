.include "Header.inc"
.include "Snes_Init.asm"

VBlank:
    RTI

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
    lda #%00000001
    sta $2105
    ; Set up sprite mode
    lda #%10000000
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
    ; copy sprite to VRAM
    rep #$20 ; 16 bit A
    lda #8192.w
    sta $4305
    lda #sprites@headtest.w
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
    ; only show sprites
    lda #$10
    sta $212c
    ; re-enable rendering
    lda #%00001111
    sta $2100
    cli ; Enable interrupts

Forever:
    jmp Forever

.ends

.bank 1
.section "Graphics"

.include "assets.inc"

.ends
