.BANK 1 SLOT "ROM"
.SECTION "MapGeneratorCode" FREE

; zeropage values
.ENUM $0010
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
    iny
    stx.b mapgenAvailableTiles,Y
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
    lda #ROOMTYPE_NORMAL
    sta.w mapTileTypeTable,X
    stz.w mapTileFlagsTable,X
    ; TODO: get map tile slot
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
            txa
        @@skipPush:
        dec A
    @skipRight:
    .BranchIfTileOnLeftBorderA @skipLeft
        dec A
        tax
        .BranchIfTileFilledX @@skipPush
        .BranchIfTileAlreadyInAvailableTilesX @@skipPush
            jsr _PushAvailableTileX
            txa
        @@skipPush:
        inc A
    @skipLeft:
    .BranchIfTileOnBottomBorderA @skipBottom
        clc
        adc #$10
        tax
        .BranchIfTileFilledX @@skipPush
        .BranchIfTileAlreadyInAvailableTilesX @@skipPush
            jsr _PushAvailableTileX
            txa
        @@skipPush:
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
            txa
        @@skipPush:
        clc
        adc #$10
    @skipTop:
    rts

BeginMapGeneration:
    phb ; push Databank
    sep #$30 ; 8 bit
@retry:
    jsr _ClearMap
    ; Map generator primarily operates on RAM, so we change data bank to $7E
    .ChangeDataBank $7E
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
    tax
    jsr _InitializeRoomX
    lda.b start_pos
    jsr _PushAdjacentEmptyTilesA
    ldy #16 ; make 10 tiles
@loop_add_tiles: ; do {
        ; First, get random tile
        jsl RngGeneratorUpdate8
        .ACCU 16 ; Rng changes A to 16
            ; .ChangeDataBank $00
            sta.l DIVU_DIVIDEND
            sep #$30 ; 8 bit AXY
            lda.b mapgenNumAvailableTiles
            sta.l DIVU_DIVISOR
            ; Have to wait 16 cycles for division to finish
            dey ;  2
            phy ; +3 = 5
            ply ; +4 = 9
            phy ; +3 = 12
            nop
            nop
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
    cpy #0
    bne @loop_add_tiles ; } while (--Y != 0);

    lda #$FF
    sta.w numTilesToUpdate
    ; END: reset data bank
    plb
    rtl

_ClearMap:
    sep #$30 ; 8 bit
    stz.w numUsedMapSlots
    stz.w numTilesToUpdate
    stz.b mapgenNumAvailableTiles
    stz.b mapgenNumAvailableEndpointTiles
    .ClearWRam mapTileTypeTable, MAP_MAX_SIZE
    .ClearWRam mapTileFlagsTable, MAP_MAX_SIZE
    .ClearWRam mapTileSlotTable, MAP_MAX_SIZE
    rts

.ENDS