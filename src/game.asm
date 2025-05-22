.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "GAME" FREE

; Enter game
Game.Begin:
    .ChangeDataBank $80
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
    PEA PALETTE_UI.0 + bankbyte(palettes.item_inactive.w)
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
    sta.w VMADDR
    lda #deft($08, 2)
    ldx #$0000
tile_map_loop:
    sta.w VMDATA
    inx
    cpx #$0400 ; overwrite entire tile map
    bne tile_map_loop

    ; now, copy data for room layout
    ; room is 16x12, game is 32x32
    lda #BG2_TILE_BASE_ADDR
    sta.w VMADDR
    ldx #$0000 ; rom tile data index
    ldy #$0000 ; vram tile data index
tile_data_loop:
    tya
    and #%0000000000111111
    cmp #32.w
    bcs tile_data_loop@copyzero
    lda.l EmptyRoomTiles,X
    inx
    inx
    jmp @store
@copyzero:
    lda #deft($08, 2)
@store:
    sta.w VMDATA
    iny
    iny
    cpy #$0300 ; 32 * 12 tiles
    bne tile_data_loop
    sep #$30 ; 8 bit X, Y, Z
    ; show sprites and BG2 on main screen
    lda #%00010111
    sta.w SCRNDESTM
    ; show BG1 on sub screen
    lda #%11100111
    sta.w SCRNDESTS
    ; Setup color math and windowing
    lda #%00000010
    sta.w CGWSEL
    lda #%01110100
    sta.w CGADSUB
    lda #%00010110
    sta.w SCRNDESTMW
    lda #%00011110
    sta.w SCRNDESTSW
    lda #%00100000
    sta.w W12SEL
    lda #%00000010
    sta.w W34SEL
    lda #%00000010
    sta.w WOBJSEL
    lda #%00111111
    sta.w COLDATA
    ; Set background color
    sep #$20 ; 8 bit A
    stz.w CGADDR
    lda #lobyte(CLEAR_COLOR)
    sta.w CGDATA
    lda #hibyte(CLEAR_COLOR)
    sta.w CGDATA
    lda #$E0
    sta.w BG2VOFS
    lda #$FF
    sta.w BG2VOFS
    stz.w BG3VOFS
    stz.w BG3VOFS
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
    stz.w isRoomTransitioning
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
    sep #$20
    lda.w loadFromSaveState
    beq @normal_load
    ; load save
        jsl MapGen.ClearAll
        sep #$20
        lda.w currentSaveSlot
        jsl Save.ReadSaveState
        sep #$30
        lda #ROOM_LOAD_CONTEXT_SAVELOAD
        pha
        lda.b currentRoomSlot
        pha
        tax
        lda.l roomSlotMapPos,X
        sta.b loadedRoomIndex
        jsl LoadAndInitRoomSlotIntoLevel
        rep #$20
        pla
        jsl Floor_Init_PostLoad
        jmp @end_load
    @normal_load:
    ; new game
        jsl Floor_Init
    @end_load:
    ; Clear sprites
    rep #$30
    jsl ClearSpriteTable
    jsl UploadSpriteTable
    ; clear some render flags
    sep #$30
    lda #1
    sta.l needResetEntireGround
    sta.l boss_health_need_rerender
    lda #0
    sta.l boss_contributor_count
    lda #$FF
    sta.l numTilesToUpdate
    stz.w didPlayerJustEnterRoom
    ; Clear HDMA table
    jsl Render.ClearHDMA
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
    stz.w didPlayerJustEnterRoom
    lda.w isGamePaused
    bne @skip_paused
        rep #$30
        inc.w tickCounter
        ; clear data
        jsl ClearSpriteTable
        jsl entity_clear_hitboxes
        jsl Render.HDMAEffect.Clear
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
        sep #$20
        lda.w didPlayerJustEnterRoom
        bne _Game.Loop
        ; Maybe Pause
        sep #$30
        lda.w joy1press+1
        bit #hibyte(JOY_START)
        beq @skip_paused
            lda #1
            sta.w shouldGamePause
            ; begin pause
            jsr Pause.Begin
@skip_paused:
    jsl GroundProcessOps
    jsl Overlay.update
    jsl BossBar.Update
    ; update pause timer
    sep #$30
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
    +:
    cmp #32
    bne +
        jsr Pause.Update
    +:
    ; End update code
    rep #$30 ; 16 bit AXY
    stz.w isGameUpdateRunning
    wai
    jmp _Game.Loop

Game.UpdateAllPathfinding:
    jsl Pathing.UpdatePlayer
    jsl Pathing.UpdateEnemy
    jsl Pathing.UpdateEnemyNearest
    rtl

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

.DEFINE PAUSE_NUM_SELECT 3

.DEFINE PAUSE_CHEAT_PAGE 2
.DEFINE PAUSE_CHEAT_ENTRY_LENGTH 10

.ENUM $0070
    cheatEntryIndex dw
    cheatActionSelect dw
    cheatParameterValue dw
.ENDE

_cheat_entry:
    .dw JOY_UP
    .dw JOY_UP
    .dw JOY_DOWN
    .dw JOY_DOWN
    .dw JOY_LEFT
    .dw JOY_RIGHT
    .dw JOY_LEFT
    .dw JOY_RIGHT
    .dw JOY_SELECT
    .dw JOY_START

_pause_pages:
    .dw Pause.PageMap
    .dw Pause.PageStats
    .dw Pause.PageCheat

_pause_actions:
    .dw Pause.ActionUnpause
    .dw Pause.ActionOptions
    .dw Pause.ActionExit

Pause.ActionUnpause:
    sep #$20
    stz.w shouldGamePause
    jsr Pause.End
    rts

Pause.ActionOptions:
    rts

Pause.ActionExit:
    jsl Room_Unload
    sep #$20
    lda.w currentSaveSlot
    jsl Save.WriteSaveState
    jml Menu.Begin

Pause.Begin:
    sep #$20
    lda #0
    sta.w pausePage
    sta.w pauseSelect
    rep #$30
    stz.b cheatEntryIndex
    and #$00FF
    asl
    tax
    jsr (_pause_pages,X)
; init indicator
    ; change indicator
    lda.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    asl
    asl
    tax
    lda #deft($AF, 6) | T_HIGHP
    sta.l vqueueMiniOps.1.data,X
    lda.w pauseSelect
    and #$00FF
    .MultiplyStatic 64
    clc
    adc #textpos(21, 8) + BG1_TILE_BASE_ADDR + $0400
    sta.l vqueueMiniOps.1.vramAddr,X
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
; Updates which are common to all pages
    ; check page change
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
        sep #$20
        lda #1
        sta.b $00
    +:
    ; check if we are on cheats page
    sep #$20
    lda.w pausePage
    cmp #PAUSE_CHEAT_PAGE
    bne +
        jmp _pause_update_cheats_page
    +:
; Updates that only occur on STATS and MAP
    ; check cheat entry
    rep #$30
    lda.b cheatEntryIndex
    asl
    tax
    lda.w joy1press
    beq @no_cheat_entry
    cmp.l _cheat_entry,X
    beq @inc_cheat_entry
        stz.b cheatEntryIndex
        jmp @no_cheat_entry
    @inc_cheat_entry:
        inc.b cheatEntryIndex
        lda.b cheatEntryIndex
        cmp #PAUSE_CHEAT_ENTRY_LENGTH
        bne @no_cheat_entry
        ; show cheat page
        stz.b cheatEntryIndex
        lda #PAUSE_CHEAT_PAGE
        sta.w pausePage
        asl
        tax
        jsr (_pause_pages,X)
        rts
@no_cheat_entry:
    ; check selection change
    sep #$20
    lda.w pauseSelect
    sta.b $02
    rep #$20
    lda.w joy1press
    bit #JOY_UP
    beq +
        sep #$20
        inc.b $00
        lda.w pauseSelect
        dec A
        bpl ++
            lda #PAUSE_NUM_SELECT-1
        ++:
        sta.w pauseSelect
        rep #$20
    +:
    lda.w joy1press
    bit #JOY_DOWN
    beq +
        sep #$20
        inc.b $00
        lda.w pauseSelect
        inc A
        cmp #PAUSE_NUM_SELECT
        bcc ++
            lda #0
        ++:
        sta.w pauseSelect
        rep #$20
    +:
    lda.b $00
    beq +
        ; change indicator
        lda.w vqueueNumMiniOps
        inc.w vqueueNumMiniOps
        inc.w vqueueNumMiniOps
        asl
        asl
        tax
        lda #deft($B1, 6) | T_HIGHP
        sta.l vqueueMiniOps.1.data,X
        lda #deft($AF, 6) | T_HIGHP
        sta.l vqueueMiniOps.2.data,X
        lda.b $02
        and #$00FF
        .MultiplyStatic 64
        clc
        adc #textpos(21, 8) + BG1_TILE_BASE_ADDR + $0400
        sta.l vqueueMiniOps.1.vramAddr,X
        lda.w pauseSelect
        and #$00FF
        .MultiplyStatic 64
        clc
        adc #textpos(21, 8) + BG1_TILE_BASE_ADDR + $0400
        sta.l vqueueMiniOps.2.vramAddr,X
    +:
    ; perform action
    rep #$20
    lda.w joy1press
    bit #JOY_A | JOY_START
    beq @skip_action
        lda.w pauseSelect
        and #$00FF
        asl
        tax
        jsr (_pause_actions,X)
@skip_action:
    rts

.DEFINE NUM_CHEAT_ACTIONS 8

_cheat_action_begin:
    .dw _cheat_action_begin_floor
    .dw _cheat_action_begin_room
    .dw _cheat_action_begin_item_give
    .dw _cheat_action_begin_item_remove
    .dw _cheat_action_begin_consumable_set
    .dw _cheat_action_begin_money
    .dw _cheat_action_begin_bombs
    .dw _cheat_action_begin_keys

_cheat_action_tick:
    .dw _cheat_action_tick_floor
    .dw _cheat_action_tick_room
    .dw _cheat_action_tick_item_give
    .dw _cheat_action_tick_item_remove
    .dw _cheat_action_tick_consumable_set
    .dw _cheat_action_tick_money
    .dw _cheat_action_tick_bombs
    .dw _cheat_action_tick_keys

Pause.PageCheat:
; copy tilemap
    .CopyROMToVQueueBin P_IMM tilemap.pause_cheat (32*32*2)
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
; set default values
    rep #$20
    stz.b cheatActionSelect
    jsr _cheat_action_begin_floor
    rts

_pause_update_cheats_page:
; exit if start is pressed
    rep #$20
    lda.w joy1press
    bit #JOY_START
    beq +
        jsr Pause.ActionUnpause
        rts
    +:
; swap actions
    ; check page change
    rep #$20
    lda.b cheatActionSelect
    sta.b $02
    stz.b $00
    lda.w joy1press
    bit #JOY_UP
    beq +
        sep #$20
        inc.b $00
        lda.b cheatActionSelect
        dec A
        bpl ++
            lda #NUM_CHEAT_ACTIONS-1
        ++:
        sta.b cheatActionSelect
        rep #$20
    +:
    lda.w joy1press
    bit #JOY_DOWN
    beq +
        sep #$20
        inc.b $00
        lda.b cheatActionSelect
        inc A
        cmp #NUM_CHEAT_ACTIONS
        bcc ++
            lda #0
        ++:
        sta.b cheatActionSelect
        rep #$20
    +:
    lda.b $00
    beq +
        ; put indicator
        lda.w vqueueNumMiniOps
        inc.w vqueueNumMiniOps
        inc.w vqueueNumMiniOps
        asl
        asl
        tax
        lda.b $02
        .MultiplyStatic 64
        clc
        adc #textpos(3, 40) + BG1_TILE_BASE_ADDR
        sta.l vqueueMiniOps.1.vramAddr
        lda #deft($B1, 6)
        sta.l vqueueMiniOps.1.data
        lda.b cheatActionSelect
        and #$00FF
        .MultiplyStatic 64
        clc
        adc #textpos(3, 40) + BG1_TILE_BASE_ADDR
        sta.l vqueueMiniOps.2.vramAddr
        lda #deft($AF, 6)
        sta.l vqueueMiniOps.2.data
        ; clear display
        jsr _cheat_clear_display
        ; begin action
        lda.b cheatActionSelect
        and #$00FF
        asl
        tax
        jsr (_cheat_action_begin,X)
        sep #$20
        lda #1
        sta.b $00
        rts
        .ACCU 16
    +:
    ; update action
    lda.b cheatActionSelect
    and #$00FF
    asl
    tax
    jsr (_cheat_action_tick,X)
; end
    rts

; write value in 'A' to number display
_cheat_write_decimal_view:
    rep #$30
    sta.b $00
    ; get vqueue op pointer
    lda.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    asl
    asl
    tax
    ; put characters
    .GetDecimalAsTilePause P_DIR, $00, 0
    sta.l vqueueMiniOps.1.data,X
    .GetDecimalAsTilePause P_DIR, $00, 1
    sta.l vqueueMiniOps.2.data,X
    .GetDecimalAsTilePause P_DIR, $00, 2
    sta.l vqueueMiniOps.3.data,X
    .GetDecimalAsTilePause P_DIR, $00, 3
    sta.l vqueueMiniOps.4.data,X
    lda #textpos(18, 40) + BG1_TILE_BASE_ADDR
    sta.l vqueueMiniOps.4.vramAddr,X
    inc A
    sta.l vqueueMiniOps.3.vramAddr,X
    inc A
    sta.l vqueueMiniOps.2.vramAddr,X
    inc A
    sta.l vqueueMiniOps.1.vramAddr,X
    rts

; write string in [$00] to string display
_cheat_write_text_view:
    rep #$30
    ; get ops
    lda.w vqueueBinOffset
    sec
    sbc #64
    sta.w vqueueBinOffset
    sta.b $04 ; [$04] - bin ptr
    lda #$7F
    sta.b $06
    .VQueueOpToA
    tax
    inc.w vqueueNumOps
    inc.w vqueueNumOps
    ; put data into vqueue
    lda #32
    sta.l vqueueOps.1.numBytes,X
    sta.l vqueueOps.2.numBytes,X
    lda.b $04
    sta.l vqueueOps.1.aAddr,X
    clc
    adc #32
    sta.l vqueueOps.2.aAddr,X
    lda #textpos(12, 42) + BG1_TILE_BASE_ADDR
    sta.l vqueueOps.1.vramAddr,X
    lda #textpos(12, 44) + BG1_TILE_BASE_ADDR
    sta.l vqueueOps.2.vramAddr,X
    sep #$20
    lda #$7F
    sta.l vqueueOps.1.aAddr+2,X
    sta.l vqueueOps.2.aAddr+2,X
    lda #VQUEUE_MODE_VRAM
    sta.l vqueueOps.1.mode,X
    sta.l vqueueOps.2.mode,X
    ; write text to vqueuebin
    rep #$30
    lda #32
    sta.b $08
    @loop:
        lda [$00]
        and #$00FF
        beq @loop_end
        ora #deft(0, 6) | T_HIGHP
        sta [$04]
        inc.b $00
        inc.b $04
        inc.b $04
        dec.b $08
        bne @loop
    @loop_end:
    ; write empty until full
    lda #deft($B1, 6) | T_HIGHP
    @loop_fill:
        sta [$04]
        inc.b $04
        inc.b $04
        dec.b $08
        bne @loop_fill
    rts

_cheat_clear_display:
    rep #$30
    ; get ops
    lda.w vqueueBinOffset
    sec
    sbc #32
    sta.w vqueueBinOffset
    sta.b $04 ; [$04] - bin ptr
    lda #$7F
    sta.b $06
    .VQueueOpToA
    tax
    inc.w vqueueNumOps
    inc.w vqueueNumOps
    inc.w vqueueNumOps
    ; put data into vqueue
    lda #32
    sta.l vqueueOps.1.numBytes,X
    sta.l vqueueOps.2.numBytes,X
    lda #8
    sta.l vqueueOps.3.numBytes,X
    lda.b $04
    sta.l vqueueOps.1.aAddr,X
    sta.l vqueueOps.2.aAddr,X
    sta.l vqueueOps.3.aAddr,X
    lda #textpos(12, 42) + BG1_TILE_BASE_ADDR
    sta.l vqueueOps.1.vramAddr,X
    lda #textpos(12, 44) + BG1_TILE_BASE_ADDR
    sta.l vqueueOps.2.vramAddr,X
    lda #textpos(18, 40) + BG1_TILE_BASE_ADDR
    sta.l vqueueOps.3.vramAddr,X
    sep #$20
    lda #$7F
    sta.l vqueueOps.1.aAddr+2,X
    sta.l vqueueOps.2.aAddr+2,X
    sta.l vqueueOps.3.aAddr+2,X
    lda #VQUEUE_MODE_VRAM
    sta.l vqueueOps.1.mode,X
    sta.l vqueueOps.2.mode,X
    sta.l vqueueOps.3.mode,X
    ; write text to vqueuebin
    rep #$30
    lda #16
    sta.b $08
    ; write empty until full
    lda #deft($B1, 6) | T_HIGHP
    @loop_fill:
        sta [$04]
        inc.b $04
        inc.b $04
        dec.b $08
        bne @loop_fill
    rts

; FLOOR

_cheat_action_begin_floor:
    rep #$20
; get and write current floor index
    lda.w currentFloorIndex
    sta.b cheatParameterValue
    jsl ConvertBinaryToDecimalU16
    jsr _cheat_write_decimal_view
; get and write floor name
    rep #$30
    lda.b cheatParameterValue
    asl
    tax
    lda.l FloorDefinitions,X
    clc
    adc #floordefinition_t.name
    sta.b $00
    lda #bankbyte(FLOOR_DEFINITION_BASE)
    sta.b $02
    jsr _cheat_write_text_view
    rts

_cheat_action_tick_floor:
    rts

; ROOM

_cheat_action_begin_room:
    rts

_cheat_action_tick_room:
    rts

; ITEM GIVE

_cheat_action_item_render:
    rep #$30
    ldx.b cheatParameterValue
    lda.w playerData.playerItemStackNumber,X
    and #$00FF
    jsl ConvertBinaryToDecimalU16
    jsr _cheat_write_decimal_view
    rep #$30
    lda.b cheatParameterValue
    asl
    tax
    lda.l Item.items,X
    clc
    adc #itemdef_t.name
    sta.b $00
    lda #bankbyte(Item.items)
    sta.b $02
    jsr _cheat_write_text_view
    rts

_cheat_action_begin_item_give:
    rep #$30
    lda #1
    sta.b cheatParameterValue
    jsr _cheat_action_item_render
    rts

_cheat_action_tick_item_give:
    rep #$30
    lda.w joy1press
    bit #JOY_RIGHT
    beq @no_right
        lda.b cheatParameterValue
        inc A
        cmp #ITEM_COUNT
        bcc +
            lda #1
        +:
        sta.b cheatParameterValue
        jsr _cheat_action_item_render
        rep #$30
    @no_right:
    lda.w joy1press
    bit #JOY_LEFT
    beq @no_left
        lda.b cheatParameterValue
        dec A
        bne +
            lda #ITEM_COUNT-1
        +:
        sta.b cheatParameterValue
        jsr _cheat_action_item_render
        rep #$30
    @no_left:
    ; try give or take items
    lda.w joy1press
    bit #JOY_A
    beq @no_give
        sep #$20
        ldx.b cheatParameterValue
        lda.w playerData.playerItemStackNumber,X
        cmp #PLAYER_MAX_ITEM_COUNT-1
        bcs @no_give
        lda.w playerData.playerItemCount
        cmp #$FF
        beq @no_give
        rep #$30
        lda.b cheatParameterValue
        asl
        tax
        lda.l Item.items,X
        tax
        lda.l bankaddr(Item.items) + itemdef_t.flags,X
        and #ITEMFLAG_ACTIVE
        beq @passive
    ; active
        sep #$30
        lda.b cheatParameterValue
        jsl Item.set_active
        rep #$30
        lda.b cheatParameterValue
        asl
        tax
        lda.l Item.items,X
        tax
        lda.l bankaddr(Item.items) + itemdef_t.charge_init,X
        sep #$20
        sta.w playerData.current_active_charge
        jsl UI.update_charge_display
        jmp @no_give
    @passive:
        sep #$30
        lda.b cheatParameterValue
        jsl Item.add
        jsr _cheat_action_item_render
    @no_give:
    rep #$30
    lda.w joy1press
    bit #JOY_B
    beq @no_take
        sep #$20
        ldx.b cheatParameterValue
        lda.w playerData.playerItemStackNumber,X
        beq @no_take
        lda.b cheatParameterValue
        jsl Item.remove
        jsr _cheat_action_item_render
        rep #$30
    @no_take:
    rts

; ITEM REMOVE

_cheat_action_begin_item_remove:
    rts

_cheat_action_tick_item_remove:
    rts

; CONSUMABLE

_cheat_action_begin_consumable_set:
    rts

_cheat_action_tick_consumable_set:
    rts

; MONEY

_cheat_action_begin_money:
    rts

_cheat_action_tick_money:
    rts

; BOMBS

_cheat_action_begin_bombs:
    rts

_cheat_action_tick_bombs:
    rts

; KEYS

_cheat_action_begin_keys:
    rts

_cheat_action_tick_keys:
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