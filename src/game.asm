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
    lda #(BG1_TILE_BASE_ADDR >> 8) | %00
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
    ; Clear sprites
    rep #$30
    jsl ClearSpriteTable
    jsl UploadSpriteTable
    ; clear some render flags
    sep #$30
    lda #1
    sta.l needResetEntireGround
    sta.l numTilesToUpdate
    ; re-enable rendering
    rep #$20
    stz.w is_game_update_running
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
    inc.w is_game_update_running
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
    jsr _UpdateRest
    jsl GroundProcessOps
    jsl Overlay.update
    ; Finally, check if room should be changed
    jsr PlayerCheckEnterRoom
    ; End update code
    rep #$30 ; 16 bit AXY
    stz.w is_game_update_running
    wai
    jmp _Game.Loop

_UpdateRest:
    rep #$30 ; 16 bit AXY
    lda.w joy1press
    BIT #JOY_START
    beq @skip_regenerate_map
    jsl BeginMapGeneration
        sep #$30 ; 8 bit AXY
        lda #1
        sta.l needResetEntireGround
        lda #0
        pha
        jsl LoadRoomSlotIntoLevel
        sep #$30 ; 8 bit AXY
        pla
        jsl PlayerEnterFloor
@skip_regenerate_map:
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

.ENDS