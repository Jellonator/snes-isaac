.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "Main"

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
    rts

; Main loop of the entire game
UpdateLoop:
    ; update counter
    rep #$30 ; 16 bit AXY
    inc.w is_game_update_running
    inc.w tickCounter
    ; clear data
    jsr ClearSpriteTable
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
    jsr UpdateRest
    jsl GroundProcessOps
    jsl Overlay.update
    ; Finally, check if room should be changed
    jsr PlayerCheckEnterRoom
    ; End update code
    rep #$30 ; 16 bit AXY
    stz.w is_game_update_running
    wai
    jmp UpdateLoop

UpdateRest:
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

ReadInput:
    ; loop until controller allows itself to be read
    rep #$20 ; 8 bit A
@read_input_loop:
    lda HVBJOY
    and #$01
    bne @read_input_loop ;0.14% -> 1.2%
    ; Read input
    rep #$30 ; 16 bit AXY
    ldx.w joy1raw
    lda $4218
    sta.w joy1raw
    txa
    eor.w joy1raw
    and.w joy1raw
    sta.w joy1press
    txa
    and.w joy1raw
    sta.w joy1held
    ; Not worried about controller validity for now
    sep #$30 ; 8 bit AXY
    rts

; Clear a section of WRAM
; push order:
;   wram address [dw] $07
;   wram bank    [db] $06
;   num bytes    [dw] $04
; MUST call with jsl
ClearWRam:
    rep #$20 ; 16 bit A
    lda $04,s
    sta DMA0_SIZE
    lda #loword(EmptyData)
    sta DMA0_SRCL
    lda $07,s
    sta WMADDL
    sep #$20 ; 8 bit A
    lda #bankbyte(EmptyData)
    sta DMA0_SRCH
    lda $06,s
    sta WMADDH
    ; Absolute address, no increment, 1 byte at a time
    lda #%00001000
    sta DMA0_CTL
    ; Write to WRAM
    lda #$80
    sta DMA0_DEST
    lda #$01
    sta MDMAEN
    rtl

.ENDS
