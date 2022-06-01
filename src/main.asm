.include "base.inc"

.BANK $00 SLOT "ROM"
.ORG $0000
.SECTION "START" FORCE

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
.SECTION "MainCode" FREE

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
    PEA $C000 + bankbyte(palettes@isaac.w)
    PEA palettes@isaac.w
    jsl CopyPalette
    rep #$20 ; 16 bit A
    PLA
    PLA
    PEA $D000 + bankbyte(palettes@tear.w)
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
    PEA $1000 + bankbyte(palettes@basement2.w)
    PEA palettes@basement2.w
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
    lda.l TileData.w,x
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
    ; show sprites and BG2 on main screen
    lda #%00010011
    sta SCRNDESTM
    ; show BG1 on sub screen
    lda #%00000001
    sta SCRNDESTS
    ; Setup color math and windowing
    lda #%00000010
    sta CGWSEL
    lda #%01110111
    sta CGADSUB
    lda #%00000001
    sta SCRNDESTMW
    stz SCRNDESTSW
    stz WH0
    lda #$80
    sta WH1
    sta WH2
    lda #$FF
    sta WH3
    stz W34SEL
    stz WOBJSEL
    lda #%00001011
    sta W12SEL
    ; re-enable rendering
    lda #%00001111
    sta $2100
    cli ; Enable interrupts and joypad
    lda #$81
    sta $4200
    lda #$E0
    sta BG2VOFS
    lda #$FF
    sta BG2VOFS
    rep #$30
    jsl RngGameInitialize
    jsr PlayerInit
    jsl ClearVQueue
    jmp UpdateLoop

UpdateLoop:
    rep #$30 ; 16 bit AXY
    inc.w is_game_update_running
    ; Actual update code
    ; First, clear sprite data (will eventually make this better)
    .InitializeObjectIndices
    lda #EmptySpriteData
    sta DMA0_SRCL
    lda #512+32
    sta DMA0_SIZE
    lda #objectData
    sta WMADDL
    sep #$30 ; 8b AXY
    lda #bankbyte(EmptySpriteData)
    sta DMA0_SRCH
    stz WMADDH
    stz DMA0_CTL ; abs addr, inc addr, 1B
    lda #$80
    sta DMA0_DEST
    lda #$01
    sta MDMAEN
    jsr PlayerUpdate
    jsr UpdateTears
    jsr UpdateRest
    ; End update code
    rep #$30 ; 16 bit AXY
    stz.w is_game_update_running
    wai
    jmp UpdateLoop

UpdateRest:
    rep #$30 ; 16 bit AXY
    lda.w joy1press
    BIT #JOY_SELECT
    beq @skip_regenerate_map
    jsl BeginMapGeneration
    sep #$30 ; 8 bit AXY
    lda #0
    pha
    jsl LoadRoomSlotIntoLevel
    sep #$30 ; 8 bit AXY
    pla
@skip_regenerate_map:
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
    ldx.w joy1raw
    lda $4218
    sta.w joy1raw
    txa
    eor.w joy1raw
    and.w joy1raw
    sta.w joy1press
    txa
    and.w joy1raw
    sta.w joy1held
    ; Not worried about controller validity for now

    sep #$30 ; 8 bit AXY
    rts

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

.ENDS

.BANK $00 SLOT "ROM"
.SECTION "MainCodeData" FREE

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
