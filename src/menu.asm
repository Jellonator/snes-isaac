.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "MENU" FREE

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
    .REPT 32*2
        .dw 0
    .ENDR
    .REPT 4 INDEX iy
        .REPT 8 INDEX ix
            .dw deft($0100 + iy*16*4 + ix*2, 2)
        .ENDR
        .REPT 8 INDEX ix
            .dw deft($0100 + (iy*2+1)*16*2 + ix*2, 2)
        .ENDR
        .REPT 16 INDEX ix
            .dw 0
        .ENDR
    .ENDR
    .REPT 32*26
        .dw 0
    .ENDR

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
    ; Set tilemap mode 1
    lda #%01100001
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
    ; show all on main screen
    lda #%00010111
    sta SCRNDESTM
    ; set scroll
    stz BG3HOFS
    stz BG3HOFS
    stz BG3VOFS
    stz BG3VOFS
    stz BG2HOFS
    stz BG2HOFS
    stz BG2VOFS
    stz BG2VOFS
    stz BG1HOFS
    stz BG1HOFS
    stz BG1VOFS
    stz BG1VOFS
    ; Clear VRAM
    pea 0
    pea $0000
    jsl ClearVMem
    rep #$20
    .POPN 4
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
    pea BG3_TILE_BASE_ADDR
    pea 32*32*2
    sep #$20
    lda #bankbyte(_MenuBackgroundData)
    pha
    pea loword(_MenuBackgroundData)
    jsl CopyVMEM
    .POPN 7
    ; Upload start layout
    pea BG2_TILE_BASE_ADDR
    pea 32*32*2
    sep #$20
    lda #bankbyte(_MenuLayout_PageStart)
    pha
    pea loword(_MenuLayout_PageStart)
    jsl CopyVMEM
    .POPN 7
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
    ; init vqueue
    jsl ClearVQueue
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
    ; End update code
    rep #$30 ; 16 bit AXY
    stz.w is_game_update_running
    wai
    jmp _Menu.Loop

.ENDS