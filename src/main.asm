.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "Main"

UpdateLoop:
    rep #$30 ; 16 bit AXY
    inc.w is_game_update_running
    ; Actual update code
    ; First, clear sprite data (will eventually make this better)
    stz.w objectIndex
    lda #512
    sta.w objectIndexShadow
    lda #EmptySpriteData
    sta DMA0_SRCL
    lda #512+32
    sta DMA0_SIZE
    lda #objectData
    sta WMADDL
    sep #$30 ; 8b AXY
    lda #bankbyte(EmptySpriteData)
    sta DMA0_SRCH
    stz WMADDH
    stz DMA0_CTL ; abs addr, inc addr, 1B
    lda #$80
    sta DMA0_DEST
    lda #$01
    sta MDMAEN
    ; run all update hooks
    jsl entity_clear_hitboxes
    jsl entity_refresh_hitboxes
    jsr PlayerUpdate
    jsl Pathing.UpdatePlayer
    jsl Pathing.UpdateEnemy
    jsl entity_tick_all
    jsl Room_Tick
    jsl Floor_Tick
    jsr UpdateRest
    jsl GroundProcessOps
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
    BIT #JOY_SELECT
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
