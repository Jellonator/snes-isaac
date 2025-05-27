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

_MenuLayout_Main:
    .REPT 16*2
        .dw 0
    .ENDR
    .dw 0, 0, 0, 0, deft($02,1), deft($08,1), deft($04,1), deft($04,1), deft($04,1), deft($04,1), deft($08,1), deft($06,1), 0, 0, 0, 0
    .REPT 8
        .dw 0, 0, 0, 0, deft($22,1), deft($24,1), deft($24,1), deft($24,1), deft($24,1), deft($24,1), deft($24,1), deft($26,1), 0, 0, 0, 0
    .ENDR
    .dw 0, 0, 0, 0, deft($42,1), deft($44,1), deft($44,1), deft($44,1), deft($44,1), deft($44,1), deft($44,1), deft($46,1), 0, 0, 0, 0
    .REPT 16*4
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
    palette dw
    selection dw
.ENDE

_empty_func:
    rts

_Menu.StateEnterTable:
    .dw _menu_start_init ; start
    .dw _menu_main_init ; main
    .dw _empty_func ; char select

_Menu.StateTickTable:
    .dw _menu_start_tick ; start
    .dw _menu_main_tick ; main
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
    ; clear BG1
    jsr _Menu.ClearBG1
    ; call enter table
    rep #$30
    lda.b menuState
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

; Clear BG1
_Menu.ClearBG1:
    rep #$30
    .VQueueOpToA
    tax
    inc.w vqueueNumOps
    lda #MENU_BG1_TILE_BASE_ADDR
    clc
    adc.b menuBG1Offset
    sta.l vqueueOps.1.vramAddr,X
    lda #32*32*2
    sta.l vqueueOps.1.numBytes,X
    sep #$20
    lda #VQUEUE_MODE_VRAM_CLEAR
    sta.l vqueueOps.1.mode,X
    rts

; put text at Y into position X
_Menu.PutTextBG1:
    rep #$30
    ; get tile address
    txa
    clc
    adc.b menuBG1Offset
    clc
    adc #MENU_BG1_TILE_BASE_ADDR
    sta.b $00
    sty.b $02
    ; get string length
    sep #$20
    tyx
    phb
    phk
    plb
    jsl String.len
    plb
    .ACCU 16
    sta.b $04
    asl
    sta.b $06
    ; get buffer
    lda.w vqueueBinOffset
    sec
    sbc.b $06
    sta.w vqueueBinOffset
    tax
    ; copy text into buffer
    phb
    phk
    plb
    ldy.b $02
    @loop_begin:
        dec.b $04
        bmi @loop_end
        lda.w $0000,Y
        and #$00FF
        ora.b palette
        sta.l $7F0000,X
        inx
        inx
        iny
        jmp @loop_begin
    @loop_end:
    plb
    ; create vqueue entry
    .VQueueOpToA
    tax
    inc.w vqueueNumOps
    lda.b $06
    sta.l vqueueOps.1.numBytes,X
    lda.w vqueueBinOffset
    sta.l vqueueOps.1.aAddr,X
    lda.b $00
    sta.l vqueueOps.1.vramAddr,X
    sep #$20
    lda #$7F
    sta.l vqueueOps.1.aAddr+2,X
    lda #VQUEUE_MODE_VRAM
    sta.l vqueueOps.1.mode,X
    ; end
    rts

; Enter menu
Menu.Begin:
    .ChangeDataBank $80
    ; Disable rendering temporarily
    .DisableINT
    ; Disable interrupts
    .DisableRENDER
    ; reset all registers
    .ClearCPU
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
    ; Set up sprite mode (page 2 points to UI)
    lda #0
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
    rep #$30
    ldx #loword(spritedata.menu.background)
    ldy #loword(private_spriteAllocBuffer)
    lda #bankbyte(spritedata.menu.background) | $7F00
    jsl Decompress.Lz4FromROM
    pea $0000
    pea 16*16/2
    sep #$20
    lda #$7F
    pha
    pea loword(private_spriteAllocBuffer)
    jsl CopySprite
    .POPN 7
    ; Upload UI
    rep #$30
    ldx #loword(spritedata.menu.mainmenu)
    ldy #loword(private_spriteAllocBuffer)
    lda #bankbyte(spritedata.menu.mainmenu) | $7F00
    jsl Decompress.Lz4FromROM
    pea BG2_CHARACTER_BASE_ADDR
    pea 16*16
    sep #$20
    lda #$7F
    pha
    pea loword(private_spriteAllocBuffer)
    jsl CopySprite
    .POPN 7
    ; Upload logo
    rep #$30
    ldx #loword(spritedata.menu.logo)
    ldy #loword(private_spriteAllocBuffer)
    lda #bankbyte(spritedata.menu.logo) | $7F00
    jsl Decompress.Lz4FromROM
    pea BG2_CHARACTER_BASE_ADDR + $1000
    pea 16*16
    sep #$20
    lda #$7F
    pha
    pea loword(private_spriteAllocBuffer)
    jsl CopySprite
    .POPN 7
    ; Decompress and upload UI
    rep #$30
    ldx #loword(spritedata.menu.ui)
    ldy #loword(private_spriteAllocBuffer)
    lda #bankbyte(spritedata.menu.ui) | $7F00
    jsl Decompress.Lz4FromROM
    pea BG1_CHARACTER_BASE_ADDR
    pea 16*16
    sep #$20
    lda #$7F
    pha
    pea loword(private_spriteAllocBuffer)
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
    rep #$30
    lda #STATE_START
    jsr _Menu.SetState
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
    ; Upload UI palette
    pea 2*16
    pea $3000 + bankbyte(palettes.menu.ui)
    pea loword(palettes.menu.ui)
    jsl CopyPalette
    .POPN 6
    pea 2*16
    pea $8000 + bankbyte(palettes.menu.ui)
    pea loword(palettes.menu.ui)
    jsl CopyPalette
    .POPN 6
    ; Upload gray text palette
    pea 2*16
    pea $4000 + bankbyte(palettes.menu.text_gray)
    pea loword(palettes.menu.text_gray)
    jsl CopyPalette
    .POPN 6
    ; Clear sprites
    rep #$30
    jsl ClearSpriteTable
    jsl UploadSpriteTable
    ; clear some render flags
    sep #$30
    lda #0
    sta.l gamePauseTimer
    sta.l needResetEntireGround
    sta.l numTilesToUpdate
    ; Clear HDMA table
    jsl Render.ClearHDMA
    ; re-enable rendering
    rep #$20
    stz.w blockVQueueMutex
    sep #$20
    lda #$0F
    sta.w roomBrightness
    .EnableRENDER
    ; Enable interrupts and joypad
    .EnableINT
; Main loop for menu
_Menu.Loop:
    ; update counter
    rep #$30 ; 16 bit AXY
    inc.w blockVQueueMutex
    inc.w tickCounter
    ; clear data
    jsl ClearSpriteTable
    ; update
    jsr _Menu.Tick
    jsr _Menu.HandleScroll
    ; increment seed timer
    rep #$20
    lda.l seed_timer_low
    inc A
    sta.l seed_timer_low
    bne +
        lda.l seed_timer_high
        inc A
        sta.l seed_timer_high
    +:
    ; End update code
    rep #$30 ; 16 bit AXY
    stz.w blockVQueueMutex
    wai
    jmp _Menu.Loop

_Menu.HandleScroll:
    rep #$30
    ; scroll X
    lda.b currentScrollX
    .CMPS_BEGIN P_DIR targetScrollX
        lda.b currentScrollX
        clc
        adc #16
        .AMIN P_DIR targetScrollX
        sta.b currentScrollX
    .CMPS_GREATER
        lda.b currentScrollX
        sec
        sbc #16
        .AMAX P_DIR targetScrollX
        sta.b currentScrollX
    .CMPS_EQUAL
    .CMPS_END
    ; scroll Y
    lda.b currentScrollY
    .CMPS_BEGIN P_DIR targetScrollY
        lda.b currentScrollY
        clc
        adc #16
        .AMIN P_DIR targetScrollY
        sta.b currentScrollY
    .CMPS_GREATER
        lda.b currentScrollY
        sec
        sbc #16
        .AMAX P_DIR targetScrollY
        sta.b currentScrollY
    .CMPS_EQUAL
    .CMPS_END
; store scroll
    ; get vqueue register ops
    rep #$20
    lda.w vqueueNumRegOps
    asl
    tax
    lsr
    clc
    adc #12
    sta.w vqueueNumRegOps
    ; store values
    ; sep #$20
    lda.b currentScrollX
    sta.l vqueueRegOps_Value+$00,X
    lda #BG2HOFS
    sta.l vqueueRegOps_Addr+$00,X
    lda.b currentScrollX+1
    sta.l vqueueRegOps_Value+$02,X
    lda #BG2HOFS
    sta.l vqueueRegOps_Addr+$02,X
    lda.b currentScrollX
    sta.l vqueueRegOps_Value+$04,X
    lda #BG1HOFS
    sta.l vqueueRegOps_Addr+$04,X
    lda.b currentScrollX+1
    sta.l vqueueRegOps_Value+$06,X
    lda #BG1HOFS
    sta.l vqueueRegOps_Addr+$06,X
    lda.b currentScrollY
    sta.l vqueueRegOps_Value+$08,X
    lda #BG2VOFS
    sta.l vqueueRegOps_Addr+$08,X
    lda.b currentScrollY+1
    sta.l vqueueRegOps_Value+$0A,X
    lda #BG2VOFS
    sta.l vqueueRegOps_Addr+$0A,X
    lda.b currentScrollY
    sta.l vqueueRegOps_Value+$0C,X
    lda #BG1VOFS
    sta.l vqueueRegOps_Addr+$0C,X
    lda.b currentScrollY+1
    sta.l vqueueRegOps_Value+$0E,X
    lda #BG1VOFS
    sta.l vqueueRegOps_Addr+$0E,X
    ; BG3 has 75% scroll
    ; rep #$20
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
    ; sep #$20
    lda.b $00
    sta.l vqueueRegOps_Value+$10,X
    lda #BG3HOFS
    sta.l vqueueRegOps_Addr+$10,X
    lda.b $01
    sta.l vqueueRegOps_Value+$12,X
    lda #BG3HOFS
    sta.l vqueueRegOps_Addr+$12,X
    lda.b $02
    sta.l vqueueRegOps_Value+$14,X
    lda #BG3VOFS
    sta.l vqueueRegOps_Addr+$14,X
    lda.b $03
    sta.l vqueueRegOps_Value+$16,X
    lda #BG3VOFS
    sta.l vqueueRegOps_Addr+$16,X
    rts

; START SCREEN
_menu_start_text:
    .ASC "PRESS START", 0

_menu_start_init:
    rep #$30
    ldx #loword(_MenuLayout_PageStart)
    jsr _Menu.UploadBG2
    ; put text
    rep #$30
    ldy #loword(_menu_start_text)
    ldx #textpos(11, 22)
    lda #deft($00, 3)
    sta.b palette
    jsr _Menu.PutTextBG1
    rts

_menu_start_tick:
    rep #$30
    lda.w joy1press
    bit #JOY_START
    beq +
        jsr _Menu.ScrollDown
        rep #$30
        lda #STATE_MAIN
        jsr _Menu.SetState
    +:
    rts

; MAIN SCREEN

_menu_main_newgame:
    .db $04
    .ASC "New Run", 0

_menu_main_continuegame:
    .ASC "Continue", 0

.DEFINE MENU_MAIN_SELECT_COUNT 2

_menu_main_actions:
    .dw _menu_main_action_newrun
    .dw _menu_main_action_continue

_menu_main_action_newrun:
    sep #$20
    stz.w loadFromSaveState
    jsl Floor.Transition_In
    jml Game.Begin

_menu_main_action_continue:
    sep #$20
    lda.w currentSaveSlot
    jsl Save.IsSavestateInUse
    cmp #1
    bne @no_continue
        sep #$20
        lda #1
        sta.w loadFromSaveState
        jsl Floor.Transition_In
        jml Game.Begin
@no_continue:
    rts

_menu_main_init:
    ldx #loword(_MenuLayout_Main)
    jsr _Menu.UploadBG2
    ; put text NEW RUN
    rep #$30
    ldy #loword(_menu_main_newgame)
    ldx #textpos(10, 8)
    lda #deft($00, 3)
    sta.b palette
    jsr _Menu.PutTextBG1
    ; put text CONTINUE
    rep #$30
    lda #deft($00, 3)
    sta.b palette
    jsl Save.IsSavestateInUse
    .ACCU 8
    cmp #1
    beq +
        rep #$30
        lda #deft($00, 4)
        sta.b palette
    +:
    rep #$30
    ldy #loword(_menu_main_continuegame)
    ldx #textpos(11, 10)
    jsr _Menu.PutTextBG1
    rep #$30
    stz.b selection
    rts

_menu_main_tick:
    ; exit
    rep #$30
    lda.w joy1press
    bit #JOY_B
    beq +
        jsr _Menu.ScrollUp
        rep #$30
        lda #STATE_START
        jsr _Menu.SetState
        rts
    +:
    ; change selection
    rep #$30
    lda.b selection
    sta.b $02
    stz.b $00
    lda.w joy1press
    bit #JOY_UP
    beq +
        inc.b $00
        sep #$20
        lda.b selection
        dec A
        bpl ++
            lda #MENU_MAIN_SELECT_COUNT-1
        ++:
        sta.b selection
        rep #$20
    +:
    lda.w joy1press
    bit #JOY_DOWN
    beq +
        inc.b $00
        sep #$20
        lda.b selection
        inc A
        cmp #MENU_MAIN_SELECT_COUNT
        bcc ++
            lda #0
        ++:
        sta.b selection
        rep #$20
    +:
    lda.b $00
    beq @no_change_select
        ; change indicator
        lda.w vqueueNumMiniOps
        inc.w vqueueNumMiniOps
        inc.w vqueueNumMiniOps
        asl
        asl
        tax
        lda #deft($00, 3) | T_HIGHP
        sta.l vqueueMiniOps.1.data,X
        lda #deft($04, 3) | T_HIGHP
        sta.l vqueueMiniOps.2.data,X
        lda.b $02
        and #$00FF
        .MultiplyStatic 64
        clc
        adc #textpos(10, 8) + MENU_BG1_TILE_BASE_ADDR
        clc
        adc.b menuBG1Offset
        sta.l vqueueMiniOps.1.vramAddr,X
        lda.w selection
        and #$00FF
        .MultiplyStatic 64
        clc
        adc #textpos(10, 8) + MENU_BG1_TILE_BASE_ADDR
        clc
        adc.b menuBG1Offset
        sta.l vqueueMiniOps.2.vramAddr,X
@no_change_select:
    ; action
    rep #$30
    lda.w joy1press
    bit #JOY_START
    beq +
        lda.b selection
        and #$00FF
        asl
        tax
        jsr (_menu_main_actions, X)
    +:
    rts

.ENDS
