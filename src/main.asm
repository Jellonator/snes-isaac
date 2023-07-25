.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "Main"

UpdateLoop:
    rep #$30 ; 16 bit AXY
    inc.w is_game_update_running
    ; Actual update code
    ; First, clear sprite data (will eventually make this better)
    .InitializeObjectIndices
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
    jsr PlayerUpdate
    jsr UpdateTears
    jsr UpdateRest
    jsl entity_tick_all
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
    lda #0
    pha
    jsl LoadRoomSlotIntoLevel
    sep #$30 ; 8 bit AXY
    pla
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

.BANK $00 SLOT "ROM"
.SECTION "MainCodeData" FREE

TileData:
.dw $0002 $0004 $0004 $0004 $0004 $0004 $0004 $000C $000E $0004 $0004 $0004 $0004 $0004 $0004 $4002
.dw $0022 $0024 $0026 $0026 $0026 $0026 $0026 $002C $002E $0026 $0026 $0026 $0026 $0026 $4024 $4022
;              [                                                                       ]
.dw $0022 $0006 $0008 $000A $000A $000A $000A $000A $000A $000A $000A $000A $000A $4008 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0040 $0042 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4042 $4040
.dw $0060 $0062 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4062 $4060
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $8008 $800A $800A $800A $800A $800A $800A $800A $800A $800A $800A $C008 $4006 $4022
;              [                                                                       ]
.dw $0022 $8024 $8026 $8026 $8026 $8026 $8026 $802C $802E $8026 $8026 $8026 $8026 $8026 $C024 $4022
.dw $8002 $8004 $8004 $8004 $8004 $8004 $8004 $800C $800E $8004 $8004 $8004 $8004 $8004 $8004 $C002

.ENDS
