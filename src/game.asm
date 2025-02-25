.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "GAME" FREE

; Enter game
Game.Begin:
    .ChangeDataBank $00
    ; Disable rendering temporarily
    .DisableINT
    ; Disable interrupts
    .DisableRENDER
    ; reset all registers
    .ClearCPU
    ; Set tilemap mode 1
    lda #%00100001
    sta.w BGMODE
    lda #(BG1_TILE_BASE_ADDR >> 8) | %10
    sta.w BG1SC
    lda #(BG2_TILE_BASE_ADDR >> 8) | %00
    sta.w BG2SC
    lda #(BG3_TILE_BASE_ADDR >> 8) | %00
    sta.w BG3SC
    lda #(BG1_CHARACTER_BASE_ADDR >> 12) | (BG2_CHARACTER_BASE_ADDR >> 8)
    sta.w BG12NBA
    lda #(BG3_CHARACTER_BASE_ADDR >> 12)
    sta.w BG34NBA
    ; Set up sprite mode
    lda #%00000000 | (SPRITE1_BASE_ADDR >> 13) | ((SPRITE2_BASE_ADDR - SPRITE1_BASE_ADDR - $1000) >> 9)
    sta.w OBSEL
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
    pea 16*16
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
    jsl RNG.InitFromTimer
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
    stz.w isGamePaused
    stz.w shouldGamePause
    rep #$30
    lda #0
    stz.w gamePauseTimer
    sta.w currentRoomGroundPalette
    lda #BG2_TILE_BASE_ADDR
    sta.w gameRoomBG2Offset
    stz.w gameRoomScrollX
    lda #-32
    sta.w gameRoomScrollY
    lda #1
    sta.w isGameUpdateRunning
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
    ; Clear sprites
    rep #$30
    jsl ClearSpriteTable
    jsl UploadSpriteTable
    ; clear some render flags
    sep #$30
    lda #1
    sta.l needResetEntireGround
    lda #$FF
    sta.l numTilesToUpdate
    ; re-enable rendering
    rep #$20
    stz.w isGameUpdateRunning
    sep #$20
    lda #$00
    sta.w roomBrightness
    .EnableRENDER
    ; Set transition flag
    rep #$20
    lda #FLOOR_FLAG_FADEIN
    tsb.w floorFlags
    ; Enable interrupts and joypad
    .EnableINT
; GAME LOOP
_Game.Loop:
    ; update counter
    rep #$30 ; 16 bit AXY
    inc.w isGameUpdateRunning
    sep #$20
    lda.w isGamePaused
    bne @skip_paused
        rep #$20
        inc.w tickCounter
        ; clear data
        jsl ClearSpriteTable
        jsl entity_clear_hitboxes
        ; run one of the slow update functions, depending on current tick.
        ; We spread these out over multiple frames to reduce their frame impact.
        ; Each of these functions may take up to 20% of runtime each, and running
        ; them all simultaneously would kill performance. The couple frames of lag
        ; between updates is deemed acceptable.
        rep #$30
        lda.w tickCounter
        and #$03
        cmp #0
        beq @do_path_player
        cmp #1
        beq @do_path_enemy
        cmp #2
        beq @do_path_enemy_nearest
        jmp @end
        @do_path_player:
            jsl Pathing.UpdatePlayer
            jmp @end
        @do_path_enemy:
            jsl Pathing.UpdateEnemy
            jmp @end
        @do_path_enemy_nearest:
            jsl Pathing.UpdateEnemyNearest
        @end:
        ; run all update hooks
        jsl entity_refresh_hitboxes
        jsr PlayerUpdate
        jsl entity_tick_all
        jsl Room_Tick
        jsl Floor_Tick
        jsr _UpdateUsables
        ; Finally, check if room should be changed
        jsr PlayerCheckEnterRoom
@skip_paused:
    jsl GroundProcessOps
    jsl Overlay.update
; PAUSE CODE
    ; toggle pause
    sep #$30
    lda.w gamePauseTimer
    beq @can_toggle_pause
    cmp #32
    beq @can_toggle_pause
    jmp @skip_pause
@can_toggle_pause:
    lda.w joy1press+1
    bit #hibyte(JOY_START)
    beq @skip_pause
        lda.w shouldGamePause
        eor #$01
        sta.w shouldGamePause
        beq +
            ; begin pause
            jsr Pause.Begin
            sep #$30
            jmp @skip_pause
        +:
        jsr Pause.End
        sep #$30
@skip_pause:
    ; update pause timer
    lda.w shouldGamePause
    beq @unpause
        ; pausing
        lda.w gamePauseTimer
        cmp #32
        bcs +
            inc A
            sta.w gamePauseTimer
            jsr Pause.UpdateScroll
            sep #$30
        +:
        jmp @end_pause_timer
    @unpause:
        lda.w gamePauseTimer
        beq +
            dec A
            sta.w gamePauseTimer
            jsr Pause.UpdateScroll
            sep #$30
        +:
@end_pause_timer
    ; set pause flag
    stz.w isGamePaused
    lda.w gamePauseTimer
    beq +
        inc.w isGamePaused
        jsr Pause.Update
    +:
    ; End update code
    rep #$30 ; 16 bit AXY
    stz.w isGameUpdateRunning
    wai
    jmp _Game.Loop

_UpdateUsables:
    rep #$30 ; 16 bit AXY
    rep #$30
    lda.w joy1press
    bit #JOY_SELECT
    beq @skip_use_consumable
        jsl Consumable.use
@skip_use_consumable:
    rep #$30
    lda.w joy1press
    bit #JOY_R
    beq @skip_use_item
        jsl Item.try_use_active
@skip_use_item:
    rts

.DEFINE PAUSE_NUM_PAGES 2

_pause_pages:
    .dw Pause.PageMap
    .dw Pause.PageStats

Pause.Begin:
    sep #$20
    lda #0
    sta.w pausePage
    rep #$30
    and #$00FF
    asl
    tax
    jsr (_pause_pages,X)
    rts

Pause.PageStats:
; copy tile data into vqueue bin
    .CopyROMToVQueueBin P_IMM tilemap.pause_stat (32*32*2)
    rep #$30
    .VQueueOpToA
    tax
    inc.w vqueueNumOps
    lda.w vqueueBinOffset
    sta.l vqueueOps.1.aAddr,X
    lda #32*32*2
    sta.l vqueueOps.1.numBytes,X
    lda #BG1_TILE_BASE_ADDR + $0400
    sta.l vqueueOps.1.vramAddr,X
    sep #$20
    lda #$7F
    sta.l vqueueOps.1.aAddr+2,X
    lda #VQUEUE_MODE_VRAM
    sta.l vqueueOps.1.mode,X
; set speed stat text
    rep #$30
    lda.l playerData.stat_speed
    ; pixels per frame -> tiles per second: × 60/16 (estimate with multiply by 4)
    .MultiplyStatic 4
    sta.b $02
    sep #$30
    and #$00FF
    tax
    lda.l FractionBinToDec,X
    sta.b $00
    lda.b $03
    jsl ConvertBinaryToDecimalU8
    sta.b $01
    rep #$30
    ldx.w vqueueBinOffset
    ; char 3
    lda.b $00
    and #$000F
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(19, 8),X
    ; char 2
    lda.b $00
    and #$00F0
    .DivideStatic 16
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(18, 8),X
    ; char 1
    lda.b $01
    and #$000F
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(16, 8),X
    ; char 0
    lda.b $01
    and #$00F0
    .DivideStatic 16
    bne +
        lda #$2B
    +:
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(15, 8),X
    ; decimal
    lda #deft($24+TILE_TEXT_FONT_BASE, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(17, 8),X
; set damage stat text
    lda.w playerData.stat_damage
    jsl ConvertBinaryToDecimalU16
    sta.b $00
    ldy #0
    ; char 0
    lda.b $01
    and #$00F0
    .DivideStatic 16
    bne +
        ldy #1
        lda #$2B
    +:
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(16, 10),X
    ; char 1
    lda.b $01
    and #$000F
    bne +
        cpy #0
        beq +
        lda #$2B
        ldy #1
    +:
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(17, 10),X
    ; char 2
    lda.b $00
    and #$00F0
    .DivideStatic 16
    bne +
        cpy #0
        beq +
        lda #$2B
        ldy #1
    +:
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(18, 10),X
    ; char 3
    lda.b $00
    and #$000F
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(19, 10),X
; set tear rate text
    lda.l playerData.stat_tear_rate
    sta.b $02
    sep #$30
    and #$00FF
    tax
    lda.l FractionBinToDec,X
    sta.b $00
    lda.b $03
    jsl ConvertBinaryToDecimalU8
    sta.b $01
    rep #$30
    ldx.w vqueueBinOffset
    ; char 3
    lda.b $00
    and #$000F
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(19, 12),X
    ; char 2
    lda.b $00
    and #$00F0
    .DivideStatic 16
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(18, 12),X
    ; char 1
    lda.b $01
    and #$000F
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(16, 12),X
    ; char 0
    lda.b $01
    and #$00F0
    .DivideStatic 16
    bne +
        lda #$2B
    +:
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(15, 12),X
    ; decimal
    lda #deft($24+TILE_TEXT_FONT_BASE, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(17, 12),X
; set tear lifetime text
    lda.l playerData.stat_tear_lifetime
    .MultiplyStatic 256/4
    sta.l DIVU_DIVIDEND
    sep #$20
    lda #15
    sta.l DIVU_DIVISOR
    rep #$20
    rep #$20
    .REPT 5
        nop
    .ENDR
    lda.l DIVU_QUOTIENT
    sta.b $02
    sep #$30
    and #$00FF
    tax
    lda.l FractionBinToDec,X
    sta.b $00
    lda.b $03
    jsl ConvertBinaryToDecimalU8
    sta.b $01
    rep #$30
    ldx.w vqueueBinOffset
    ; char 3
    lda.b $00
    and #$000F
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(19, 14),X
    ; char 2
    lda.b $00
    and #$00F0
    .DivideStatic 16
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(18, 14),X
    ; char 1
    lda.b $01
    and #$000F
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(16, 14),X
    ; char 0
    lda.b $01
    and #$00F0
    .DivideStatic 16
    bne +
        lda #$2B
    +:
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(15, 14),X
    ; decimal
    lda #deft($24+TILE_TEXT_FONT_BASE, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(17, 14),X
; set tear speed text
    lda.l playerData.stat_tear_speed
    ; pixels per frame -> tiles per second: × 60/16 (estimate with multiply by 4)
    .MultiplyStatic 4
    sta.b $02
    sep #$30
    and #$00FF
    tax
    lda.l FractionBinToDec,X
    sta.b $00
    lda.b $03
    jsl ConvertBinaryToDecimalU8
    sta.b $01
    rep #$30
    ldx.w vqueueBinOffset
    ; char 3
    lda.b $00
    and #$000F
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(19, 16),X
    ; char 2
    lda.b $00
    and #$00F0
    .DivideStatic 16
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(18, 16),X
    ; char 1
    lda.b $01
    and #$000F
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(16, 16),X
    ; char 0
    lda.b $01
    and #$00F0
    .DivideStatic 16
    bne +
        lda #$2B
    +:
    clc
    adc #TILE_TEXT_FONT_BASE
    ora #deft(0, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(15, 16),X
    ; decimal
    lda #deft($24+TILE_TEXT_FONT_BASE, 6) | T_HIGHP
    sta.l $7F0000 + 2*textpos(17, 16),X
    jsr Pause.CopySeed
    rts

Pause.CopySeed:
; copy seed
    ldx.w vqueueBinOffset
    .REPT 8 INDEX i
        lda.w gameSeedStored + (i / 2)
        .IF (i # 2) == 0
            and #$000F
        .ELSE
            and #$00F0
            .DivideStatic 16
        .ENDIF
        clc
        adc #TILE_TEXT_FONT_BASE
        ora #deft(0, 6) | T_HIGHP
        sta.l $7F0000 + 2*textpos(21+i, 23),X
    .ENDR
    rts

Pause.PageMap:
; copy tile data into vqueue bin
    .CopyROMToVQueueBin P_IMM tilemap.pause_map (32*32*2)
    rep #$30
    .VQueueOpToA
    tax
    inc.w vqueueNumOps
    lda.w vqueueBinOffset
    sta.l vqueueOps.1.aAddr,X
    lda #32*32*2
    sta.l vqueueOps.1.numBytes,X
    lda #BG1_TILE_BASE_ADDR + $0400
    sta.l vqueueOps.1.vramAddr,X
    sep #$20
    lda #$7F
    sta.l vqueueOps.1.aAddr+2,X
    lda #VQUEUE_MODE_VRAM
    sta.l vqueueOps.1.mode,X
; display map
    rep #$30
    lda.w vqueueBinOffset
    clc
    adc #2*textpos(4, 8)
    tax
    ldy #0
    lda #16
    sta.b $10
@loop_map_y:
    lda #16
    sta.b $12
    @loop_map_x:
        phx
        jsl Map.GetTileValue
        bne +
            lda #deft($B1,6) | T_HIGHP
        +:
        plx
        sta.l $7F0000,X
        inx
        inx
        iny
        dec.b $12
        bne @loop_map_x
    txa
    clc
    adc #32
    tax
    dec.b $10
    bne @loop_map_y
    jsr Pause.CopySeed
    rts

Pause.End:
    rts

Pause.Update:
    rep #$30
    stz.b $00
    lda.w joy1press
    bit #JOY_L
    beq +
        sep #$20
        inc.b $00
        lda.w pausePage
        dec A
        bpl ++
            lda #PAUSE_NUM_PAGES-1
        ++:
        sta.w pausePage
        rep #$20
    +:
    lda.w joy1press
    bit #JOY_R
    beq +
        sep #$20
        inc.b $00
        lda.w pausePage
        inc A
        cmp #PAUSE_NUM_PAGES
        bcc ++
            lda #0
        ++:
        sta.w pausePage
        rep #$20
    +:
    lda.b $00
    beq +
        lda.w pausePage
        and #$00FF
        asl
        tax
        jsr (_pause_pages,X)
    +:
    rts

Pause.UpdateScroll:
    rep #$30
    lda.w gamePauseTimer
    and #$00FF
    asl
    asl
    asl
    sta.b $00
    lda.w vqueueNumRegOps
    inc.w vqueueNumRegOps
    inc.w vqueueNumRegOps
    asl
    tax
    lda #BG1VOFS
    sta.l vqueueRegOps_Addr,X
    sta.l vqueueRegOps_Addr+2,X
    lda.b $00
    sta.l vqueueRegOps_Value,X
    lda.b $01
    sta.l vqueueRegOps_Value+2,X
    rts

.ENDS