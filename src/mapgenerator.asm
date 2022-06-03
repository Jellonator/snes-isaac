.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "MapGeneratorCode" FREE

; zeropage values
.ENUM $0060
    start_pos INSTANCEOF maptilepos_t
    mapgenNumAvailableTiles db
    mapgenNumAvailableEndpointTiles db
    mapgenAvailableTiles INSTANCEOF maptilepos_t MAX_MAP_SLOTS
.ENDE

; Check if tile pos is valid; that is, Y<10
; Assume tile is in A
.MACRO .CheckTilePosValidA
    cmp #$A0
.ENDM

; Branch if tile pos is valid
.MACRO .BranchIfTilePosValid ARGS label
    bcc label
.ENDM

; Branch if tile pos is not valid
.MACRO .BranchIfTilePosInvalid ARGS label
    bcs label
.ENDM

; Branch if tile is on left border
; Assume tile is in A
.MACRO .BranchIfTileOnLeftBorderA ARGS label
    bit #$0F
    beq label
.ENDM

; Branch if tile is on right border
; Assume tile is in A
.MACRO .BranchIfTileOnRightBorderA ARGS label
    inc A
    bit #$0F
    bne @@@@@\.\@
    dec A
    bra label
@@@@@\.\@:
    dec A
.ENDM

; Branch if tile is on top border
; Assume tile is in A
.MACRO .BranchIfTileOnTopBorderA ARGS label
    bit #$F0
    beq label
.ENDM

; Branch if tile is on bottom border
; Assume tile is in A
.MACRO .BranchIfTileOnBottomBorderA ARGS label
    cmp #$90
    bcs label
.ENDM

; Branch if tile is empty
; Assumes tile is in X
; Tile type is stored in A
.MACRO .BranchIfTileEmptyX ARGS label
    lda.w mapTileTypeTable,X
    beq label ; if mapTileTypeTable[X] == 0
.ENDM

; Branch if tile is not empty
; Assumes tile is in X
; Tile type is stored in A
.MACRO .BranchIfTileFilledX ARGS label
    lda.w mapTileTypeTable,X
    bne label ; if mapTileTypeTable[X] == 0
.ENDM

; Branch if tile is already in the available rooms table
; Assumes tile is in X
; Tile flag is stored in A
.MACRO .BranchIfTileAlreadyInAvailableTilesX ARGS label
    lda.w mapTileFlagsTable,X
    bit #MAPTILE_AVAILABLE
    bne label
.ENDM

; i = 0, j = len(tiles)-1
; while (i <= j) {
;   if (isEndpoint(tiles[i]) {
;       // i is endpoint, j may or may not be endpoint
;       ++i;
;   }
;   else if (isEndpoint(tiles[j])) {
;       // i is not endpoint, j is endpoint
;       swap(&tiles[i], &tiles[j]);
;       ++i;
;       --j;
;   }
;   else {
;       // i is not endpoint, j is not endpoint
;       --j;
;   }
; }
; if (isEndpoint(tiles[i])) {
;   numEndpoints = i+1;
; }
; else {
;   numEndpoints = i;
; }
_CalculateAvailableEndpointTiles:
    .ACCU 8
    .INDEX 8
    stz.b mapgenNumAvailableEndpointTiles
    lda.b mapgenNumAvailableTiles
    beq @end
    stz $00 ; $00=i
    dec A
    ; beq @endloop ; len == 1
    sta $01 ; $01=j
@loop:
    ; Count rooms adjacent to i
    ldy $00
    lda.w mapgenAvailableTiles,Y
    jsr _CountAdjacentFilledRoomsA
    ldy $03
    cpy #1 ; Check that there is exactly ONE room next to i
    beq @isEndpoint_i
    ; Count rooms adjacent to j
    ldy $01
    lda.w mapgenAvailableTiles,Y
    jsr _CountAdjacentFilledRoomsA
    ldy $03
    cpy #1 ; Check that there is exactly ONE room next to j
    beq @isEndpoint_j
    ; neither i nor j are endpoints
    dec $01
    jmp @continue
@isEndpoint_i:
    ; i is endpoint
    inc.b mapgenNumAvailableEndpointTiles
    inc $00
    jmp @continue
@isEndpoint_j:
    ; j is endpoint but i is not, so swap and inc i/dec j
    inc.b mapgenNumAvailableEndpointTiles
    ldx $00
    lda.b mapgenAvailableTiles,X
    sta $07
    ldx $01
    lda.b mapgenAvailableTiles,X
    sta $08
    lda $07
    ldx $01
    sta.b mapgenAvailableTiles,X
    lda $08
    ldx $00
    sta.b mapgenAvailableTiles,X
    ; pha
    ; lda.w mapgenAvailableTiles,Y
    ; sta.b mapgenAvailableTiles,X
    ; pla
    ; sta.w mapgenAvailableTiles,Y
    inc $00
    dec $01
    ; jmp @continue <- it is here in spirit
@continue:
    ; Repeat if (j >= i)
    lda $00
    cmp $01
    bcc @loop
@endloop:
    ; lda $00
    ; sta.b mapgenNumAvailableEndpointTiles
    ; Count rooms adjacent to i
    ldy $00
    lda.w mapgenAvailableTiles,Y
    jsr _CountAdjacentFilledRoomsA
    ldy $03
    cpy #1 ; Check that there is exactly ONE room next to i
    bne @end
    inc.b mapgenNumAvailableEndpointTiles
@end:
    rts

; Removes the room at mapgenAvailableTiles[X]
; Consumes Y and A
_RemoveAvailableTileX:
    .ACCU 8
    .INDEX 8
    ldy.b mapgenNumAvailableTiles
    dey
    sty.b mapgenNumAvailableTiles
    lda.w mapgenAvailableTiles,Y
    sta.b mapgenAvailableTiles,X
    rts

; push tile in X to available rooms
; consumes A and Y
_PushAvailableTileX:
    .ACCU 8
    .INDEX 8
    ldy.b mapgenNumAvailableTiles
    stx.b mapgenAvailableTiles,Y
    iny
    sty.b mapgenNumAvailableTiles
    lda.w mapTileFlagsTable,X
    ora #MAPTILE_AVAILABLE
    sta.w mapTileFlagsTable,X
    rts

; Initialize the tile at X
; consumes A
_InitializeRoomX:
    .ACCU 8
    .INDEX 8
    pha ; A [db]
    lda #ROOMTYPE_NORMAL
    sta.w mapTileTypeTable,X
    stz.w mapTileFlagsTable,X
    phy ; Y [db]
    phx ; tile position [db]
    lda.w numUsedMapSlots
    inc.w numUsedMapSlots
    sta.w loword(mapTileSlotTable),X
    pha ; room slot [db]
    ; lda #bankbyte(RoomDefinitionTest)
    ; pha ; room definition bank [db]
    ; pea loword(RoomDefinitionTest) ; room definiton address [dw]
    jsr _PushRandomRoomFromPool
    jsl InitializeRoomSlot
    sep #$30 ; 8 bit AXY
    pla ; [db]
    pla ; [db]
    pla ; [db]
    pla ; [db]
    plx ; [db]
    ply ; [db]
    pla ; [db]
    rts

; Count tiles adjacent to A
; consumes X
; Stores result into $03
_CountAdjacentFilledRoomsA:
    .ACCU 8
    .INDEX 8
    sta $02
    stz $03
    .BranchIfTileOnRightBorderA +
        inc A
        tax
        .BranchIfTileEmptyX +
            inc $03
    +:
    lda $02
    .BranchIfTileOnLeftBorderA +
        dec A
        tax
        .BranchIfTileEmptyX +
            inc $03
    +:
    lda $02
    .BranchIfTileOnBottomBorderA +
        clc
        adc #$10
        tax
        .BranchIfTileEmptyX +
            inc $03
    +:
    lda $02
    .BranchIfTileOnTopBorderA +
        sec
        sbc #$10
        tax
        .BranchIfTileEmptyX +
            inc $03
    +:
    rts

; Push tiles adjacent to A
; consumes X
_PushAdjacentEmptyTilesA:
    .ACCU 8
    .INDEX 8
    .BranchIfTileOnRightBorderA @skipRight
        inc A
        tax
        .BranchIfTileFilledX @@skipPush
        .BranchIfTileAlreadyInAvailableTilesX @@skipPush
            jsr _PushAvailableTileX
        @@skipPush:
        txa
        dec A
    @skipRight:
    .BranchIfTileOnLeftBorderA @skipLeft
        dec A
        tax
        .BranchIfTileFilledX @@skipPush
        .BranchIfTileAlreadyInAvailableTilesX @@skipPush
            jsr _PushAvailableTileX
        @@skipPush:
        txa
        inc A
    @skipLeft:
    .BranchIfTileOnBottomBorderA @skipBottom
        clc
        adc #$10
        tax
        .BranchIfTileFilledX @@skipPush
        .BranchIfTileAlreadyInAvailableTilesX @@skipPush
            jsr _PushAvailableTileX
        @@skipPush:
        txa
        sec
        sbc #$10
    @skipBottom:
    .BranchIfTileOnTopBorderA @skipTop
        sec
        sbc #$10
        tax
        .BranchIfTileFilledX @@skipPush
        .BranchIfTileAlreadyInAvailableTilesX @@skipPush
            jsr _PushAvailableTileX
        @@skipPush:
        txa
        clc
        adc #$10
    @skipTop:
    rts

BeginMapGeneration:
    phb ; push Databank
    sep #$30 ; 8 bit
    ; Map generator primarily operates on RAM, so we change data bank to $7E
    .ChangeDataBank $7E
@retry:
    jsr _ClearMap
    ; First, choose starting tile
    jsl RngGeneratorUpdate4
    sep #$30 ; 8 bit AXY
    and #$07
    clc
    adc #4 ; X: [4-11]
    sta.b start_pos
    jsl RngGeneratorUpdate4
    sep #$30 ; 8 bit AXY
    and #$07
    clc
    adc #1 ; Y: [1-8]
    asl
    asl
    asl
    asl
    clc
    adc.b start_pos
    sta.b start_pos
    sta.w loadedRoomIndex
    tax
    jsr _InitializeRoomX
    lda.b start_pos
    jsr _PushAdjacentEmptyTilesA
    ldy #64
@loop_add_tiles: ; do {
    phy
        ; Determine endpoint tiles
        jsr _CalculateAvailableEndpointTiles
        ; First, get random tile
        jsl RngGeneratorUpdate8
        .ACCU 16 ; Rng changes A to 16
            ; .ChangeDataBank $00
            sta.l DIVU_DIVIDEND
            sep #$30 ; 8 bit AXY
            lda.b mapgenNumAvailableEndpointTiles
            bne @dontUseAllTiles
            lda.b mapgenNumAvailableTiles
        @dontUseAllTiles:
            sta.l DIVU_DIVISOR
            ; Have to wait 16 cycles for division to finish
            .REPT 8
                nop
            .ENDR
            lda.l DIVU_REMAINDER ; Only need low byte
            ; .ChangeDataBank $7E
        sta $04 ; $04 is index into mapgenAvailableTiles
        ; Get tilepos_t
        ldy $04
        ldx.b mapgenAvailableTiles,Y
        stx $05 ; $05 is tilepos_t
        ; Remove available room
        ldx $04
        jsr _RemoveAvailableTileX
        ; Push room
        ldx $05
        jsr _InitializeRoomX
        lda $05
        jsr _PushAdjacentEmptyTilesA
    ply
    dey
    cpy #0
    bne @loop_add_tiles ; } while (--Y != 0);

    lda #$FF
    sta.w numTilesToUpdate
    ; END: reset data bank
    plb
    rtl

_PushRandomRoomFromPool:
    rep #$30 ; 16b AXY
    ply
    jsl RngGeneratorUpdate8
    sta.l DIVU_DIVIDEND
    sep #$20 ; 8b A
    lda.l RoomPoolDefinitions@basement ; pool size
    sta.l DIVU_DIVISOR
    .REPT 7
        NOP ; (7 * 2 cycle)
    .ENDR
    rep #$20 ; 16b A (3 cycle)
    lda.l DIVU_REMAINDER
    asl
    clc
    adc.l DIVU_REMAINDER
    tax
    sep #$20 ; 8b A
    lda.l RoomPoolDefinitions@basement+3,X ; bank
    pha
    rep #$20 ; 16b A
    lda.l RoomPoolDefinitions@basement+1,X ; addr
    pha
    phy
    rts

_ClearMap:
    phd
    pea $4300
    pld
    sep #$30 ; 8 bit
    stz.w numUsedMapSlots
    stz.w numTilesToUpdate
    stz.w mapgenNumAvailableTiles
    stz.w mapgenNumAvailableEndpointTiles
    .ClearWRam_ZP mapTileTypeTable, MAP_MAX_SIZE
    .ClearWRam_ZP mapTileFlagsTable, MAP_MAX_SIZE
    .ClearWRam_ZP mapTileSlotTable, MAP_MAX_SIZE
    pld
    rts

.ENDS