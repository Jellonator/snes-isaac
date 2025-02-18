.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "Snes_Init" SEMIFREE
Init:
    sep #$30  ; X,Y,A are 8 bit numbers
    lda #$8F  ; screen off, full brightness
    sta $2100 ; brightness + screen enable register 
    stz $2101 ; Sprite register (size + address in VRAM) 
    stz $2102 ; Sprite registers (address of sprite memory [OAM])
    stz $2103 ;    ""                       ""
    stz $2105 ; Mode 0, = Graphic mode register
    stz $2106 ; noplanes, no mosaic, = Mosaic register
    stz $2107 ; Plane 0 map VRAM location
    stz $2108 ; Plane 1 map VRAM location
    stz $2109 ; Plane 2 map VRAM location
    stz $210A ; Plane 3 map VRAM location
    stz $210B ; Plane 0+1 Tile data location
    stz $210C ; Plane 2+3 Tile data location
    stz $210D ; Plane 0 scroll x (first 8 bits)
    stz $210D ; Plane 0 scroll x (last 3 bits) #$0 - #$07ff
    lda #$FF  ; The top pixel drawn on the screen isn't the top one in the tilemap, it's the one above that.
    sta $210E ; Plane 0 scroll y (first 8 bits)
    sta $2110 ; Plane 1 scroll y (first 8 bits)
    sta $2112 ; Plane 2 scroll y (first 8 bits)
    sta $2114 ; Plane 3 scroll y (first 8 bits)
    lda #$07  ; Since this could get quite annoying, it's better to edit the scrolling registers to fix this.
    sta $210E ; Plane 0 scroll y (last 3 bits) #$0 - #$07ff
    sta $2110 ; Plane 1 scroll y (last 3 bits) #$0 - #$07ff
    sta $2112 ; Plane 2 scroll y (last 3 bits) #$0 - #$07ff
    sta $2114 ; Plane 3 scroll y (last 3 bits) #$0 - #$07ff
    stz $210F ; Plane 1 scroll x (first 8 bits)
    stz $210F ; Plane 1 scroll x (last 3 bits) #$0 - #$07ff
    stz $2111 ; Plane 2 scroll x (first 8 bits)
    stz $2111 ; Plane 2 scroll x (last 3 bits) #$0 - #$07ff
    stz $2113 ; Plane 3 scroll x (first 8 bits)
    stz $2113 ; Plane 3 scroll x (last 3 bits) #$0 - #$07ff
    lda #$80  ; increase VRAM address after writing to $2119
    sta $2115 ; VRAM address increment register
    stz $2116 ; VRAM address low
    stz $2117 ; VRAM address high
    stz $211A ; Initial Mode 7 setting register
    stz $211B ; Mode 7 matrix parameter A register (low)
    lda #$01
    sta $211B ; Mode 7 matrix parameter A register (high)
    stz $211C ; Mode 7 matrix parameter B register (low)
    stz $211C ; Mode 7 matrix parameter B register (high)
    stz $211D ; Mode 7 matrix parameter C register (low)
    stz $211D ; Mode 7 matrix parameter C register (high)
    stz $211E ; Mode 7 matrix parameter D register (low)
    sta $211E ; Mode 7 matrix parameter D register (high)
    stz $211F ; Mode 7 center position X register (low)
    stz $211F ; Mode 7 center position X register (high)
    stz $2120 ; Mode 7 center position Y register (low)
    stz $2120 ; Mode 7 center position Y register (high)
    stz $2121 ; Color number register ($0-ff)
    stz $2123 ; BG1 & BG2 Window mask setting register
    stz $2124 ; BG3 & BG4 Window mask setting register
    stz $2125 ; OBJ & Color Window mask setting register
    stz $2126 ; Window 1 left position register
    stz $2127 ; Window 2 left position register
    stz $2128 ; Window 3 left position register
    stz $2129 ; Window 4 left position register
    stz $212A ; BG1, BG2, BG3, BG4 Window Logic register
    stz $212B ; OBJ, Color Window Logic Register (or,and,xor,xnor)
    sta $212C ; Main Screen designation (planes, sprites enable)
    stz $212D ; Sub Screen designation
    stz $212E ; Window mask for Main Screen
    stz $212F ; Window mask for Sub Screen
    lda #$30
    sta $2130 ; Color addition & screen addition init setting
    stz $2131 ; Add/Sub sub designation for screen, sprite, color
    lda #$E0
    sta $2132 ; color data for addition/subtraction
    stz $2133 ; Screen setting (interlace x,y/enable SFX data)
    stz $4200 ; Enable V-blank, interrupt, Joypad register
    lda #$FF
    sta $4201 ; Programmable I/O port
    stz $4202 ; Multiplicand A
    stz $4203 ; Multiplier B
    stz $4204 ; Multiplier C
    stz $4205 ; Multiplicand C
    stz $4206 ; Divisor B
    stz $4207 ; Horizontal Count Timer
    stz $4208 ; Horizontal Count Timer MSB (most significant bit)
    stz $4209 ; Vertical Count Timer
    stz $420A ; Vertical Count Timer MSB
    stz $420B ; General DMA enable (bits 0-7)
    stz $420C ; Horizontal DMA (HDMA) enable (bits 0-7)
    stz $420D ; Access cycle designation (slow/fast rom)
    rtl
.ends

.SNESNATIVEVECTOR
    COP EmptyHandler
    BRK EmptyHandler
    ABORT EmptyHandler
    NMI VBlank
    IRQ EmptyHandler
.ENDNATIVEVECTOR

.SNESEMUVECTOR
    COP EmptyHandler
    ABORT EmptyHandler
    NMI EmptyHandler
    RESET Start
    IRQBRK EmptyHandler
.ENDEMUVECTOR

.SECTION "InitVector" BANK ROMBANK_BASE SLOT "ROM" ORGA $8000 SEMIFREE

EmptyHandler:
    rti

Start:
    ; Disabled interrupts
    sei
    ; Change to native mode
    clc
    xce
    ; Binary mode (decimal mode off), X/Y 16 bit
    rep #$18
    ; set stack to $1FFF
    ldx #$1FFF
    txs
    ; Initialize registers
    jsl Init
    lda #$01
    sta MEMSEL
    jml Start2

.ENDS

.BANK $01 SLOT "ROM"
.SECTION "InitMain" FREE

Start2:
    ; Disable rendering temporarily
    sep #$20
    lda #%10000000
    sta INIDISP
    ; Set tilemap mode 2
    lda #%00100001
    sta BGMODE
    lda #(BG1_TILE_BASE_ADDR >> 8) | %00
    sta BG1SC
    lda #(BG2_TILE_BASE_ADDR >> 8) | %00
    sta BG2SC
    lda #(BG3_TILE_BASE_ADDR >> 8) | %00
    sta BG3SC
    lda #(BG1_CHARACTER_BASE_ADDR >> 12) | (BG2_CHARACTER_BASE_ADDR >> 8)
    sta BG12NBA
    lda #(BG3_CHARACTER_BASE_ADDR >> 12)
    sta BG34NBA
    ; Set up sprite mode
    lda #%00000000 | (SPRITE1_BASE_ADDR >> 13) | ((SPRITE2_BASE_ADDR - SPRITE1_BASE_ADDR - $1000) >> 9)
    sta OBSEL
    ; copy palettes to CGRAM
    pea 32
    PEA $5000 + bankbyte(palettes.ui_light.w)
    PEA palettes.ui_light.w
    jsl CopyPalette
    rep #$20 ; 16 bit A
    PLA
    PLA
    PEA $6000 + bankbyte(palettes.ui_gold.w)
    PEA palettes.ui_gold.w
    jsl CopyPalette
    rep #$20 ; 16 bit A
    PLA
    PLA
    PEA $4000 + bankbyte(palettes.item_inactive.w)
    PEA palettes.item_inactive.w
    jsl CopyPalette
    rep #$20 ; 16 bit A
    PLA
    PLA
    .REPT 8 INDEX i
        PEA $8000 + (i * $1000) + bankbyte(palettes.palette0.w)
        .IF i == 0 || i == 4
            PEA palettes.palette0.w
        .ELIF i == 7
            PEA palettes.red.w
        .ELSE
            PEA palettes.default.w
        .ENDIF
        jsl CopyPalette
        rep #$20 ; 16 bit A
        PLA
        PLA
    .ENDR
    pla
    ; copy UI to VRAM
    pea BG1_CHARACTER_BASE_ADDR
    pea 16*6
    sep #$20 ; 8 bit A
    lda #bankbyte(spritedata.UI)
    pha
    pea spritedata.UI
    jsl CopySprite
    sep #$20 ; 8 bit A
    pla
    rep #$20 ; 16 bit A
    pla
    pla
    pla
    ; copy font to VRAM
    pea BG1_CHARACTER_BASE_ADDR + 16*8*8*2
    pea 16*3
    sep #$20 ; 8 bit A
    lda #bankbyte(spritedata.UI_font)
    pha
    pea spritedata.UI_font
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
    lda #bankbyte(spritedata.UI_numbers)
    pha
    pea spritedata.UI_numbers
    jsl CopySprite
    sep #$20 ; 8 bit A
    pla
    rep #$20 ; 16 bit A
    pla
    pla
    pla
    ; copy tear to VRAM
    .REPT 6 INDEX i
        pea SPRITE1_BASE_ADDR + 16*32 + 256*i ; VRAM address
        pea 8 ; num tiles
        sep #$20 ; 8 bit A
        lda #bankbyte(spritedata.isaac_tear)
        pha
        pea spritedata.isaac_tear + 8*i*32 ; address
        jsl CopySprite
        sep #$20 ; 8 bit A
        pla
        rep #$20 ; 16 bit A
        pla
        pla
        pla
    .ENDR
    ; copy default sprites to VRAM
    pea SPRITE1_BASE_ADDR + 64*32 ; VRAM address
    pea 128
    sep #$20 ; 8 bit A
    lda #bankbyte(spritedata.default_sprites)
    pha
    pea spritedata.default_sprites ; address
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
    ; setup BG3 (background)
    jsl InitializeBackground
    ; Set up tilemap. First, write empty in all slots
    rep #$30 ; 16 bit X, Y, Z
    lda #BG2_TILE_BASE_ADDR
    sta VMADDR
    lda #$0020
    ldx #$0000
tile_map_loop:
    sta VMDATA
    inx
    cpx #$0400 ; overwrite entire tile map
    bne tile_map_loop

    ; now, copy data for room layout
    ; room is 16x12, game is 32x32
    lda #BG2_TILE_BASE_ADDR
    sta VMADDR
    ldx #$0000 ; rom tile data index
    ldy #$0000 ; vram tile data index
tile_data_loop:
    ; lda TileData.w,x
    ; sta $2118
    tya
    and #%0000000000111111
    cmp #32.w
    bcs tile_data_loop@copyzero
    lda.l EmptyRoomTiles,X
    inx
    inx
    jmp @store
@copyzero:
    lda #$0020
@store:
    sta VMDATA
    iny
    iny
    cpy #$0300 ; 32 * 12 tiles
    bne tile_data_loop
    sep #$30 ; 8 bit X, Y, Z
    ; show sprites and BG2 on main screen
    lda #%00010111
    sta SCRNDESTM
    ; show BG1 on sub screen
    lda #%11100100
    sta SCRNDESTS
    ; Setup color math and windowing
    lda #%00000010
    sta CGWSEL
    lda #%01110100
    sta CGADSUB
    stz SCRNDESTMW
    stz SCRNDESTSW
    stz W34SEL
    stz WOBJSEL
    lda #%00001011
    sta W12SEL
    ; Set background color
    sep #$20 ; 8 bit A
    stz CGADDR
    lda #lobyte(CLEAR_COLOR)
    sta CGDATA
    lda #hibyte(CLEAR_COLOR)
    sta CGDATA
    cli ; Enable interrupts and joypad
    lda #$81
    sta NMITIMEN
    lda #$E0
    sta BG2VOFS
    lda #$FF
    sta BG2VOFS
    stz BG3VOFS
    stz BG3VOFS
    rep #$30
    lda #0
    sta.l tickCounter
    ; init rng
    jsl RngGameInitialize
    ; init vqueue
    jsl ClearVQueue
    ; init overlay
    jsl Overlay.init
    ; init hashtables
    phb
    .ChangeDataBank bankbyte(spriteTableKey)
    jsl table_clear_sprite
    jsl spriteman_init
    plb
    jsl Palette.init_data
    ; Initialize other variables
    sep #$30
    lda #bankbyte(mapTileSlotTable)
    sta.b currentRoomTileTypeTableAddress+2
    sta.b currentRoomTileVariantTableAddress+2
    sta.b currentRoomRngAddress_Low+2
    sta.b currentRoomRngAddress_High+2
    sta.b mapDoorNorth+2
    sta.b mapDoorEast+2
    sta.b mapDoorSouth+2
    sta.b mapDoorWest+2
    rep #$30
    lda #0
    sta.w currentRoomGroundPalette
    lda #BG2_TILE_BASE_ADDR
    sta.w gameRoomBG2Offset
    stz.w gameRoomScrollX
    lda #-32
    sta.w gameRoomScrollY
    lda #1
    sta.w is_game_update_running
    ; clear entity table
    jsl EntityInfoInitialize
    ; clear pathfinding data
    jsl Pathing.Initialize
    ; clear ground data
    jsl GroundOpClear
    ; init player
    jsr PlayerInit
    ; init floor
    jsl Floor_Init
    ; re-enable rendering
    sep #$20
    lda #%00001111
    sta.w roomBrightness
    sta INIDISP
    stz.w is_game_update_running
    jmp UpdateLoop

.ENDS