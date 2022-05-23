.include "base.inc"

.BANK $00 SLOT "ROM"
.SECTION "RENDER" FREE

; .MACRO .ResetSpriteExt
;     stz.w last_used_sprite
;     .REPT 32 INDEX i
;         stz.w sprite_data_ext+i
;     .ENDR
; .ENDM

VBlank:
    jml VBlank2
VBlank2:
    rep #$30 ; 16 bit AXY
    pha
    .ChangeDataBank $00
    lda.w is_game_update_running
    beq @continuevblank
    pla
    rti
@continuevblank:
    pla
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
    ; Check if minimap needs updating
    sep #$20 ; 8 bit A
    lda.w numTilesToUpdate
    cmp #$FF
    bne @skipUpdateAllTiles
    stz.w numTilesToUpdate
    jsr UpdateEntireMinimap
@skipUpdateAllTiles:
    sep #$20 ; 8 bit A
    lda #%00001111
    sta INIDISP
    jsr ReadInput
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
        sta VMDATA
        iny
    .ENDR
    rts

; DrawTears:
;     rep #$30 ; 16 bit mode
;     ldx.w tear_bytes_used
;     cpx #0
;     beq @end
; @iter:
;     sep #$20 ; 8 bit A, 16 bit X
;     lda.w tear_array.1.pos.x+1-_sizeof_tear_t,X
;     sta $2104
;     lda.w tear_array.1.pos.y+1-_sizeof_tear_t,X
;     sec
;     sbc #10
;     sta $2104
;     lda #$21
;     sta $2104
;     lda #%00101010
;     sta $2104
;     phx
;     jsl PushSpriteExtZero
;     rep #$30 ; 16 bit mode
;     pla
;     sec
;     sbc #_sizeof_tear_t
;     tax
;     bne @iter
; @end:
;     rts

; PushSpriteExtZero:
;     sep #$30 ; 8 bit axy
;     lda.w last_used_sprite
;     inc A
;     sta.w last_used_sprite
;     rtl

; PushSpriteExt:
;     sta $00
;     sep #$30 ; 8 bit axy
;     lda.w last_used_sprite
;     lsr
;     lsr
;     tax
;     lda.w last_used_sprite
;     bit #2
;     beq @skip2
;     .REPT 4
;         asl $00
;     .ENDR
; @skip2:
;     bit #1
;     beq @skip1
;     .REPT 2
;         asl $00
;     .ENDR 
; @skip1:
;     lda $00
;     ora.w sprite_data_ext,X
;     sta.w sprite_data_ext,X
;     lda.w last_used_sprite
;     inc A
;     sta.w last_used_sprite
;     rtl

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

.ENDS
