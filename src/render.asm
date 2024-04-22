.include "base.inc"

.SECTION "RenderInterrupt" BANK ROMBANK_BASE SLOT "ROM" ORGA $8000 SEMIFREE

VBlank:
    jml VBlank2

.ENDS

.SECTION "RenderCode" BANK $01 SLOT "ROM" FREE

VBlank2:
    sei ; disable interrupts
    phb
    rep #$30 ; 16 bit AXY
    pha
    .ChangeDataBank $00
    lda.w is_game_update_running
    beq @continuevblank
    pla
    plb
    ; cli ; enable interrupts
    rti
@continuevblank:
    pla ; compensate for earlier pha
    inc.w is_game_update_running
    ; Since VBlank only actually executes while the game isn't updating, we
    ; don't have to worry about storing previous state here
    sep #$20 ; 8 bit A
    lda #%10000000
    sta INIDISP
    sep #$30 ; 16 bit AXY
    lda $4210

    ; reset sprites
    rep #$20 ; 16 bit A
    stz $2102
    lda #512+32
    sta DMA0_SIZE
    lda.w #objectData
    sta DMA0_SRCL
    sep #$20 ; 8 bit A
    lda #0
    sta DMA0_SRCH
    ; Absolute address, auto increment, 1 byte at a time
    lda #%00000000
    sta DMA0_CTL
    ; Write to OAM
    lda #$04
    sta DMA0_DEST
    lda #$01
    sta MDMAEN
    ; check if ground needs reloading
    sep #$20 ; 8 bit A
    lda.l needResetEntireGround
    beq @skipUpdateGround
        lda #0
        sta.l needResetEntireGround
        jsl InitializeBackground
@skipUpdateGround:
    ; Check if minimap needs updating
    sep #$20 ; 8 bit A
    lda.w numTilesToUpdate
    cmp #$FF
    bne @skipUpdateAllTiles
        stz.w numTilesToUpdate
        jsr UpdateEntireMinimap
@skipUpdateAllTiles:
    jsl ProcessVQueue
    sep #$20 ; 8 bit A
    pla ; compensate for phb earlier
    lda #%00001111
    sta INIDISP
    jsr ReadInput
    stz.w is_game_update_running
    cli ; enable interrupts
    rti

UpdateEntireMinimap:
    sep #$30 ; 8 bit AXY
    lda #$80
    sta $2115
    .REPT MAP_MAX_HEIGHT INDEX i
        rep #$30 ; 16 bit AXY
        lda #BG1_TILE_BASE_ADDR + i*32 + 32 - MAP_MAX_WIDTH
        sta VMADDR
        ldy #i*MAP_MAX_WIDTH
        jsr UpdateMinimapLine
    .ENDR
    rts

UpdateMinimapLine:
    .ACCU 16
    .INDEX 16
    .REPT MAP_MAX_WIDTH
        lda.w mapTileTypeTable,Y
        and #$00FF
        asl
        tax
        lda.l MapTiles,X
        cpy loadedRoomIndex
        bne +
        ORA #$0020
        +:
        sta VMDATA
        iny
    .ENDR
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
    ; TODO
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

InitializeBackground:
    ; write character data
    rep #$20 ; 16 bit A
    lda #24 * 16 * 8 * 2
    sta DMA0_SIZE ; number of bytes
    lda #loword(spritedata.basement_ground_base)
    sta DMA0_SRCL ; source address
    lda #BG3_CHARACTER_BASE_ADDR
    sta $2116 ; VRAM address
    sep #$20 ; 8 bit A
    lda #bankbyte(spritedata.basement_ground_base)
    sta DMA0_SRCH ; source bank
    lda #$80
    sta $2115 ; VRAM address increment flags
    lda #%00000001
    sta DMA0_CTL ; write to PPU, absolute address, auto increment, 2 bytes at a time
    lda #$18
    sta DMA0_DEST ; Write to VRAM
    lda #$01
    sta MDMAEN ; begin transfer
    ; tile data
    rep #$20 ; 16 bit A
    lda #_sizeof_DefaultBackgroundTileData
    sta DMA0_SIZE ; number of bytes
    lda #loword(DefaultBackgroundTileData)
    sta DMA0_SRCL ; source address
    lda #BG3_TILE_BASE_ADDR
    sta $2116 ; VRAM address
    sep #$20 ; 8 bit A
    lda #0
    sta.l needResetEntireGround
    lda #bankbyte(DefaultBackgroundTileData)
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

.ENDS
