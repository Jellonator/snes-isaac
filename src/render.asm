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
    lda RDNMI
; upload sprite data
    rep #$20 ; 16 bit A
    stz OAMADDR
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
; Force-load VRAM sections
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
; Process vqueue
    jsl ProcessVQueue
; end
    sep #$20 ; 8 bit A
    pla ; compensate for phb earlier
    lda.w roomBrightness
    sta INIDISP
    jsr ReadInput
    stz.w is_game_update_running
    cli ; enable interrupts
    rti

ClearSpriteTable:
    .ACCU 16
    .INDEX 16
    stz.w objectIndex
    lda #512
    sta.w objectIndexShadow
    .REPT 32/2 INDEX i
        stz.w objectDataExt + (i*2)
    .ENDR
    sep #$20
    lda #$F0
    .REPT 128 INDEX i
        sta.w objectData.{i+1}.pos_y
    .ENDR
    rtl

UploadSpriteTable:
    rep #$20 ; 16 bit A
    stz OAMADDR
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
    rtl

; Update the entire minimap
; NOTE: this requires blank to be enabled
; We assume that this will be performed during stage load.
; Just set numTilesToUpdate to $FF instead.
UpdateEntireMinimap:
    rep #$30 ; 16 bit AXY
    lda #$80
    sta $2115
    .REPT MAP_MAX_HEIGHT INDEX i
        lda #BG1_TILE_BASE_ADDR + i*32 + 32 - MAP_MAX_WIDTH
        sta VMADDR
        ldy #i*MAP_MAX_WIDTH
        jsr UpdateMinimapLine
    .ENDR
    rts

UpdateMinimapLine:
    .ACCU 16
    .INDEX 16
    .REPT MAP_MAX_WIDTH INDEX i
        jsr _get_tile_value
        sta VMDATA
        iny
    .ENDR
    rts

; Get tile value for tile Y
_get_tile_value:
    .INDEX 16
    .ACCU 16
    lda.w mapTileTypeTable,Y
    and #$00FF
    asl
    tax
    lda.l MapTiles,X
    sta.b $00
    beq @empty_tile
; modify value by flags
    lda.w mapTileFlagsTable,Y
    bit #MAPTILE_COMPLETED
    beq +
        lda #$0010
        ora.b $00
        sta.b $00
    +:
    lda.w mapTileFlagsTable,Y
    bit #MAPTILE_HAS_PLAYER
    beq +
        lda #$0020
        ora.b $00
        sta.b $00
    +:
    ; hide undiscovered rooms
    lda.w mapTileFlagsTable,Y
    bit #MAPTILE_DISCOVERED
    bne @tile_discovered
        ; always hide secret rooms
        lda.w mapTileTypeTable,Y
        and #$00FF
        cmp #ROOMTYPE_SECRET
        beq @no_map_no_compass
            lda.w playerData.playerItemStackNumber + ITEMID_MAP
            and #$00FF
            beq @no_map
                ; has map
                lda.w playerData.playerItemStackNumber + ITEMID_COMPASS
                and #$00FF
                bne @tile_discovered ; has map has compass - discover all rooms
                    ; has map no compass - all undiscovered rooms appear as normal rooms
                    lda #deft($08, 6) | T_HIGHP
                    sta.b $00
                    jmp @tile_discovered
            @no_map:
                ; no map
                lda.w playerData.playerItemStackNumber + ITEMID_COMPASS
                and #$00FF
                beq @no_map_no_compass ; no map no compass - don't discover any rooms
                    ; no map has compass - discover non-normal rooms
                    lda.w mapTileTypeTable,Y
                    cmp #ROOMTYPE_NORMAL+1
                    bcs @tile_discovered
        @no_map_no_compass:
        lda #$0000
        and.b $00
        sta.b $00
    @tile_discovered:
@empty_tile:
; set value
    lda.b $00
    rts

; Update minimap slot
; Args:
;    slot dw $04,S
UpdateMinimapSlot:
    rep #$30
; set VRAM address
    lda.w vqueueNumMiniOps
    asl
    asl
    tax
    inc.w vqueueNumMiniOps
    lda $04,S
    and #$0F
    sta.l vqueueMiniOps.1.vramAddr,X
    lda $04,S
    and #$F0
    asl
    clc
    adc #BG1_TILE_BASE_ADDR + 32 - MAP_MAX_WIDTH
    clc
    adc.l vqueueMiniOps.1.vramAddr,X
    sta.l vqueueMiniOps.1.vramAddr,X
; determine value
    phx ; PUSH vqueue address
    lda $04+2,S
    and #$00FF
    tay
    jsr _get_tile_value
    plx
    sta.l vqueueMiniOps.1.data,X
    rtl

; Copy palette to CGRAM
; PUSH order:
;   bytes          [dw] $08
;   palette index  [db] $07
;   source bank    [db] $06
;   source address [dw] $04
CopyPalette:
    rep #$20 ; 16 bit A
    lda $04,S
    sta $4302 ; source address
    lda $08,S
    sta $4305 ; 32 bytes for palette
    sep #$20 ; 8 bit A
    lda $06,S
    sta $4304 ; source bank
    lda $07,S
    sta $2121 ; destination is first sprite palette
    stz $4300 ; write to PPU, absolute address, auto increment, 1 byte at a time
    lda #$22
    sta $4301 ; Write to CGRAM
    lda #$01
    sta $420B ; Begin transfer
    rtl

; Copy palette to CGRAM via VQUEUE
; PUSH order:
;   bytes          [dw] $08
;   palette index  [db] $07
;   source bank    [db] $06
;   source address [dw] $04
CopyPaletteVQueue:
    rep #$30 ; 16 bit A
    .VQueueOpToA
    tax
    inc.w vqueueNumOps
    rep #$20 ; 16 bit A
    lda $04,S
    sta.l vqueueOps.1.aAddr,X; source address
    lda $08,S
    sta.l vqueueOps.1.numBytes,X ; 32 bytes for palette
    sep #$20 ; 8 bit A
    lda $06,S
    sta.l vqueueOps.1.aAddr+2,X ; source bank
    lda $07,S
    sta.l vqueueOps.1.vramAddr,X ; destination palette
    lda #VQUEUE_MODE_CGRAM
    sta.l vqueueOps.1.mode,X
    rtl

; Copy sprite data to VRAM
; Use this method if the sprite occupies an entire row in width,
; or it is only 1 tile in height.
; push order:
;   vram address   [dw] $09
;   num tiles      [dw] $07
;   source bank    [db] $06
;   source address [dw] $04
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

; Copy sprite data to VRAM via VQueue
; Use this method if the sprite occupies an entire row in width,
; or it is only 1 tile in height.
; push order:
;   vram address   [dw] $09
;   num tiles      [dw] $07
;   source bank    [db] $06
;   source address [dw] $04
CopySpriteVQueue:
    phb
    rep #$30 ; 16 bit A
    .VQueueOpToA
    tay
    inc.w vqueueNumOps
    lda 1+$07,S
    asl ; multiply by 32 bytes per tile
    asl
    asl
    asl
    asl
    .ChangeDataBank $7F
    sta.w loword(vqueueOps.1.numBytes),Y ; number of bytes
    lda 1+$04,S
    sta.w loword(vqueueOps.1.aAddr),Y ; source address
    lda 1+$09,S
    sta.w loword(vqueueOps.1.vramAddr),Y ; VRAM address
    sep #$20 ; 8 bit A
    lda 1+$06,S
    sta.w loword(vqueueOps.1.aAddr+2),Y ; source bank
    lda #VQUEUE_MODE_VRAM
    sta.w loword(vqueueOps.1.mode),Y
    plb
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
    sta.w DMA0_SIZE ; number of bytes
    lda.l currentRoomGroundData
    sta.w DMA0_SRCL ; source address
    lda #BG3_CHARACTER_BASE_ADDR
    sta.w VMADDR ; VRAM address
    sep #$20 ; 8 bit A
    lda.l currentRoomGroundData+2
    sta.w DMA0_SRCH ; source bank
    lda #$80
    sta.w VMAIN ; VRAM address increment flags
    lda #%00000001
    sta.w DMA0_CTL ; write to PPU, absolute address, auto increment, 2 bytes at a time
    lda #$18
    sta.w DMA0_DEST ; Write to VRAM
    lda #$01
    sta.w MDMAEN ; begin transfer
    ; tile data
    rep #$30 ; 16 bit A
    lda #BG3_TILE_BASE_ADDR
    sta.w VMADDR ; VRAM address
    sep #$20 ; 8 bit A
    lda #$80
    sta.w VMAIN ; VRAM address increment flags
    rep #$30
    ldy #32*32
    ldx #0
@loop:
    lda.l DefaultBackgroundTileData,X
    ora.w currentRoomGroundPalette
    sta.w VMDATA
    inx
    inx
    dey
    bne @loop
    rtl

.ENDS
