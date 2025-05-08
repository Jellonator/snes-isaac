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
    .ChangeDataBank $80
    lda.w isGameUpdateRunning
    beq @continuevblank
    phx
    jsl Render.UpdateHDMA
    rep #$30
    plx
    pla
    plb
    rti
@continuevblank:
    pla ; compensate for earlier pha
    inc.w isGameUpdateRunning
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
; Process HDMA
    jsl Render.UpdateHDMA
    .ACCU 8
    lda.l hdmaWindowMainPositionActiveBufferId
    eor #1
    sta.l hdmaWindowMainPositionActiveBufferId
    lda.l hdmaWindowSubPositionActiveBufferId
    eor #1
    sta.l hdmaWindowSubPositionActiveBufferId
; end
    sep #$20 ; 8 bit A
    pla ; compensate for phb earlier
    lda.w roomBrightness
    sta INIDISP
    jsr ReadInput
    stz.w isGameUpdateRunning
    cli ; enable interrupts
    rti

Render.UpdateHDMA:
    rep #$30
    lda #%00000001 + ($0100*lobyte(WH0))
    sta.w DMA7_CTL
    lda #%00000001 + ($0100*lobyte(WH2))
    sta.w DMA6_CTL
    sep #$20
    ldx #loword(hdmaWindowMainPositionBuffer1)
    lda.l hdmaWindowMainPositionActiveBufferId
    beq +
        ldx #loword(hdmaWindowMainPositionBuffer2)
    +:
    stx.w DMA7_SRCL
    ldx #loword(hdmaWindowSubPositionBuffer1)
    lda.l hdmaWindowSubPositionActiveBufferId
    beq +
        ldx #loword(hdmaWindowSubPositionBuffer2)
    +:
    stx.w DMA6_SRCL
    lda #$7E
    sta.w DMA7_SRCH
    sta.w DMA6_SRCH
    lda #%11000000
    sta.w HDMAEN
    rtl

Render.ClearHDMA:
    sep #$30
    lda #0
    sta.l hdmaWindowMainPositionActiveBufferId
    sta.l hdmaWindowSubPositionActiveBufferId
    lda #1
    sta.l hdmaWindowMainPositionBuffer1
    sta.l hdmaWindowMainPositionBuffer2
    sta.l hdmaWindowSubPositionBuffer1
    sta.l hdmaWindowSubPositionBuffer2
    lda #127-6
    sta.l hdmaWindowMainPositionBuffer1+1
    sta.l hdmaWindowMainPositionBuffer2+1
    sta.l hdmaWindowSubPositionBuffer1+1
    sta.l hdmaWindowSubPositionBuffer2+1
    lda #128+6
    sta.l hdmaWindowMainPositionBuffer1+2
    sta.l hdmaWindowMainPositionBuffer2+2
    sta.l hdmaWindowSubPositionBuffer1+2
    sta.l hdmaWindowSubPositionBuffer2+2
    lda #0
    sta.l hdmaWindowMainPositionBuffer1+3
    sta.l hdmaWindowMainPositionBuffer2+3
    sta.l hdmaWindowSubPositionBuffer1+3
    sta.l hdmaWindowSubPositionBuffer2+3
    rtl

Render.HDMAEffect.Clear:
    sep #$20
    rep #$10
    ; get address of inactive table
    ldx #hdmaWindowMainPositionBuffer1
    lda.l hdmaWindowMainPositionActiveBufferId
    beq +
        ldx #hdmaWindowMainPositionBuffer2
    +:
    lda #0
    sta.l $7E0002,X
    sta.l $7E0003,X
    dec A
    sta.l $7E0001,X
    inc A
    inc A
    sta.l $7E0000,X
    rtl

; Set up HDMA Window main for brimstone firing to right
; Render.HDMAEffect.BrimstoneRight([s8]x, [s8]y)
; $04,S: Y
; $05,S: X
Render.HDMAEffect.BrimstoneRight:
    phb
    .ChangeDataBank $7E
    sep #$20
    rep #$10
    ; get address of inactive table
    ldx #hdmaWindowMainPositionBuffer1
    lda.w hdmaWindowMainPositionActiveBufferId
    beq +
        ldx #hdmaWindowMainPositionBuffer2
    +:
    ; line counts for Y offset
    lda 1+$04,S
    lsr
    sta.w $00*3 + 0,X
    lda 1+$04,S
    sec
    sbc.w $00*3 + 0,X
    sta.w $01*3 + 0,X
    ; line counts for main shape
    lda #1
    sta.w $09*3 + 0,X
    sta.w $02*3 + 0,X
    sta.w $03*3 + 0,X
    sta.w $07*3 + 0,X
    sta.w $08*3 + 0,X
    inc A
    sta.w $04*3 + 0,X
    sta.w $06*3 + 0,X
    inc A
    inc A
    sta.w $05*3 + 0,X
    ;
    lda #0
    sta.w $00*3 + 2,X ; RIGHT[0] = 0
    sta.w $01*3 + 2,X ; RIGHT[1] = 0
    sta.w $09*3 + 2,X ; RIGHT[9] = 0
    sta.w $0A*3 + 0,X ; LINES[10] = 0
    lda #$FF
    sta.w $00*3 + 1,X ; LEFT[0] = 255
    sta.w $01*3 + 1,X ; LEFT[0] = 255
    sta.w $09*3 + 1,X ; LEFT[0] = 255
    ; sta.l hdmaWindowMainPositionBuffer1 + 0*3 + 1
    lda #ROOM_RIGHT+8
    sta.w $02*3 + 2,X
    sta.w $03*3 + 2,X
    sta.w $04*3 + 2,X
    sta.w $05*3 + 2,X
    sta.w $06*3 + 2,X
    sta.w $07*3 + 2,X
    sta.w $08*3 + 2,X
    lda 1+$05,S
    sta.w $05*3 + 1,X
    inc A
    sta.w $04*3 + 1,X
    sta.w $06*3 + 1,X
    inc A
    sta.w $03*3 + 1,X
    sta.w $07*3 + 1,X
    inc A
    inc A
    sta.w $02*3 + 1,X
    sta.w $08*3 + 1,X
    plb
    rtl

; Set up HDMA Window main for brimstone firing to left
; Render.HDMAEffect.BrimstoneLeft([s8]x, [s8]y)
; $04,S: Y
; $05,S: X
Render.HDMAEffect.BrimstoneLeft:
    phb
    .ChangeDataBank $7E
    sep #$20
    rep #$10
    ; get address of inactive table
    ldx #hdmaWindowMainPositionBuffer1
    lda.w hdmaWindowMainPositionActiveBufferId
    beq +
        ldx #hdmaWindowMainPositionBuffer2
    +:
    ; line counts for Y offset
    lda 1+$04,S
    lsr
    sta.w $00*3 + 0,X
    lda 1+$04,S
    sec
    sbc.w $00*3 + 0,X
    sta.w $01*3 + 0,X
    ; line counts for main shape
    lda #1
    sta.w $09*3 + 0,X
    sta.w $02*3 + 0,X
    sta.w $03*3 + 0,X
    sta.w $07*3 + 0,X
    sta.w $08*3 + 0,X
    inc A
    sta.w $04*3 + 0,X
    sta.w $06*3 + 0,X
    inc A
    inc A
    sta.w $05*3 + 0,X
    ;
    lda #0
    sta.w $00*3 + 2,X ; RIGHT[0] = 0
    sta.w $01*3 + 2,X ; RIGHT[1] = 0
    sta.w $09*3 + 2,X ; RIGHT[9] = 0
    sta.w $0A*3 + 0,X ; LINES[10] = 0
    lda #$FF
    sta.w $00*3 + 1,X ; LEFT[0] = 255
    sta.w $01*3 + 1,X ; LEFT[0] = 255
    sta.w $09*3 + 1,X ; LEFT[0] = 255
    ; sta.l hdmaWindowMainPositionBuffer1 + 0*3 + 1
    lda #ROOM_LEFT-8
    sta.w $02*3 + 1,X
    sta.w $03*3 + 1,X
    sta.w $04*3 + 1,X
    sta.w $05*3 + 1,X
    sta.w $06*3 + 1,X
    sta.w $07*3 + 1,X
    sta.w $08*3 + 1,X
    lda 1+$05,S
    sta.w $05*3 + 2,X
    dec A
    sta.w $04*3 + 2,X
    sta.w $06*3 + 2,X
    dec A
    sta.w $03*3 + 2,X
    sta.w $07*3 + 2,X
    dec A
    dec A
    sta.w $02*3 + 2,X
    sta.w $08*3 + 2,X
    plb
    rtl

; Set up HDMA Window main for brimstone firing up
; Render.HDMAEffect.BrimstoneUp([s8]x, [s8]y)
; $04,S: Y
; $05,S: X
Render.HDMAEffect.BrimstoneUp:
    phb
    .ChangeDataBank $7E
    sep #$20
    rep #$10
    ; get address of inactive table
    ldx #hdmaWindowMainPositionBuffer1
    lda.w hdmaWindowMainPositionActiveBufferId
    beq +
        ldx #hdmaWindowMainPositionBuffer2
    +:
    ; line counts for Y offset
    lda #ROOM_TOP - 8
    sta.w $00*3 + 0,X ; LINES[0] = TOP
    lda 1+$04,S
    sec
    sbc #ROOM_TOP - 8
    lsr
    sta.w $01*3 + 0,X ; LINES[1] = floor((Y-TOP)/2)
    lda 1+$04,S
    sec
    sbc.w $01*3 + 0,X
    sbc #ROOM_TOP - 8
    sta.w $02*3 + 0,X ; LINES[2] = Y-floor((Y-TOP)/2)
    ;
    lda #0
    sta.w $07*3 + 0,X ; LINES[7] = 0
    sta.w $06*3 + 2,X ; RIGHT[4] = 0
    sta.w $00*3 + 2,X ; RIGHT[0] = 0
    ;
    inc A
    sta.w $04*3 + 0,X ; LINES[4] = 1
    sta.w $05*3 + 0,X ; LINES[5] = 1
    sta.w $06*3 + 0,X ; LINES[6] = 1
    ;
    inc A
    sta.w $03*3 + 0,X ; LINES[3] = 2
    ;
    lda #$FF
    sta.w $06*3 + 1,X ; LEFT[6] = 255
    sta.w $00*3 + 1,X ; LEFT[0] = 255
    ;
    lda 1+$05,S
    sta.w $01*3 + 1,X ; LEFT[1] = X
    sta.w $02*3 + 1,X ; LEFT[2] = X
    inc A
    sta.w $03*3 + 1,X ; LEFT[3] = X+1
    inc A
    sta.w $04*3 + 1,X ; LEFT[4] = X+2
    inc A
    inc A
    sta.w $05*3 + 1,X ; LEFT[5] = X+4
    inc A
    inc A
    inc A
    sta.w $05*3 + 2,X ; RIGHT[4] = X+7
    inc A
    inc A
    sta.w $04*3 + 2,X ; RIGHT[3] = X+9
    inc A
    sta.w $03*3 + 2,X ; RIGHT[2] = X+10
    inc A
    sta.w $02*3 + 2,X ; RIGHT[2] = X+11
    sta.w $01*3 + 2,X ; RIGHT[1] = X+11
    plb
    rtl

; Set up HDMA Window main for brimstone firing down
; Render.HDMAEffect.BrimstoneDown([s8]x, [s8]y)
; $04,S: Y
; $05,S: X
Render.HDMAEffect.BrimstoneDown:
    phb
    .ChangeDataBank $7E
    sep #$20
    rep #$10
    ; get address of inactive table
    ldx #hdmaWindowMainPositionBuffer1
    lda.w hdmaWindowMainPositionActiveBufferId
    beq +
        ldx #hdmaWindowMainPositionBuffer2
    +:
    ; line counts for Y offset
    lda 1+$04,S
    lsr
    sta.w $00*3 + 0,X ; LINES[0] = floor(Y/2)
    lda 1+$04,S
    sec
    sbc.w $00*3 + 0,X
    sta.w $01*3 + 0,X ; LINES[1] = ceil(Y/2)
    lda #ROOM_BOTTOM + 4
    sec
    sbc 1+$04,S
    lsr
    sta.w $05*3 + 0,X ; LINES[5] = (BOTTOM - Y)/2
    bcc +
        inc A
    +:
    sta.w $06*3 + 0,X ; LINES[6] = (BOTTOM - Y)/2
    ;
    lda #0
    sta.w $08*3 + 0,X ; LINES[8] = 0
    sta.w $00*3 + 2,X ; RIGHT[0] = 0
    sta.w $01*3 + 2,X ; RIGHT[1] = 0
    sta.w $07*3 + 2,X ; RIGHT[7] = 0
    inc A
    sta.w $02*3 + 0,X ; LINES[2] = 1
    sta.w $03*3 + 0,X ; LINES[3] = 1
    sta.w $07*3 + 0,X ; LINES[7] = 1
    inc A
    sta.w $04*3 + 0,X ; LINES[4] = 2
    ;
    lda #$FF
    sta.w $00*3 + 1,X ; LEFT[0] = 255
    sta.w $01*3 + 1,X ; LEFT[1] = 255
    sta.w $07*3 + 1,X ; LEFT[7] = 255
    ;
    lda 1+$05,S
    sta.w $05*3 + 1,X ; LEFT[5] = X
    sta.w $06*3 + 1,X ; LEFT[6] = X
    inc A
    sta.w $04*3 + 1,X ; LEFT[4] = X+1
    inc A
    sta.w $03*3 + 1,X ; LEFT[3] = X+2
    inc A
    inc A
    sta.w $02*3 + 1,X ; LEFT[2] = X+4
    inc A
    inc A
    inc A
    sta.w $02*3 + 2,X ; RIGHT[2] = X+7
    inc A
    inc A
    sta.w $03*3 + 2,X ; RIGHT[3] = X+9
    inc A
    sta.w $04*3 + 2,X ; RIGHT[4] = X+10
    inc A
    sta.w $05*3 + 2,X ; RIGHT[5] = X+11
    sta.w $06*3 + 2,X ; RIGHT[6] = X+11
    plb
    rtl

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
    sta.w DMA0_SIZE ; number of bytes
    lda $04,s
    sta.w DMA0_SRCL ; source address
    lda $09,s
    sta.w VMADDR ; VRAM address
    sep #$20 ; 8 bit A
    lda $06,s
    sta.w DMA0_SRCH ; source bank
    lda #$80
    sta.w VMAIN ; VRAM address increment flags
    lda #$01
    sta.w DMA0_CTL ; write to PPU, absolute address, auto increment, 2 bytes at a time
    lda #$18
    sta.w DMA0_DEST ; Write to VRAM
    lda #$01
    sta.w MDMAEN ; begin transfer
    rtl

; Copy data to VRAM
; push order:
;   vram address   [dw] $09
;   num bytes      [dw] $07
;   source bank    [db] $06
;   source address [dw] $04
CopyVMEM:
    rep #$20 ; 16 bit A
    lda $07,s
    sta.w DMA0_SIZE ; number of bytes
    lda $04,s
    sta.w DMA0_SRCL ; source address
    lda $09,s
    sta.w VMADDR ; VRAM address
    sep #$20 ; 8 bit A
    lda $06,s
    sta.w DMA0_SRCH ; source bank
    lda #$80
    sta.w VMAIN ; VRAM address increment flags
    lda #$01
    sta.w DMA0_CTL ; write to PPU, absolute address, auto increment, 2 bytes at a time
    lda #$18
    sta.w DMA0_DEST ; Write to VRAM
    lda #$01
    sta.w MDMAEN ; begin transfer
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
    sta VMAIN ; VRAM address increment flags
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
    sta.w DMA0_SIZE ; number of bytes
    lda #loword(DefaultUiData)
    sta.w DMA0_SRCL ; source address
    lda #BG1_TILE_BASE_ADDR
    sta.w VMADDR ; VRAM address
    sep #$20 ; 8 bit A
    lda #bankbyte(DefaultUiData)
    sta.w DMA0_SRCH ; source bank
    lda #$80
    sta.w VMAIN ; VRAM address increment flags
    lda #%00000001
    sta.w DMA0_CTL ; write to PPU, absolute address, auto increment, 2 bytes at a time
    lda #$18
    sta.w DMA0_DEST ; Write to VRAM
    lda #$01
    sta.w MDMAEN ; begin transfer
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

; Add entity 'A' to boss contributors list
; Assumes DB=$7E
BossBar.Add:
    sep #$30
    ldx.w boss_contributor_count
    sta.w boss_contributor_array,X
    inc.w boss_contributor_count
    lda #1
    sta.w boss_health_need_rerender
    rtl

; Remove entity 'A' from boss contributors list
; Assumes DB = $7E
BossBar.Remove:
    sep #$30
    ldx.w boss_contributor_count
    txy
@loop:
    dex
    bmi @end
    cmp.w boss_contributor_array,X
    bne @loop
; found:
    lda.w boss_contributor_array,Y
    sta.w boss_contributor_array,X
    dey
    sty.w boss_contributor_count
    lda #1
    sta.w boss_health_need_rerender
@end:
    rtl

; Assumes DB=$7E
BossBar.ReRender:
    sep #$30
    lda #1
    sta.w boss_health_need_rerender
    rtl

_bossbar_no_contributors:
    ; clear boss bar
    rep #$30
    .VQueueOpToA
    tax
    inc.w vqueueNumOps
    inc.w vqueueNumOps
    lda #BG1_TILE_BASE_ADDR + textpos(6, 25)
    sta.l vqueueOps.1.vramAddr,X
    lda #BG1_TILE_BASE_ADDR + textpos(6, 26)
    sta.l vqueueOps.2.vramAddr,X
    lda #19*2
    sta.l vqueueOps.1.numBytes,X
    sta.l vqueueOps.2.numBytes,X
    sep #$20
    lda #VQUEUE_MODE_VRAM_CLEAR
    sta.l vqueueOps.1.mode,X
    sta.l vqueueOps.2.mode,X
    plb
    rtl

BossBar.Update:
    sep #$30
    ; check need re-render
    lda.l boss_health_need_rerender
    bne +
        rtl
    +:
    ; switch data bank
    phb
    .ChangeDataBank $7E
    stz.w boss_health_need_rerender
    ; check contributor cound
    ldx.w boss_contributor_count
    beq _bossbar_no_contributors
; sum health of all entities
    rep #$20
    ; $00,$01,$02 - health
    stz.b $02
    ; $04,$05,$06 - max health
    stz.b $06
    lda #0
@loop_sum_health:
    dex
    bmi @end_sum_health
    ldy.w boss_contributor_array,X
    clc
    adc.w entity_health,Y
    bcc +
        inc.b $02
    +:
    jmp @loop_sum_health
@end_sum_health:
    sta.b $00
    lda #0
    ldx.w boss_contributor_count
@loop_sum_health_max:
    dex
    bmi @end_sum_health_max
    ldy.w boss_contributor_array,X
    clc
    adc.w loword(entity_char_max_health),Y
    bcc +
        inc.b $06
    +:
    jmp @loop_sum_health_max
@end_sum_health_max:
    sta.b $04
    ; boss health bar is 16 tiles of 8 values each, for a total of 128 total values.
    ; we need: hp * 128 / (maxhp)
; shift values right until top byte of max health is empty
@loop_rot_right:
    lda.b $06
    beq @end_rot_right
    clc
    ror.b $06
    ror.b $04
    clc
    ror.b $02
    ror.b $00
    jmp @loop_rot_right
@end_rot_right:
; shift values left until top bit of max health is set
@loop_rot_left:
    lda.b $04
    bmi @end_rot_left
    asl.b $04
    asl.b $00
    jmp @loop_rot_left
@end_rot_left:
; divide
    lda.b $00
    sta.l DIVU_DIVIDEND
    sep #$20
    lda.b $05
    sta.l DIVU_DIVISOR
    .REPT 8
        nop
    .ENDR
    rep #$30
    lda.l DIVU_QUOTIENT ; A is now 256 * health / maxhealth
    lsr
    sta.b $00 ; $00 is now number of subtiles to set
; allocate bin
    lda.w vqueueBinOffset
    sec
    sbc #19*2*2
    sta.w vqueueBinOffset
    tax
; set borders
    lda #deft($D8, 5) | T_HIGHP
    sta.l $7F0000 + $00*2,X
    lda #deft($D9, 5) | T_HIGHP
    sta.l $7F0000 + $01*2,X
    lda #deft($E8, 5) | T_HIGHP
    sta.l $7F0026 + $00*2,X
    lda #deft($E9, 5) | T_HIGHP
    sta.l $7F0026 + $01*2,X
    ; end
    lda #deft($EB, 5) | T_HIGHP
    ldy.b $00
    cpy #128
    bcc +
        lda #deft($DB, 5) | T_HIGHP
    +:
    sta.l $7F0000 + $12*2,X
    eor #T_FLIPV
    sta.l $7F0026 + $12*2,X
; fill full tiles
    lda #16
    sta.b $02 ; $02 - remaining tiles
@loop_fill:
    lda.b $00
    cmp #8
    bcc @end_fill
    sec
    sbc #8
    sta.b $00
    lda #deft($DA, 5) | T_HIGHP
    sta.l $7F0004,X
    eor #T_FLIPV
    sta.l $7F002A,X
    dec.b $02
    beq @finalize ; no more tiles - so finish
    inx
    inx
    jmp @loop_fill
@end_fill:
; set midpoint tile
    lda #deft($C8, 5) | T_HIGHP
    clc
    adc.b $00
    sta.l $7F0004,X
    eor #T_FLIPV
    sta.l $7F002A,X
    inx
    inx
    dec.b $02
    beq @finalize
; clear remaining tiles
@loop_clear:
    lda #deft($EA, 5) | T_HIGHP
    sta.l $7F0004,X
    eor #T_FLIPV
    sta.l $7F002A,X
    dec.b $02
    beq @finalize
    inx
    inx
    jmp @loop_clear
@finalize:
; set up vqueue
    rep #$30
    .VQueueOpToA
    tax
    inc.w vqueueNumOps
    inc.w vqueueNumOps
    lda #BG1_TILE_BASE_ADDR + textpos(6, 25)
    sta.l vqueueOps.1.vramAddr,X
    lda #BG1_TILE_BASE_ADDR + textpos(6, 26)
    sta.l vqueueOps.2.vramAddr,X
    lda #19*2
    sta.l vqueueOps.1.numBytes,X
    sta.l vqueueOps.2.numBytes,X
    lda.w vqueueBinOffset
    sta.l vqueueOps.1.aAddr,X
    clc
    adc #19*2
    sta.l vqueueOps.2.aAddr,X
    sep #$20
    lda #VQUEUE_MODE_VRAM
    sta.l vqueueOps.1.mode,X
    sta.l vqueueOps.2.mode,X
    lda #$7F
    sta.l vqueueOps.1.aAddr+2,X
    sta.l vqueueOps.2.aAddr+2,X
; end
    plb
    rtl

.ENDS
