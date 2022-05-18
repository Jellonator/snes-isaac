.include "Header.inc"
.include "Snes_Init.asm"
.include "defines.inc"
.include "structs.inc"
.include "layout.inc"
.include "util.inc"
.include "registers.inc"

.include "rng.inc"
.include "mapgenerator.inc"
.include "render.inc"

.BANK $00
.ORGA $8000
.SECTION "MainCode" FORCE

Start:
    sei ; Disabled interrupts
    Snes_Init
    lda #$01
    sta MEMSEL
    jml Start2

Start2:
    ; Disable rendering temporarily
    sep #$20
    lda #%10000000
    sta INIDISP
    ; Set tilemap mode 2
    lda #%00100001
    sta BGMODE
    lda #%00100100 ; BG1 tile data at $2400
    sta BG1SC
    lda #%00101000 ; BG2 tile data at $2800 (>>10)
    sta BG2SC
    lda #%00101100 ; BG3 tile data at $2C00
    sta BG3SC
    lda #%01010011 ; character data: BG1=$3000, BG2=$5000 (>>12)
    sta BG12NBA
    lda #%00000010 ; character data: BG3=$2000 (essentially $2000-$2400
                   ; for character data, but can technically access up to $4000)
    sta BG34NBA
    ; Set up sprite mode
    lda #%00000000
    sta OBSEL
    ; copy palettes to CGRAM
    PEA $8000 + bankbyte(palettes@isaac.w)
    PEA palettes@isaac.w
    jsl CopyPalette
    rep #$20 ; 16 bit A
    PLA
    PLA
    PEA $9000 + bankbyte(palettes@tear.w)
    PEA palettes@tear.w
    jsl CopyPalette
    rep #$20 ; 16 bit A
    PLA
    PLA
    PEA $0000 + bankbyte(palettes@basement.w)
    PEA palettes@basement.w
    jsl CopyPalette
    rep #$20 ; 16 bit A
    PLA
    PLA
    PEA $2000 + bankbyte(palettes@ui_light.w)
    PEA palettes@ui_light.w
    jsl CopyPalette
    rep #$20 ; 16 bit A
    PLA
    PLA
    PEA $3000 + bankbyte(palettes@ui_gold.w)
    PEA palettes@ui_gold.w
    jsl CopyPalette
    rep #$20 ; 16 bit A
    PLA
    PLA
    PEA $4000 + bankbyte(palettes@ui_dark.w)
    PEA palettes@ui_dark.w
    jsl CopyPalette
    rep #$20 ; 16 bit A
    PLA
    PLA
    ; Set background color
    sep #$20 ; 8 bit A
    stz $2121
    lda #%01100011
    sta $2122
    lda #%00001100
    sta $2122
    ; copy sprite to VRAM
    pea SPRITE1_BASE_ADDR
    pea 32
    sep #$20 ; 8 bit A
    lda #bankbyte(sprites@isaac_head)
    pha
    pea sprites@isaac_head
    jsl CopySprite
    sep #$20 ; 8 bit A
    pla
    rep #$20 ; 16 bit A
    pla
    pla
    pla
    ; copy tilemap to VRAM
    pea BG2_CHARACTER_BASE_ADDR
    pea 256
    sep #$20 ; 8 bit A
    lda #bankbyte(sprites@basement)
    pha
    pea sprites@basement
    jsl CopySprite
    sep #$20 ; 8 bit A
    pla
    rep #$20 ; 16 bit A
    pla
    pla
    pla
    ; copy UI to VRAM
    pea BG1_CHARACTER_BASE_ADDR
    pea 16*4
    sep #$20 ; 8 bit A
    lda #bankbyte(sprites@UI)
    pha
    pea sprites@UI
    jsl CopySprite
    sep #$20 ; 8 bit A
    pla
    rep #$20 ; 16 bit A
    pla
    pla
    pla
    ; copy font to VRAM
    pea BG1_CHARACTER_BASE_ADDR + 16*4*8*2
    pea 16*3
    sep #$20 ; 8 bit A
    lda #bankbyte(sprites@UI_font)
    pha
    pea sprites@UI_font
    jsl CopySprite
    sep #$20 ; 8 bit A
    pla
    rep #$20 ; 16 bit A
    pla
    pla
    pla
    ; copy UI numbers to VRAM
    pea BG1_CHARACTER_BASE_ADDR + 16*7*8*2
    pea 16*1
    sep #$20 ; 8 bit A
    lda #bankbyte(sprites@UI_numbers)
    pha
    pea sprites@UI_numbers
    jsl CopySprite
    sep #$20 ; 8 bit A
    pla
    rep #$20 ; 16 bit A
    pla
    pla
    pla
    ; copy tear to VRAM
    pea 16*32 ; VRAM address
    pea 4 ; num tiles
    sep #$20 ; 8 bit A
    lda #bankbyte(sprites@isaac_tear)
    pha
    pea sprites@isaac_tear ; address
    jsl CopySprite
    sep #$20 ; 8 bit A
    pla
    rep #$20 ; 16 bit A
    pla
    pla
    pla
    ; Clear BG1 (UI)
    pea BG1_TILE_BASE_ADDR
    pea 32*32*2
    jsl ClearVMem
    rep #$20 ; 16 bit A
    pla
    pla
    jsl InitializeUI
    ; Set up tilemap. First, write empty in all slots
    rep #$30 ; 16 bit X, Y, Z
    lda #BG2_TILE_BASE_ADDR
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
    lda #BG2_TILE_BASE_ADDR
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
    ; show sprites and BG1/BG2
    lda #%00010011
    sta SCRNDESTM
    ; re-enable rendering
    lda #%00001111
    sta $2100
    cli ; Enable interrupts and joypad
    lda #$81
    sta $4200
    lda #$E0
    sta $2110
    lda #$FF
    sta $2110
    rep #$30
    jsl RngGameInitialize
    jsr PlayerInit
    jmp UpdateLoop

UpdateLoop:
    wai
    rep #$30 ; 16 bit AXY
    inc is_game_update_running
    jsr PlayerUpdate
    jsr UpdateTears
    jsr UpdateRest
    rep #$30 ; 16 bit AXY
    stz is_game_update_running
    jmp UpdateLoop

UpdateRest:
    rep #$30 ; 16 bit AXY
    lda joy1press
    BIT #JOY_SELECT
    beq @skip_regenerate_map
    jsl BeginMapGeneration
@skip_regenerate_map:
    rts

PlayerInit:
    rep #$20 ; 16 bit A
    lda #24
    sta player.stat_accel
    lda #256
    sta player.stat_speed
    lda #24
    sta player.stat_tear_delay
    lda #$0100
    sta player.stat_tear_speed
    lda #0
    sta player.speed.x
    lda #0
    sta player.speed.y
    lda #((32 + 6 * 16 - 8) * 256)
    sta player.pos.x
    lda #((64 + 4 * 16 - 8) * 256)
    sta player.pos.y
    stz tear_bytes_used
    rts

ReadInput:
    ; loop until controller allows itself to be read
    rep #$20 ; 8 bit A
@read_input_loop:
    lda HVBJOY
    and #$01
    bne @read_input_loop ;0.14% -> 1.2%

    ; Read input
    rep #$30 ; 16 bit AXY
    ldx joy1raw
    lda $4218
    sta joy1raw
    txa
    eor joy1raw
    and joy1raw
    sta joy1press
    txa
    and joy1raw
    sta joy1held
    ; Not worried about controller validity for now

    sep #$30 ; 8 bit AXY
    rts

PlayerUpdate:
    rep #$30 ; 16 bit AXY

    lda player.stat_speed
    sta $00
    ; check (LEFT OR RIGHT) AND (UP OR DOWN)
    ; if so, multiply speed by 3/4; aka (A+A+A) >> 2
    lda joy1held
    ; LEFT or RIGHT. 00 = F; 01,10,11 = T
    bit #$0C00
    beq @skip_slow
    bit #$0300
    beq @skip_slow
    lda player.stat_speed
    asl
    clc
    adc $00
    lsr
    lsr
    sta $00
@skip_slow:

    ldx player.speed.y
    lda joy1held
    bit #JOY_DOWN
    bne @down
    bit #JOY_UP
    bne @up
    txa
    cmp #0
    bpl @slowup ; If speed.y > 0

    ; slowright
    clc
    adc player.stat_accel
    AMINI $00
    jmp @endy
@slowup:
    ; slowleft
    sec
    sbc player.stat_accel
    AMAXI $00
    jmp @endy
@down:
    ; right
    txa
    clc
    adc player.stat_accel
    AMIN $00
    jmp @endy
@up:
    ; left
    txa
    sec
    sbc player.stat_accel
    eor #$FFFF
    inc A
    AMIN $00
    eor #$FFFF
    inc A
@endy:
    sta player.speed.y
    
    ldx player.speed.x
    lda joy1held
    bit #JOY_RIGHT
    bne @right
    bit #JOY_LEFT
    bne @left
    ; X stop
    txa
    cmp #0
    bpl @slowleft ; If speed.x > 0

    ; slowright
    clc
    adc player.stat_accel
    AMINI $00
    jmp @endx
@slowleft:
    ; slowleft
    sec
    sbc player.stat_accel
    AMAXI $00
    jmp @endx
@right:
    ; right
    txa
    clc
    adc player.stat_accel
    AMIN $00
    jmp @endx
@left:
    ; left
    txa
    sec
    sbc player.stat_accel
    eor #$FFFF
    inc A
    AMIN $00
    eor #$FFFF
    inc A
@endx:
    sta player.speed.x

    ; apply speed
    lda player.pos.x
    clc
    adc player.speed.x
    AMAXUI (32 - 4)*256
    AMINUI (32 + 12*16 - 12)*256
    sta player.pos.x
    lda player.pos.y
    clc
    adc player.speed.y
    AMAXUI (64 - 4)*256
    AMINUI (64 + 8*16 - 12)*256
    sta player.pos.y
; handle player shoot
    lda player.tear_timer
    cmp player.stat_tear_delay ; if tear_timer < stat_tear_delay: ++tear_timer
    bcc @tear_not_ready
    ; check inputs
    lda joy1held
    bit #(JOY_A|JOY_B|JOY_Y|JOY_X)
    beq @end_tear_code
    jsr PlayerShootTear
    jmp @end_tear_code
@tear_not_ready:
    inc A
    sta player.tear_timer
@end_tear_code:
    sep #$30 ; 8 bit AXY
    rts

PlayerShootTear:
    rep #$30 ; 16 bit AXY
    jsr GetTearSlot
    lda player.flags
    eor #PLAYER_FLAG_EYE
    sta player.flags
    ; lda player.pos.x
    ; sta tear_array.1.pos.x,X
    ; lda player.pos.y
    ; sta tear_array.1.pos.y,X
    lda #90
    sta tear_array.1.lifetime,X
    stz tear_array.1.size,X
    lda #$0000
    sta player.tear_timer
    lda joy1held
    bit #JOY_Y
    bne @tear_left
    bit #JOY_A
    bne @tear_right
    bit #JOY_B
    bne @tear_down
;tear_up:
    lda player.speed.x
    sta tear_array.1.speed.x,X
    lda player.speed.y
    AMINI 64
    AMAXI -128
    sec
    sbc player.stat_tear_speed
    sta tear_array.1.speed.y,X
    jmp @vertical
@tear_left:
    lda player.speed.y
    sta tear_array.1.speed.y,X
    lda player.speed.x
    AMINI 64
    AMAXI -128
    sec
    sbc player.stat_tear_speed
    sta tear_array.1.speed.x,X
    jmp @horizontal
@tear_right:
    lda player.speed.y
    sta tear_array.1.speed.y,X
    lda player.speed.x
    AMAXI -64
    AMAXI 128
    clc
    adc player.stat_tear_speed
    sta tear_array.1.speed.x,X
    jmp @horizontal
@tear_down:
    lda player.speed.x
    sta tear_array.1.speed.x,X
    lda player.speed.y
    AMAXI -64
    AMAXI 128
    clc
    adc player.stat_tear_speed
    sta tear_array.1.speed.y,X
    jmp @vertical
@vertical:
    lda player.flags
    bit #PLAYER_FLAG_EYE
    bne @vertical_skip
    lda player.pos.x
    sta tear_array.1.pos.x,X
    lda player.pos.y
    clc
    adc #256*4
    sta tear_array.1.pos.y,X
    rts
@vertical_skip:
    lda player.pos.x
    clc
    adc #256*8
    sta tear_array.1.pos.x,X
    lda player.pos.y
    clc
    adc #256*4
    sta tear_array.1.pos.y,X
    rts
@horizontal:
    lda player.flags
    bit #PLAYER_FLAG_EYE
    bne @horizontal_skip
    lda player.pos.x
    clc
    adc #256*4
    sta tear_array.1.pos.x,X
    lda player.pos.y
    sta tear_array.1.pos.y,X
    rts
@horizontal_skip:
    lda player.pos.x
    clc
    adc #256*4
    sta tear_array.1.pos.x,X
    lda player.pos.y
    clc
    adc #256*8
    sta tear_array.1.pos.y,X
    rts

UpdateTears:
    rep #$30 ; 16 bit AXY
    ldx #$0000
    cpx tear_bytes_used
    beq @end
    jmp @iter
@iter_remove:
    jsr RemoveTearSlot
    ; No ++X, but do check that this is the end of the array
    cpx tear_bytes_used ; X != tear_bytes_used
    bcs @end
@iter:
    lda tear_array.1.lifetime,X
    dec A
    cmp #0 ; if lifetime == 0, then remove
    beq @iter_remove
    sta tear_array.1.lifetime,X
    lda tear_array.1.pos.x,X
    clc
    adc tear_array.1.speed.x,X
    sta tear_array.1.pos.x,X
    lda tear_array.1.pos.y,X
    clc
    adc tear_array.1.speed.y,X
    sta tear_array.1.pos.y,X
    txa ; ++X
    clc
    adc #_sizeof_tear_t
    tax
    cpx tear_bytes_used ; X < tear_bytes_used
    bcc @iter
@end:
    rts

; Get the next available tear slot, and store it in X
; if there are no available slots, the tear with the lowest life will be chosen
GetTearSlot:
    rep #$30 ; 16 bit AXY
    lda tear_bytes_used
    cmp #TEAR_ARRAY_MAX_SIZE
    bcc @has_empty_slots
; no empty slots available:
; find the slot with the lowest lifetime
    lda #$7FFF
    sta $00 ; $00 is best value
    ldx #0 ; x is current index
    ldy #0 ; Y is best index
@iter_tears:
    lda tear_array.1.lifetime,X
    cmp $00
    bcs @skip_store
    sta $00
    txy ; if tears[X].lifetime < tears[Y].lifetime: Y=X
@skip_store:
; ++X
    txa ; increment X
    clc
    adc #_sizeof_tear_t
    tax
; X < TEAR_ARRAY_MAX_SIZE
    cpx #TEAR_ARRAY_MAX_SIZE
    bcc @iter_tears
; Finish, transfer Y to X
    tyx
    rts
; empty slots available:
@has_empty_slots:
    tax
    clc
    adc #_sizeof_tear_t
    sta tear_bytes_used
    rts

; Remove the tear at the index X
; AXY must be 16bit
RemoveTearSlot:
    rep #$30 ; 16 bit AXY
    ; decrement number of used tears
    lda tear_bytes_used
    sec
    sbc #_sizeof_tear_t
    sta tear_bytes_used
    ; Check if X is the last available tear slot
    cpx tear_bytes_used
    beq @skip_copy
    ; copy last tear slot to slot being removed
    ldy tear_bytes_used
    lda tear_array+0,Y
    sta tear_array+0,X
    lda tear_array+2,Y
    sta tear_array+2,X
    lda tear_array+4,Y
    sta tear_array+4,X
    lda tear_array+6,Y
    sta tear_array+6,X
    lda tear_array+8,Y
    sta tear_array+8,X
    lda tear_array+10,Y
    sta tear_array+10,X
    lda tear_array+12,Y
    sta tear_array+12,X
    lda tear_array+14,Y
    sta tear_array+14,X
@skip_copy:
    rts

; Copy palette to CGRAM
; PUSH order:
;   palette index  [db] $07
;   source bank    [db] $06
;   source address [dw] $04
; MUST call with jsl
CopyPalette:
    rep #$20 ; 16 bit A
    lda $04,s
    sta $4302 ; source address
    lda #32.w
    sta $4305 ; 32 bytes for palette
    sep #$20 ; 8 bit A
    lda $06,s
    sta $4304 ; source bank
    lda $07,s
    sta $2121 ; destination is first sprite palette
    stz $4300 ; write to PPU, absolute address, auto increment, 1 byte at a time
    lda #$22
    sta $4301 ; Write to CGRAM
    lda #$01
    sta $420B ; Begin transfer
    rtl

; Copy sprite data to VRAM
; Use this method if the sprite occupies an entire row in width,
; or it is only 1 tile in height.
; push order:
;   vram address   [dw] $09
;   num tiles      [dw] $07
;   source bank    [db] $06
;   source address [dw] $04
; MUST call with jsl
CopySprite:
    rep #$20 ; 16 bit A
    lda $07,s
    asl ; multiply by 32 bytes per tile
    asl
    asl
    asl
    asl
    sta $4305 ; number of bytes
    lda $04,s
    sta $4302 ; source address
    lda $09,s
    sta $2116 ; VRAM address
    sep #$20 ; 8 bit A
    lda $06,s
    sta $4304 ; source bank
    lda #$80
    sta $2115 ; VRAM address increment flags
    lda #$01
    sta $4300 ; write to PPU, absolute address, auto increment, 2 bytes at a time
    lda #$18
    sta $4301 ; Write to VRAM
    lda #$01
    sta $420B ; begin transfer
    rtl

; Copy partial sprite data to VRAM.
; Use this method if the sprite occupies more than 1 tile height and does not
; occupy an entire sprite row in width.
; push order:
;   vram base index[dw]
;   num tiles width[db], must be 1-16
;   num tiles height[db], must be >1
;   source bank[db]
;   source address[dw]
; MUST call with jsl
CopySpritePartial:
    rep #$20
    rtl

; Clear a section of VRAM
; push order:
;   vram address [dw] $06
;   num bytes    [dw] $04
; MUST call with jsl
ClearVMem:
    rep #$20 ; 16 bit A
    lda $04,s
    sta DMA0_SIZE ; number of bytes
    lda #EmptyData
    sta DMA0_SRCL ; source address
    lda $06,s
    sta $2116 ; VRAM address
    sep #$20 ; 8 bit A
    lda #bankbyte(EmptyData)
    sta DMA0_SRCH ; source bank
    lda #$80
    sta $2115 ; VRAM address increment flags
    lda #%00001001
    sta DMA0_CTL ; write to PPU, absolute address, no increment, 2 bytes at a time
    lda #$18
    sta DMA0_DEST ; Write to VRAM
    lda #$01
    sta MDMAEN ; begin transfer
    rtl

; Clear a section of WRAM
; push order:
;   wram address [dw] $07
;   wram bank    [db] $06
;   num bytes    [dw] $04
; MUST call with jsl
ClearWRam:
    rep #$20 ; 16 bit A
    lda $04,s
    sta DMA0_SIZE
    lda #loword(EmptyData)
    sta DMA0_SRCL
    lda $07,s
    sta WMADDL
    sep #$20 ; 8 bit A
    lda #bankbyte(EmptyData)
    sta DMA0_SRCH
    lda $06,s
    sta WMADDH
    ; Absolute address, no increment, 1 byte at a time
    lda #%00001000
    sta DMA0_CTL
    ; Write to WRAM
    lda #$80
    sta DMA0_DEST
    lda #$01
    sta MDMAEN
    rtl

InitializeUI:
    rep #$20 ; 16 bit A
    lda #_sizeof_DefaultUiData
    sta DMA0_SIZE ; number of bytes
    lda #loword(DefaultUiData)
    sta DMA0_SRCL ; source address
    lda #BG1_TILE_BASE_ADDR
    sta $2116 ; VRAM address
    sep #$20 ; 8 bit A
    lda #bankbyte(DefaultUiData)
    sta DMA0_SRCH ; source bank
    lda #$80
    sta $2115 ; VRAM address increment flags
    lda #%00000001
    sta DMA0_CTL ; write to PPU, absolute address, auto increment, 2 bytes at a time
    lda #$18
    sta DMA0_DEST ; Write to VRAM
    lda #$01
    sta MDMAEN ; begin transfer
    rtl

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

.ENDS

.bank $40
.SECTION "Graphics"
.include "assets.inc"
.ENDS

.bank $41
.SECTION "ExtraData"
EmptyData:
    .dw $0000
EmptySpriteData:
    .REPT 128
        .db $00 $F0 $00 $00
    .ENDR
DefaultUiData:
    .dw $0000 $0C02 $0C03 $0C03 $4C02
    .dw $0C20 $0830 $0830 $0830 $0830 $0831 $0832
    .REPT 20
        .dw $0000
    .ENDR
    .dw $0000 $0C12 $0000 $0000 $4C12
    .dw $0C21 $0832 $0832 $0C30 $0C33 $0000 $0000
    .REPT 20
        .dw $0000
    .ENDR
    .dw $0000 $0C12 $0000 $0000 $4C12
    .dw $0C22
    .REPT 26
        .dw $0000
    .ENDR
    .dw $0000 $8C02 $8C03 $8C03 $CC02
    .dw $0000
    .REPT 26
        .dw $0000
    .ENDR
    @end:
MapTiles:
    .dw $0000 ; empty
    .dw $0C08 ; normal
    .dw $0C09 ; item
    .dw $0C0A ; boss
    .dw $0C0B ; shop
    .dw $080C ; sacrifice
    .dw $080D ; curse
    .dw $0C0E ; secret
.ENDS