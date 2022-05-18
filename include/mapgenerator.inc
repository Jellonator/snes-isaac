.BANK 1 SLOT "ROM"
.SECTION "MapGeneratorCode" FREE

; zeropage values
.ENUM $0002
    start_pos INSTANCEOF maptilepos_t
    mapgenNumAvailableRooms db
    mapgenNumAvailableEndpointRooms db
    mapgenAvailableRooms INSTANCEOF maptilepos_t MAX_MAP_SLOTS
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

; push tile in A to available rooms
_PushTile:
    .ACCU 8
    .INDEX 8
    ldx.w mapgenNumAvailableRooms
    sta.w mapgenAvailableRooms,x
    inx
    stx.w mapgenNumAvailableRooms
    rts

; Initialize the tile at X
_AddTile:
    .ACCU 8
    .INDEX 8
    lda #ROOMTYPE_NORMAL
    sta.w mapTileTypeTable,X
    stz.w mapTileFlagsTable,X
    ; TODO: get map tile slot
    rts

_PushAdjacentEmptyTiles:
    .ACCU 8
    .INDEX 8
    .BranchIfTileOnRightBorderA @skipRight
        inc A
        tax
        .BranchIfTileFilledX @@skipPush
            jsr _PushTile
        @@skipPush:
        dec A
    @skipRight:
    .BranchIfTileOnLeftBorderA @skipLeft
        dec A
        tax
        .BranchIfTileFilledX @@skipPush
            jsr _PushTile
        @@skipPush:
        inc A
    @skipLeft:
    .BranchIfTileOnBottomBorderA @skipBottom
        clc
        adc #$10
        tax
        .BranchIfTileFilledX @@skipPush
            jsr _PushTile
        @@skipPush:
        sec
        sbc #$10
    @skipBottom:
    .BranchIfTileOnTopBorderA @skipTop
        sec
        sbc #$10
        tax
        .BranchIfTileFilledX @@skipPush
            jsr _PushTile
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
    .ChangeDataBank #$7E
    ; First, choose starting tile
    jsl RngGeneratorUpdate4
    sep #$30 ; 8 bit AXY
    and #$07
    clc
    adc #4 ; X: [4-11]
    sta start_pos
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
    adc start_pos
    sta start_pos
    tax
    jsr _AddTile
    jsr _PushAdjacentEmptyTiles

    lda #$FF
    sta.w numTilesToUpdate
    ; END: reset data bank
    plb
    rtl

_ClearMap:
    sep #$30 ; 8 bit
    stz.w loword(numUsedMapSlots)
    stz.w loword(numTilesToUpdate)
    stz.w mapgenNumAvailableRooms
    stz.w mapgenNumAvailableEndpointRooms
    .ClearWRam mapTileTypeTable, MAP_MAX_SIZE
    .ClearWRam mapTileFlagsTable, MAP_MAX_SIZE
    .ClearWRam mapTileSlotTable, MAP_MAX_SIZE
    rts

.ENDS