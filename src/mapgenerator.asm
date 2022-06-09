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

.DEFINE TempDoorMask $20
.DEFINE TempAddr $22
.DEFINE TempValue $27

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
_InitializeRoomX:
    .ACCU 8
    .INDEX 8
    pha ; >1
; set up map data
    lda #ROOMTYPE_NORMAL
    sta.w mapTileTypeTable,X
    stz.w mapTileFlagsTable,X
    lda.w numUsedMapSlots
    sta.w loword(mapTileSlotTable),X
    inc.w numUsedMapSlots
; set up room slot data
    phx ; >1
    tax ; X now contains tile slot
    lda $01,S
    sta roomSlotMapPos,X
    lda #ROOMTYPE_NORMAL
    sta roomSlotRoomType,X
    lda #ROOM_SIZE_REGULAR
    sta roomSlotRoomSize,X
    plx ; <1
; end
    pla ; <1
    rts

; Setup the room at tile position X
_SetupRoomX:
    .INDEX 8
    .ACCU 8
    phy ; >1
    pha ; >1
    lda mapTileSlotTable,X
    phx ; >1 $02,S contains tile position [db]
    pha ; >1 $01,S contains room slot [db]
; First, determine door mask
    stz TempDoorMask
    lda $02,s
    .BranchIfTileOnLeftBorderA +
        dex
        .BranchIfTileEmptyX +
            lda TempDoorMask
            ora #DOOR_DEF_LEFT
            sta TempDoorMask
    +:
    lda $02,s
    .BranchIfTileOnRightBorderA +
        inc A
        tax
        .BranchIfTileEmptyX +
            lda TempDoorMask
            ora #DOOR_DEF_RIGHT
            sta TempDoorMask
    +:
    lda $02,s
    .BranchIfTileOnTopBorderA +
        sec
        sbc #MAP_MAX_WIDTH
        tax
        .BranchIfTileEmptyX +
            lda TempDoorMask
            ora #DOOR_DEF_UP
            sta TempDoorMask
    +:
    lda $02,s
    .BranchIfTileOnBottomBorderA +
        clc
        adc #MAP_MAX_WIDTH
        tax
        .BranchIfTileEmptyX +
            lda TempDoorMask
            ora #DOOR_DEF_DOWN
            sta TempDoorMask
    +:
    lda $01,s
    tax
    lda TempDoorMask
    sta roomSlotDoorMask,X
; Set up actual room
    jsr _PushRandomRoomFromPool ; >3
    jsl InitializeRoomSlot
    rep #$20 ; 16b A
    pla ; <2
    pla ; <2
    sep #$30 ; 8b AXY
; end
    plx ; <1
    pla ; <1
    ply ; <1
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
; Setup rooms
    sep #$30 ; 8b AXY
    ldy numUsedMapSlots
@loop_setup_tiles:
    ldx loword(roomSlotMapPos-1),Y
    jsr _SetupRoomX
    sep #$30 ; 8b AXY
    dey
    bne @loop_setup_tiles
; end
    lda #$FF
    sta.w numTilesToUpdate
    ; END: reset data bank
    plb
    rtl

_PushRandomRoomFromPool:
    rep #$30 ; 16b AXY
; Get RNG value
    jsl RngGeneratorUpdate8
    sta.l DIVU_DIVIDEND
; Put pointer in X
; For efficiency, X starts at size*3, and accesses use X-3
    lda.l RoomPoolDefinitions@basement.numRooms ; byte 0 is size
    and #$FF
    sta TempValue
    asl
    clc
    adc.l TempValue
    tax
    sep #$20 ; 8b A
    ldy #0 ; Y counts number of valid rooms
    dec TempValue ; TempValue is index of current element (i.e. X/3 - 1)
; Find rooms with matching door mask, and put their indices into tempData
@loop:
    rep #$20 ; 16b A
    lda.l RoomPoolDefinitions@basement.roomList-3,X
    sta TempAddr
    sep #$20 ; 8b A
    lda.l RoomPoolDefinitions@basement.roomList+2-3,X
    sta TempAddr+2
    ; Ensure that RoomMask is a subset of DefMask
    ; Need to check that RoomMask & DefMask = RoomMask
    ; Need to check that (RoomMask)(DefMask) xor (RoomMask)(1) = 0
    ; (RoomMask)(1 xor DefMask) = 0
    lda [TempAddr] ; get DefMask
    ; eor #$0F
    and TempDoorMask
    cmp TempDoorMask
    bne @skip
    lda TempValue
    sta.w loword(tempData),Y
    iny
@skip:
    dec TempValue
    dex
    dex
    dex
    bne @loop
; Apply RNG (rand() % Y)
    tya
    sta.l DIVU_DIVISOR
    .REPT 8
        NOP ; (8 * 2 cycle)
    .ENDR
    rep #$20 ; 16b A
    lda.l DIVU_REMAINDER ; index into tempData
    tax
    stz.w loword(tempData)+1,X ; Need to make next byte 0 so that it doesn't get added to 16b result
    lda.w loword(tempData),X
    asl
    clc
    adc.w loword(tempData),X
    tax ; X now contains index into RoomPoolDefinitions@basement.roomList
    sep #$20 ; 8b A
    lda.l RoomPoolDefinitions@basement+3,X ; bank
    ply ; <2 pull return address
    pha ; >1
    rep #$20 ; 16b A
    lda.l RoomPoolDefinitions@basement+1,X ; addr
    pha ; >2
    phy ; >2 push return address
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
    .ClearWRam_ZP _mapDoorHorizontalEmptyBuf, (MAP_MAX_SIZE*2 + MAP_MAX_WIDTH + MAP_MAX_HEIGHT)
    pld
    rts

.ENDS