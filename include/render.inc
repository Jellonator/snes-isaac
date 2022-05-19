.BANK 0 SLOT "ROM"
.SECTION "RENDER" FREE

.MACRO .ResetSpriteExt
    stz.w last_used_sprite
    .REPT 32 INDEX i
        stz.w sprite_data_ext+i
    .ENDR
.ENDM

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

    jsr ReadInput

    ; reset sprites
    .ResetSpriteExt

    ; Push player sprites
    sep #$30 ; 8 bit axy
    stz $2102
    stz $2103
    lda.w player.pos.x + 1
    sta $2104
    lda.w player.pos.y + 1
    sec
    sbc #10
    sta $2104
    stz $2104
    lda #%00100000
    sta $2104
    lda.w player.pos.x + 1
    sta $2104
    lda.w player.pos.y + 1
    sta $2104
    lda #$02
    sta $2104
    lda #%00100000
    sta $2104
    lda #2
    jsl PushSpriteExt
    lda #2
    jsl PushSpriteExt
    jsr DrawTears
    ; clear all sprites after last used sprite
    sep #$30 ; 8 bit axy
    lda.w last_used_sprite
    cpx #128
    beq @clear_sprites_end

    rep #$20 ; 16 bit A
    and #$FF
    asl
    asl
    sta $00
    lda #EmptySpriteData
    sta DMA0_SRCL
    lda #513 ; 512 - num_sprites*4
    clc
    sbc $00
    sta DMA0_SIZE 
    sep #$20 ; 8 bit A
    lda #bankbyte(EmptySpriteData)
    sta DMA0_SRCH ; source bank
    stz DMA0_CTL ; write to OAMRAM, absolute address, auto increment, 1 byte at a time
    lda #$04
    sta DMA0_DEST ; Write to OAMRAM
    lda #$01
    sta MDMAEN ; Begin transfer
@clear_sprites_end:
    ; copy ext data
    .REPT 32 INDEX i
        lda.w sprite_data_ext+i
        sta $2104
    .ENDR
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

DrawTears:
    rep #$30 ; 16 bit mode
    ldx.w tear_bytes_used
    cpx #0
    beq @end
@iter:
    sep #$20 ; 8 bit A, 16 bit X
    lda.w tear_array.1.pos.x+1-_sizeof_tear_t,X
    sta $2104
    lda.w tear_array.1.pos.y+1-_sizeof_tear_t,X
    sec
    sbc #10
    sta $2104
    lda #$21
    sta $2104
    lda #%00100010
    sta $2104
    phx
    jsl PushSpriteExtZero
    rep #$30 ; 16 bit mode
    pla
    sec
    sbc #_sizeof_tear_t
    tax
    bne @iter
@end:
    rts

PushSpriteExtZero:
    sep #$30 ; 8 bit axy
    lda.w last_used_sprite
    inc A
    sta.w last_used_sprite
    rtl

PushSpriteExt:
    sta $00
    sep #$30 ; 8 bit axy
    lda.w last_used_sprite
    lsr
    lsr
    tax
    lda.w last_used_sprite
    bit #2
    beq @skip2
    .REPT 4
        asl $00
    .ENDR
@skip2:
    bit #1
    beq @skip1
    .REPT 2
        asl $00
    .ENDR 
@skip1:
    lda $00
    ora.w sprite_data_ext,X
    sta.w sprite_data_ext,X
    lda.w last_used_sprite
    inc A
    sta.w last_used_sprite
    rtl

.ENDS
