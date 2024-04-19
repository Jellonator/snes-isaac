.include "base.inc"

.BANK ROMBANK_GROUNDCODE SLOT "ROM"
.SECTION "GroundCode" FREE

; Each tile of character data:
;     bp 0     bp 1
; dsw 00000000 11111111
; dsw 00000000 11111111
; dsw 00000000 11111111
; dsw 00000000 11111111
; dsw 00000000 11111111
; dsw 00000000 11111111
; dsw 00000000 11111111
; dsw 00000000 11111111
;     01234567 01234567
; 16 BYTE per tile
;  8 WORD per tile
; character data is stored as 24x16 tiles

_PxDataTbl_End:
    .db %10000000
    .db %11000000
    .db %11100000
    .db %11110000
    .db %11111000
    .db %11111100
    .db %11111110
    .db %11111111

_PxDataTbl_Start:
    .db %11111111
    .db %01111111
    .db %00111111
    .db %00011111
    .db %00001111
    .db %00000111
    .db %00000011
    .db %00000001

GroundFullUpdate:
    sep #$20
    lda #1
    sta.l needResetEntireGround
    rtl

GroundReset:
    sep #$20
    lda #1
    sta.l needResetEntireGround
    ; jmp GroundOpClear

GroundOpClear:
    rep #$20
    lda #0
    sta.l groundOpListStart
    sta.l groundOpListEnd
    .REPT 32*2 INDEX i
        sta.l groundTilesInList + i * 2
    .ENDR
    ; write character data
    rep #$20 ; 16 bit A
    lda #24 * 16 * 8 * 2
    sta DMA0_SIZE ; number of bytes
    lda #loword(spritedata.basement_ground_base)
    sta DMA0_SRCL ; source address
    lda #groundCharacterData
    sta WMADDL
    sep #$20 ; 8 bit A
    lda #bankbyte(spritedata.basement_ground_base)
    sta DMA0_SRCH ; source bank
    lda #$7F
    sta WMADDH
    lda #%00000000
    sta DMA0_CTL ; auto increment, 1 byte at a time
    lda #$80
    sta DMA0_DEST ; Write to WRAM
    lda #$01
    sta MDMAEN ; begin transfer
    rtl

_BitTbl:
    .db %00000001
    .db %00000010
    .db %00000100
    .db %00001000
    .db %00010000
    .db %00100000
    .db %01000000
    .db %10000000

.DEFINE tile_row $00
.DEFINE tileinner_row $02
.DEFINE line_byte $04
.DEFINE tmp $06
.DEFINE start_i $08
.DEFINE end_i $0A
.DEFINE start_subi $0C
.DEFINE end_subi $0E
.DEFINE bytei $10
.DEFINE tile_index $12
.DEFINE tmp2 $14

_AddTileToQueue:
    rep #$30
; determine if we need to skip
    lda.b tile_index
    and #$0007
    tax
    lda.l _BitTbl,X
    sta.b tmp
    lda.b tile_index
    lsr
    lsr
    lsr
    tax
    lda.w loword(groundTilesInList),X
    and.b tmp
    and #$00FF
    beq +
        jmp @skipThis
    +:
; set bit
    lda.w loword(groundTilesInList),X
    ora.b tmp
    sta.w loword(groundTilesInList),X
; set palette
    ldx.w loword(groundOpListEnd)
    lda.w loword(groundOpList_palette),X
    xba
    and #$FF00
    sta.b tmp
; Add tile to minivqueue
    lda.l vqueueNumMiniOps
    inc A
    sta.l vqueueNumMiniOps
    dec A
    asl
    asl
    tax
    lda.b tile_index
    clc
    adc #BG3_TILE_BASE_ADDR
    clc
    adc #32*8+4
    sta.w vqueueMiniOps.1.vramAddr,X
    lda.b bytei
    lsr
    lsr
    lsr
    lsr
    ora.b tmp
    sta.w vqueueMiniOps.1.data,X
; Add character data to vqueue
    ; get vqueue index
    lda.l vqueueNumOps
    asl
    asl
    asl
    tay
    ; inc vqueue index
    lda.l vqueueNumOps
    inc A
    sta.l vqueueNumOps
    ; set param, bAddr for vmem
    sep #$20
    lda #VQUEUE_MODE_VRAM
    sta.w loword(vqueueOps.1.mode),Y
    ; set aAddr bank
    lda #$7F
    sta.w loword(vqueueOps.1.aAddr+2),Y
    ; vram_addr = (row * 8 * 3 + column) * 8
    rep #$20
    lda.b bytei
    and #$FFF0
    lsr
    sta.w loword(vqueueOps.1.vramAddr),Y
    ; aAddr = 2 * vram_addr + groundCharacterData
    asl
    clc
    adc #loword(groundCharacterData)
    sta.w loword(vqueueOps.1.aAddr),Y
    ; numBytes = 16
    lda #16
    sta.w loword(vqueueOps.1.numBytes),Y
@skipThis:
    rts

GroundProcessOps:
    phb
    .ChangeDataBank $7F
; start
    rep #$30
    lda.w loword(groundOpListEnd)
    cmp.w loword(groundOpListStart)
    bne @loop
    jmp @end
    @loop:
        tax
    ; determine line byte
; tilebyte_index = (line / 8) * 16 * 24 + ((line % 8) * 2)
        ; tile_row = line / 8
        lda.w loword(groundOpList_line),X
        and #$00FF
        .DivideStatic 8
        sta.b tile_row
        ; tileinner_row = line % 8
        lda.w loword(groundOpList_line),X
        and #$0007
        sta.b tileinner_row
        ; line_byte = tileinner_row * 2
        asl
        sta.b line_byte
        ; line_byte += tile_row * 24 * 16B
        lda.b tile_row
        ; xba
        asl
        asl
        asl
        asl
        asl
        asl
        asl
        sta.b tmp
        asl
        clc
        adc.b tmp
        adc.b line_byte
        sta.b line_byte
    ; determine start/end indices
; start_index = startpx / 8 
; end_index = endpx / 8
        lda.w loword(groundOpList_startPx),X
        and #$00FF
        .DivideStatic 8
        sta.b start_i
        lda.w loword(groundOpList_endPx),X
        and #$00FF
        .DivideStatic 8
        sta.b end_i
        lda.w loword(groundOpList_startPx),X
        and #$0007
        sta.b start_subi
        lda.w loword(groundOpList_endPx),X
        and #$0007
        sta.b end_subi
    ; begin
; tilebyte_index += start_index * 16
        lda.b start_i
        .MultiplyStatic 16
        clc
        adc.b line_byte
        sta.b bytei
; tile_index = (line / 8) * 32 + (pixel / 8)
        lda.b tile_row
        .MultiplyStatic 32
        clc
        adc.b start_i
        sta.b tile_index
; if start_index == end_index:
        lda.b start_i
        cmp.b end_i
        bne @differentTiles
        ; same tile:
;   value = _PxDataTbl_Start[start_index % 8] & _PxDataTbl_End[end_index % 8]
            ldx.b start_subi
            sep #$20
            lda.l _PxDataTbl_Start,X
            ldx.b end_subi
            and.l _PxDataTbl_End,X
            sta.b tmp2
;   tiles[tilebyte_index] |= value
            ldy.b bytei

            lda.w loword(groundCharacterData),Y
            eor.b tmp2
            sta.b tmp

            lda.w loword(groundCharacterData)+1,Y
            pha
            ora.b tmp2
            sta.w loword(groundCharacterData)+1,Y

            pla
            and.b tmp2
            ora.b tmp
            sta.w loword(groundCharacterData),Y
;   tilepalettes[tile_index] = palette
            jsr _AddTileToQueue
            rep #$20
;   return
            jmp @nextOp
        @differentTiles:
; tiles[tilebyte_index] |= _PxDataTbl_Start[start_index % 8]
            sep #$20
            ldx.b start_subi
            ldy.b bytei

            lda.w loword(groundCharacterData),Y
            eor.l _PxDataTbl_Start,X
            sta.b tmp

            ; H = (H | C)
            lda.w loword(groundCharacterData)+1,Y
            pha
            ora.l _PxDataTbl_Start,X
            sta.w loword(groundCharacterData)+1,Y

            ; L = (L xor C) | (H & C)
            pla
            and.l _PxDataTbl_Start,X
            ora.b tmp
            sta.w loword(groundCharacterData),Y

            jsr _AddTileToQueue
            rep #$20
; ++ start_index;
            inc.b start_i
            inc.b tile_index
; tilebyte_index += 16
            lda.b bytei
            clc
            adc #16
            sta.b bytei
; while start_index < end_index:
            lda.b start_i
            cmp.b end_i
            beq @inner_loop_end
            @inner_loop:
;   tiles[tilebyte_index] |= 0xFF
                sep #$20
                ldx.b bytei

                lda.w loword(groundCharacterData),X
                eor #$FF
                ora.w loword(groundCharacterData)+1,X
                sta.w loword(groundCharacterData),X

                lda #$FF
                sta.w loword(groundCharacterData)+1,X

                jsr _AddTileToQueue
                rep #$20
;   tilebyte_index += 16
                lda.b bytei
                clc
                adc #16
                sta.b bytei
;   ++ start_index;
            ; maybe continue loop?
                inc.b start_i
                inc.b tile_index
                lda.b start_i
                cmp.b end_i
                bne @inner_loop
            @inner_loop_end:
; tiles[tilebyte_index] |= _PxDataTbl_End[end_index % 8]
            sep #$20
            ldx.b end_subi
            ldy.b bytei

            lda.w loword(groundCharacterData),Y
            eor.l _PxDataTbl_End,X
            sta.b tmp

            lda.w loword(groundCharacterData)+1,Y
            pha
            ora.l _PxDataTbl_End,X
            sta.w loword(groundCharacterData)+1,Y

            pla
            and.l _PxDataTbl_End,X
            ora.b tmp
            sta.w loword(groundCharacterData),Y

            jsr _AddTileToQueue
            rep #$20
    ; next index
    @nextOp:
        lda.w loword(groundOpListEnd)
        inc A
        and #MAX_GROUND_OPS-1
        sta.w loword(groundOpListEnd)
        cmp.w loword(groundOpListStart)
        beq @end
        jmp @loop
; end
@end:
    jsr _ClearTiles
    plb
    rtl

_ClearTiles:
    .REPT 32*2 INDEX i
        stz.w loword(groundTilesInList) + i * 2
    .ENDR
    rts

; Parameters:
; pixel (x-pos) [db] $07
; line  (y-pos) [db] $06
; length        [db] $05
; palette       [db] $04
GroundAddOp:
    rep #$30
    lda.l groundOpListStart
    tax
    sep #$20
    ; set line
    ; only allow lines 64-192, subtract 64
    lda $06
    sec
    sbc #64
    sta.l groundOpList_line,X
    bmi @skipAdd
    ; only allow x positions 32-224
    lda $07
    cmp #224
    bcs @skipAdd
    .AMAXU P_IMM, 32
    sec
    sbc #32
    sta.l groundOpList_startPx,X
    lda $07
    clc
    adc $05
    cmp #32
    bcc @skipAdd
    .AMINU P_IMM, 224
    .AMAXU P_IMM, 32
    sec
    sbc #32
    cmp.l groundOpList_startPx,X
    bcc @skipAdd
    sta.l groundOpList_endPx,X
    lda $04
    sta.l groundOpList_palette,X
    ; add to list
    rep #$30
    txa
    inc A
    and #MAX_GROUND_OPS-1
    sta.l groundOpListStart
@skipAdd:
    rtl

.ENDS