.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "MENU" FREE

.DEFINE MENU_BG1_TILE_BASE_ADDR $7000
.DEFINE MENU_BG2_TILE_BASE_ADDR $6C00
.DEFINE MENU_BG3_TILE_BASE_ADDR $6800

.ARRAYDEFINE NAME ArrayBackground SIZE 32*32
.MACRO .PutBGTile ARGS ix, iy, tile
    .ARRAYIN NAME ArrayBackground INDEX (ix   + ( iy    * 32)) VALUE deft(tile+$00, 0)
    .ARRAYIN NAME ArrayBackground INDEX (ix+1 + ( iy    * 32)) VALUE deft(tile+$02, 0)
    .ARRAYIN NAME ArrayBackground INDEX (ix   + ((iy+1) * 32)) VALUE deft(tile+$20, 0)
    .ARRAYIN NAME ArrayBackground INDEX (ix+1 + ((iy+1) * 32)) VALUE deft(tile+$22, 0)
.ENDM
.PutBGTile  4,  4, $04
.PutBGTile 12,  6, $08
.PutBGTile  6, 12, $0C
.PutBGTile 24,  2, $40
.PutBGTile 18, 10, $44
.PutBGTile  8, 18, $48
.PutBGTile 20, 22, $4C

_MenuBackgroundData:
    .REPT 32*32 INDEX i
        .ARRAYDW NAME ArrayBackground INDICES i
    .ENDR

_MenuLayout_PageStart:
    .REPT 16*2
        .dw 0
    .ENDR
    .REPT 4 INDEX iy
        .REPT 8 INDEX ix
            .dw deft($0100 + iy*16*4 + ix*2, 2)
        .ENDR
        .REPT 8 INDEX ix
            .dw deft($0100 + (iy*2+1)*16*2 + ix*2, 2)
        .ENDR
    .ENDR
    .REPT 32*10
        .dw 0
    .ENDR

.DEFINE STATE_START 0
.DEFINE STATE_MAIN 2
.DEFINE STATE_CHARSELECT 4

.ENUM $0040
    menuState dw
    currentScrollX dw
    currentScrollY dw
    targetScrollX dw
    targetScrollY dw
    menuBG2Offset dw ; % 000000y0 000x0000
    menuBG1Offset dw ; % 0000yx00 00000000
.ENDE

_empty_func:
    rts

_Menu.StateEnterTable:
    .dw _menu_start_init ; start
    .dw _empty_func ; main
    .dw _empty_func ; char select

_Menu.StateTickTable:
    .dw _menu_start_tick ; start
    .dw _empty_func ; main
    .dw _empty_func ; char select

_Menu.Tick:
    rep #$30
    ldx.b menuState
    jsr (_Menu.StateTickTable,X)
    rts

; Set state to A
_Menu.SetState:
    rep #$30
    and #$00FF
    sta.b menuState
    tax
    jsr (_Menu.StateEnterTable,X)
    rts

_Menu.ScrollLeft:
    rep #$30
    lda.b menuBG2Offset
    eor #BG2_TILE_ADDR_OFFS_X
    sta.b menuBG2Offset
    lda.b menuBG1Offset
    eor #%0000010000000000
    sta.b menuBG1Offset
    lda.b targetScrollX
    sec
    sbc #256
    sta.b targetScrollX
    rts

_Menu.ScrollRight:
    rep #$30
    lda.b menuBG2Offset
    eor #BG2_TILE_ADDR_OFFS_X
    sta.b menuBG2Offset
    lda.b menuBG1Offset
    eor #%0000010000000000
    sta.b menuBG1Offset
    lda.b targetScrollX
    clc
    adc #256
    sta.b targetScrollX
    rts

_Menu.ScrollUp:
    rep #$30
    lda.b menuBG2Offset
    eor #BG2_TILE_ADDR_OFFS_Y
    sta.b menuBG2Offset
    lda.b menuBG1Offset
    eor #%0000100000000000
    sta.b menuBG1Offset
    lda.b targetScrollY
    sec
    sbc #256
    sta.b targetScrollY
    rts

_Menu.ScrollDown:
    rep #$30
    lda.b menuBG2Offset
    eor #BG2_TILE_ADDR_OFFS_Y
    sta.b menuBG2Offset
    lda.b menuBG1Offset
    eor #%0000100000000000
    sta.b menuBG1Offset
    lda.b targetScrollY
    clc
    adc #256
    sta.b targetScrollY
    rts

; Upload tile data to BG2
; Tile data pointer stored in X
_Menu.UploadBG2:
    rep #$30 ; 16 bit A
    stx.b $00
    .VQueueOpToA
    tax
    lda.w vqueueNumOps
    clc
    adc #16
    sta.w vqueueNumOps
    lda #MENU_BG2_TILE_BASE_ADDR
    clc
    adc.b menuBG2Offset
    sta.b $02
    .REPT 16 INDEX i
        ; SRC ADDR
        lda.b $00
        sta.l vqueueOps.{i+1}.aAddr,X
        clc
        adc #16*2
        sta.b $00
        ; VRAM ADDR
        lda.b $02
        sta.l vqueueOps.{i+1}.vramAddr,X
        clc
        adc #16*2
        sta.b $02
        ; rest
        lda #16*2
        sta.l vqueueOps.{i+1}.numBytes,X
        sep #$20
        lda #bankbyte(_MenuBackgroundData)
        sta.l vqueueOps.{i+1}.aAddr+2,X
        lda #VQUEUE_MODE_VRAM
        sta.l vqueueOps.{i+1}.mode,X
        rep #$20
    .ENDR
    rts

; Enter menu
Menu.Begin:
    .ChangeDataBank $00
    ; Disable rendering temporarily
    sep #$20
    lda #%10000000
    sta.w INIDISP
    ; Disable interrupts
    lda #1
    sta.w NMITIMEN
    sei
    ; reset all registers
    jsl ResetRegisters
    sep #$20
    lda #%10000000
    sta.w INIDISP
    ; Set tilemap mode 1
    lda #%01100001
    sta.w BGMODE
    lda #(MENU_BG1_TILE_BASE_ADDR >> 8) | %11
    sta.w BG1SC
    lda #(MENU_BG2_TILE_BASE_ADDR >> 8) | %00
    sta.w BG2SC
    lda #(MENU_BG3_TILE_BASE_ADDR >> 8) | %00
    sta.w BG3SC
    lda #(BG1_CHARACTER_BASE_ADDR >> 12) | (BG2_CHARACTER_BASE_ADDR >> 8)
    sta.w BG12NBA
    lda #(BG3_CHARACTER_BASE_ADDR >> 12)
    sta.w BG34NBA
    ; Set up sprite mode
    lda #%00000000 | (SPRITE1_BASE_ADDR >> 13) | ((SPRITE2_BASE_ADDR - SPRITE1_BASE_ADDR - $1000) >> 9)
    sta.w OBSEL
    ; show all on main screen
    lda #%00010111
    sta.w SCRNDESTM
    ; set scroll
    stz.w BG3HOFS
    stz.w BG3HOFS
    stz.w BG3VOFS
    stz.w BG3VOFS
    stz.w BG2HOFS
    stz.w BG2HOFS
    stz.w BG2VOFS
    stz.w BG2VOFS
    stz.w BG1HOFS
    stz.w BG1HOFS
    stz.w BG1VOFS
    stz.w BG1VOFS
    ; set menu variables
    rep #$20
    stz.b currentScrollX
    stz.b currentScrollY
    stz.b targetScrollX
    stz.b targetScrollY
    stz.b menuBG2Offset
    stz.b menuBG1Offset
    lda #STATE_START
    sta.b menuState
    ; clear inputs
    stz.w joy1raw
    stz.w joy1press
    stz.w joy1held
    ; Clear VRAM
    pea 0
    pea $0000
    jsl ClearVMem
    rep #$20
    .POPN 4
    ; init vqueue
    jsl ClearVQueue
    ; Upload background
    pea $0000
    pea 16*16/2
    sep #$20
    lda #bankbyte(spritedata.menu.background)
    pha
    pea loword(spritedata.menu.background)
    jsl CopySprite
    .POPN 7
    ; Upload UI
    pea BG2_CHARACTER_BASE_ADDR
    pea 16*16
    sep #$20
    lda #bankbyte(spritedata.menu.mainmenu)
    pha
    pea loword(spritedata.menu.mainmenu)
    jsl CopySprite
    .POPN 7
    ; Upload logo
    pea BG2_CHARACTER_BASE_ADDR + $1000
    pea 16*16
    sep #$20
    lda #bankbyte(spritedata.menu.logo)
    pha
    pea loword(spritedata.menu.logo)
    jsl CopySprite
    .POPN 7
    ; Upload background tiles
    pea MENU_BG3_TILE_BASE_ADDR
    pea 32*32*2
    sep #$20
    lda #bankbyte(_MenuBackgroundData)
    pha
    pea loword(_MenuBackgroundData)
    jsl CopyVMEM
    .POPN 7
    ; Upload start layout
    ; pea MENU_BG2_TILE_BASE_ADDR
    ; pea 32*32*2
    ; sep #$20
    ; lda #bankbyte(_MenuLayout_PageStart)
    ; pha
    rep #$30
    lda #STATE_START
    jsr _Menu.SetState
    ; jsl CopyVMEM
    ; .POPN 7
    ; Upload background palette
    pea 2*4
    pea $0000 + bankbyte(palettes.menu.background)
    pea loword(palettes.menu.background)
    jsl CopyPalette
    .POPN 6
    ; Upload UI palette
    pea 2*16
    pea $1000 + bankbyte(palettes.menu.main)
    pea loword(palettes.menu.main)
    jsl CopyPalette
    .POPN 6
    ; Upload logo palette
    pea 2*16
    pea $2000 + bankbyte(palettes.menu.logo)
    pea loword(palettes.menu.logo)
    jsl CopyPalette
    .POPN 6
    ; Clear sprites
    rep #$30
    jsl ClearSpriteTable
    jsl UploadSpriteTable
    ; clear some render flags
    sep #$30
    lda #0
    sta.l needResetEntireGround
    sta.l numTilesToUpdate
    ; re-enable rendering
    sep #$20
    lda #%00001111
    sta.w roomBrightness
    sta INIDISP
    stz.w is_game_update_running
    ; Enable interrupts and joypad
    cli
    lda #$81
    sta.w NMITIMEN
; Main loop for menu
_Menu.Loop:
    ; update counter
    rep #$30 ; 16 bit AXY
    inc.w is_game_update_running
    inc.w tickCounter
    ; clear data
    jsl ClearSpriteTable
    ; update
    jsr _Menu.Tick
    jsr _Menu.HandleScroll
    ; End update code
    rep #$30 ; 16 bit AXY
    stz.w is_game_update_running
    wai
    jmp _Menu.Loop

_Menu.HandleScroll:
    rep #$30
    ; scroll X
    lda.b currentScrollX
    .CMPS_BEGIN P_DIR targetScrollX
        lda.b currentScrollX
        clc
        adc #8
        .AMIN P_DIR targetScrollX
        sta.b currentScrollX
    .CMPS_GREATER
        lda.b currentScrollX
        sec
        sbc #8
        .AMAX P_DIR targetScrollX
        sta.b currentScrollX
    .CMPS_EQUAL
    .CMPS_END
    ; scroll Y
    lda.b currentScrollY
    .CMPS_BEGIN P_DIR targetScrollY
        lda.b currentScrollY
        clc
        adc #8
        .AMIN P_DIR targetScrollY
        sta.b currentScrollY
    .CMPS_GREATER
        lda.b currentScrollY
        sec
        sbc #8
        .AMAX P_DIR targetScrollY
        sta.b currentScrollY
    .CMPS_EQUAL
    .CMPS_END
    ; store
    sep #$20
    lda.b currentScrollX
    sta BG2HOFS
    lda.b currentScrollX+1
    sta BG2HOFS
    lda.b currentScrollX
    sta BG1HOFS
    lda.b currentScrollX+1
    sta BG1HOFS
    lda.b currentScrollY
    sta BG2VOFS
    lda.b currentScrollY+1
    sta BG2VOFS
    lda.b currentScrollY
    sta BG1VOFS
    lda.b currentScrollY+1
    sta BG1VOFS
    ; BG3 has 75% scroll
    rep #$20
    lda.b currentScrollX
    .ShiftRight_SIGN 3, 0
    sta.b $00
    lda.b currentScrollX
    sec
    sbc.b $00
    sta.b $00
    lda.b currentScrollY
    .ShiftRight_SIGN 3, 0
    sta.b $02
    lda.b currentScrollY
    sec
    sbc.b $02
    sta.b $02
    sep #$20
    lda.b $00
    sta BG3HOFS
    lda.b $01
    sta BG3HOFS
    lda.b $02
    sta BG3VOFS
    lda.b $03
    sta BG3VOFS
    rts

; START SCREEN
_menu_start_init:
    ldx #loword(_MenuLayout_PageStart)
    jsr _Menu.UploadBG2
    rts

_menu_start_tick:
    rep #$30
    lda.w joy1press
    bit #JOY_UP
    beq +
        jsr _Menu.ScrollUp
        rep #$30
        lda #STATE_START
        jsr _Menu.SetState
        rep #$30
        lda.w joy1press
    +:
    bit #JOY_DOWN
    beq +
        jsr _Menu.ScrollDown
        rep #$30
        lda #STATE_START
        jsr _Menu.SetState
        rep #$30
        lda.w joy1press
    +:
    bit #JOY_LEFT
    beq +
        jsr _Menu.ScrollLeft
        rep #$30
        lda #STATE_START
        jsr _Menu.SetState
        rep #$30
        lda.w joy1press
    +:
    bit #JOY_RIGHT
    beq +
        jsr _Menu.ScrollRight
        rep #$30
        lda #STATE_START
        jsr _Menu.SetState
    +:
    rts

.ENDS
