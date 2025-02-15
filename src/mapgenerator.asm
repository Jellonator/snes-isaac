.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "MapGeneratorCode" FREE

; zeropage values
.ENUM $0070
    start_pos INSTANCEOF maptilepos_t
    mapgenNumAvailableTiles db
    mapgenNumUsedTiles db
    mapgenNumAvailableEndpointTiles db
    mapgenAvailableTiles INSTANCEOF maptilepos_t MAX_MAP_SLOTS
    mapgenUsedTiles INSTANCEOF maptilepos_t MAX_MAP_SLOTS
    currentRoomPoolBase dl
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

.MACRO ._UpdateDoors ARGS newValue
    ; west door
    lda.w loword(mapDoorHorizontal)-1,X
    beq +
        lda #newValue
        sta.w loword(mapDoorHorizontal)-1,X
    +:
    ; east door
    lda.w loword(mapDoorHorizontal),X
    beq +
        lda #newValue
        sta.w loword(mapDoorHorizontal),X
    +:
    ; north door
    lda.w loword(mapDoorVertical-MAP_MAX_WIDTH),X
    beq +
        lda #newValue
        sta.w loword(mapDoorVertical-MAP_MAX_WIDTH),X
    +:
    ; south door
    lda.w loword(mapDoorVertical),X
    beq +
        lda #newValue
        sta.w loword(mapDoorVertical),X
    +:
.ENDM

_CmpRoomsByAvailableEndpointTiles:
    .INDEX 16
    .ACCU 16
    sep #$30
    phx
    phy
    lda $01,S
    tax
    lda.w $0000,X
    jsr _CountAdjacentFilledRoomsA
    lda.b $03
    sta.b TempValue
    lda $02,S
    tax
    lda.w $0000,X
    jsr _CountAdjacentFilledRoomsA
    ply
    plx
    lda.b $03
    cmp.b TempValue
    rtl

.SortHeap_Build "SortRoomsByEndpointCount", _CmpRoomsByAvailableEndpointTiles, 8

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
    inc $00
    dec $01
    ; jmp @continue <- it is here in spirit
@continue:
    ; Repeat if (j >= i)
    lda $00
    cmp $01
    bcc @loop
@endloop:
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

; Similar to _CalculateAvailableEndpointTiles, except we only use tiles
; which are adjacent to the starting room
_CalculateAvailableStartingRoomEndpointTiles:
    .ACCU 8
    .INDEX 8
    lda.b start_pos
    sta.b $02
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
    jsr _IsTileAdjacent
    ldy $03
    cpy #1 ; Check that there is exactly ONE room next to i
    beq @isEndpoint_i
    ; Count rooms adjacent to j
    ldy $01
    lda.w mapgenAvailableTiles,Y
    jsr _IsTileAdjacent
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
    inc $00
    dec $01
    ; jmp @continue <- it is here in spirit
@continue:
    ; Repeat if (j >= i)
    lda $00
    cmp $01
    bcc @loop
@endloop:
    ; Count rooms adjacent to i
    ldy $00
    lda.w mapgenAvailableTiles,Y
    jsr _IsTileAdjacent
    ldy $03
    cpy #1 ; Check that there is exactly ONE room next to i
    bne @end
    inc.b mapgenNumAvailableEndpointTiles
@end:
    rts

; Similar to _CalculateAvailableEndpointTiles, except we only consider tiles
; which would create a new endroom
_CalculateNewEndpointTiles:
    .ACCU 8
    .INDEX 8
    stz.b mapgenNumAvailableEndpointTiles
    lda.b mapgenNumAvailableTiles
    bne +
        rts
    +:
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
    bne +
        ; check that target room has two or three adjacent rooms
        lda.b $04
        jsr _CountAdjacentFilledRoomsA
        ldy.b $03
        cpy #2
        beq @isEndpoint_i
        cpy #3
        beq @isEndpoint_i
    +:
    ; Count rooms adjacent to j
    ldy $01
    lda.w mapgenAvailableTiles,Y
    jsr _CountAdjacentFilledRoomsA
    ldy $03
    cpy #1 ; Check that there is exactly ONE room next to j
    bne +
        ; check that target room has two or three adjacent rooms
        lda.b $04
        jsr _CountAdjacentFilledRoomsA
        ldy.b $03
        cpy #2
        beq @isEndpoint_j
        cpy #3
        beq @isEndpoint_j
    +:
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
    inc $00
    dec $01
    ; jmp @continue <- it is here in spirit
@continue:
    ; Repeat if (j >= i)
    lda $00
    cmp $01
    bcc @loop
@endloop:
    ; Count rooms adjacent to i
    ldy $00
    lda.w mapgenAvailableTiles,Y
    jsr _CountAdjacentFilledRoomsA
    ldy $03
    cpy #1 ; Check that there is exactly ONE room next to i
    bne +
        ; check that target room has two or three adjacent rooms
        lda.b $04
        jsr _CountAdjacentFilledRoomsA
        ldy.b $03
        cpy #2
        beq @inctiles
        cpy #3
        beq @inctiles
    +:
    rts
@inctiles:
    inc.b mapgenNumAvailableEndpointTiles
    rts

_MoveActiveRoomsIntoUsedTiles:
    ; stz.b mapgenNumAvailableEndpointTiles
    ldx.w numUsedMapSlots
    stx.b mapgenNumUsedTiles
@loop_setup_tiles:
    lda.w loword(roomSlotMapPos-1),X
    sta.b mapgenUsedTiles-1,X
    dex
    bne @loop_setup_tiles
    rts

_FindValidSecretRoomLocations:
    sep #$30
    lda #0
    sta.b mapgenNumUsedTiles
    lda.b mapgenNumAvailableTiles
    sta.b $00
@loop:
    ; --i
    ldx.b $00
    beq @end
    dex
    stx.b $00
    ; check left
    lda.b mapgenAvailableTiles,X
    .BranchIfTileOnLeftBorderA +
        tay
        dey
        lda.w mapTileTypeTable,Y
        cmp #ROOMTYPE_BOSS
        beq @loop
        cmp #ROOMTYPE_SECRET
        beq @loop
    +:
    ; check right
    lda.b mapgenAvailableTiles,X
    .BranchIfTileOnRightBorderA +
        tay
        iny
        lda.w mapTileTypeTable,Y
        cmp #ROOMTYPE_BOSS
        beq @loop
        cmp #ROOMTYPE_SECRET
        beq @loop
    +:
    ; check top
    lda.b mapgenAvailableTiles,X
    .BranchIfTileOnTopBorderA +
        sec
        sbc #16
        tay
        lda.w mapTileTypeTable,Y
        cmp #ROOMTYPE_BOSS
        beq @loop
        cmp #ROOMTYPE_SECRET
        beq @loop
    +:
    ; check bottom
    lda.b mapgenAvailableTiles,X
    .BranchIfTileOnBottomBorderA +
        clc
        adc #16
        tay
        lda.w mapTileTypeTable,Y
        cmp #ROOMTYPE_BOSS
        beq @loop
        cmp #ROOMTYPE_SECRET
        beq @loop
    +:
    ; put
    ldy.b mapgenNumUsedTiles
    inc.b mapgenNumUsedTiles
    lda.b mapgenAvailableTiles,X
    sta.w mapgenUsedTiles,Y
    bra @loop
@end
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
; Parameters:
;     roomtype: db $03,S
_InitializeRoomX:
    .ACCU 8
    .INDEX 8
    pha ; >1
; set up map data
    lda $03+1,S
    cmp #ROOMTYPE_START
    ; bne + ; start becomes normal room
    ;     lda #ROOMTYPE_NORMAL
    ; +:
    sta.w mapTileTypeTable,X
    stz.w mapTileFlagsTable,X
    lda.w numUsedMapSlots
    sta.w loword(mapTileSlotTable),X
    inc.w numUsedMapSlots
; set up room slot data
    phx ; >1
    tax ; X now contains tile slot
    lda $01,S
    sta.w loword(roomSlotMapPos),X
    lda $03+2,S
    sta.w loword(roomSlotRoomType),X
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
    lda.w loword(mapTileSlotTable),X
    phx ; >1 $02,S contains tile position [db]
    pha ; >1 $01,S contains room slot [db]
; First, determine door mask
    stz TempDoorMask
    lda $02,s
    tay
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
            ; setup door to right
            ; TODO: improve algorithm
            lda #DOOR_TYPE_NORMAL | DOOR_OPEN | DOOR_METHOD_FINISH_ROOM
            sta.w loword(mapDoorHorizontal),Y
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
            ; setup door to bottom
            ; TODO: improve algorithm
            lda #DOOR_TYPE_NORMAL | DOOR_OPEN | DOOR_METHOD_FINISH_ROOM
            sta.w loword(mapDoorVertical),Y
    +:
    lda $01,s
    tax
    lda TempDoorMask
    sta.w loword(roomSlotDoorMask),X
; Set up actual room
    ; set pool according to room type
    lda.w loword(roomSlotRoomType),X
    cmp #ROOMTYPE_NORMAL
    beq @room_normal
    cmp #ROOMTYPE_START
    beq @room_empty
    cmp #ROOMTYPE_BOSS
    beq @room_boss
    cmp #ROOMTYPE_ITEM
    beq @room_item
    cmp #ROOMTYPE_SHOP
    beq @room_shop
    cmp #ROOMTYPE_SECRET
    beq @room_secret
    bra @room_empty ; uh oh; something has gone wrong probably. Just make it empty
    @room_normal:
        ; normal room type
        sep #$30
        lda #bankbyte(RoomPoolDefinitions@floor_basement)
        sta.b currentRoomPoolBase+2
        rep #$30 ; 16b AXY
        lda #loword(RoomPoolDefinitions@floor_basement)
        sta.b currentRoomPoolBase
        bra @end
    @room_boss:
        ; normal room type
        sep #$30
        lda #bankbyte(RoomPoolDefinitions@boss_basement)
        sta.b currentRoomPoolBase+2
        rep #$30 ; 16b AXY
        lda #loword(RoomPoolDefinitions@boss_basement)
        sta.b currentRoomPoolBase
        bra @end
    @room_item:
        ; item room type
        sep #$30
        lda #bankbyte(RoomPoolDefinitions@item)
        sta.b currentRoomPoolBase+2
        rep #$30 ; 16b AXY
        lda #loword(RoomPoolDefinitions@item)
        sta.b currentRoomPoolBase
        bra @end
    @room_shop:
        ; item room type
        sep #$30
        lda #bankbyte(RoomPoolDefinitions@shop)
        sta.b currentRoomPoolBase+2
        rep #$30 ; 16b AXY
        lda #loword(RoomPoolDefinitions@shop)
        sta.b currentRoomPoolBase
        bra @end
    @room_secret:
        ; item room type
        sep #$30
        lda #bankbyte(RoomPoolDefinitions@secret_room)
        sta.b currentRoomPoolBase+2
        rep #$30 ; 16b AXY
        lda #loword(RoomPoolDefinitions@secret_room)
        sta.b currentRoomPoolBase
        bra @end
    @room_empty:
        ; empty room type
        sep #$30
        lda #bankbyte(RoomPoolDefinitions@type_start)
        sta.b currentRoomPoolBase+2
        rep #$30 ; 16b AXY
        lda #loword(RoomPoolDefinitions@type_start)
        sta.b currentRoomPoolBase
        ; bra @end
    @end:
    ; select room from pool
    jsr _PushRandomRoomFromPool ; >3
    ; initialize room
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
; Stored an adjacent location in $04
_CountAdjacentFilledRoomsA:
    .ACCU 8
    .INDEX 8
    sta.b $02
    stz.b $03
    .BranchIfTileOnRightBorderA +
        inc A
        tax
        .BranchIfTileEmptyX +
            inc.b $03
            stx.b $04
    +:
    lda $02
    .BranchIfTileOnLeftBorderA +
        dec A
        tax
        .BranchIfTileEmptyX +
            inc.b $03
            stx.b $04
    +:
    lda $02
    .BranchIfTileOnBottomBorderA +
        clc
        adc #$10
        tax
        .BranchIfTileEmptyX +
            inc.b $03
            stx.b $04
    +:
    lda $02
    .BranchIfTileOnTopBorderA +
        sec
        sbc #$10
        tax
        .BranchIfTileEmptyX +
            inc.b $03
            stx.b $04
    +:
    rts

; Sets $03 to `1` if `A` is adjacent to $02
_IsTileAdjacent:
    .ACCU 8
    .INDEX 8
    pha
    stz.b $03
    .BranchIfTileOnRightBorderA +
        inc A
        cmp.b $02
        beq @eq
    +:
    lda $01,S
    .BranchIfTileOnLeftBorderA +
        dec A
        cmp.b $02
        beq @eq
    +:
    lda $01,S
    .BranchIfTileOnBottomBorderA +
        clc
        adc #$10
        cmp.b $02
        beq @eq
    +:
    lda $01,S
    .BranchIfTileOnTopBorderA +
        sec
        sbc #$10
        cmp.b $02
        beq @eq
    +:
    pla
    rts
@eq:
    inc.b $03
    pla
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
    jsl StageRand_Update4
    sep #$30 ; 8 bit AXY
    and #$03
    clc
    adc #6 ; X: [6-9]
    ; sta.b start_pos
    ; jsl StageRand_Update4
    ; sep #$30 ; 8 bit AXY
    ; and #$01
    ; clc
    ; adc #2 ; Y: [2-3]
    ; asl
    ; asl
    ; asl
    ; asl
    ; clc
    ; adc.b start_pos
    lda #(8 + 2*16)
    sta.b start_pos
    sta.w loadedRoomIndex
    stx.w roomslot_start
    tax
    lda #ROOMTYPE_START
    pha
    jsr _InitializeRoomX
    pla
    lda.b start_pos
    jsr _PushAdjacentEmptyTilesA
    rep #$30
    lda.l currentFloorPointer
    tax
    lda.l FLOOR_DEFINITION_BASE + floordefinition_t.size,X
    dec A
    tay
    sep #$30
@loop_add_tiles: ; do {
    phy
        ; Determine endpoint tiles
        lda.w numUsedMapSlots
        cmp #3
        bcc @add_adjacent_to_start
            jsr _CalculateNewEndpointTiles
            lda.b mapgenNumAvailableEndpointTiles
            bne +
                jsr _CalculateAvailableEndpointTiles
            +:
            jmp @skip_adjacent_to_start
    @add_adjacent_to_start:
            jsr _CalculateAvailableStartingRoomEndpointTiles
    @skip_adjacent_to_start:
        ; First, get random tile
        jsl StageRand_Update8
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
        lda #ROOMTYPE_NORMAL
        pha
        jsr _InitializeRoomX
        pla
        lda $05
        jsr _PushAdjacentEmptyTilesA
    ply
    dey
    cpy #0
    bne @loop_add_tiles ; } while (--Y != 0);
; setup special rooms
    ; Determine endpoint tiles
    jsr _MoveActiveRoomsIntoUsedTiles
    rep #$30
    ldx #mapgenUsedTiles
    lda.w mapgenNumUsedTiles
    and #$00FF
    jsl SortRoomsByEndpointCount
    sep #$30 ; 8b AXY
    ; for now, just set them up depending on index in available endpoint tiles
    ; BOSS
        ldx mapgenUsedTiles+0
        stx.w roomslot_boss
        stx.b $10
        ldy.w loword(mapTileSlotTable),X
        lda #ROOMTYPE_BOSS
        sta.w loword(mapTileTypeTable),X
        sta.w loword(roomSlotRoomType),Y
    ; ITEM
        ldx mapgenUsedTiles+1
        stx.w roomslot_star
        stx.b $11
        ldy.w loword(mapTileSlotTable),X
        lda #ROOMTYPE_ITEM
        sta.w loword(mapTileTypeTable),X
        sta.w loword(roomSlotRoomType),Y
    ; SHOP
        ldx mapgenUsedTiles+2
        stx.w roomslot_shop
        stx.b $12
        ldy.w loword(mapTileSlotTable),X
        lda #ROOMTYPE_SHOP
        sta.w loword(mapTileTypeTable),X
        sta.w loword(roomSlotRoomType),Y
    ; SUPER SECRET
        ldx mapgenUsedTiles+3
        stx.w roomslot_secret2
        stx.b $13
        ldy.w loword(mapTileSlotTable),X
        lda #ROOMTYPE_SECRET
        sta.w loword(mapTileTypeTable),X
        sta.w loword(roomSlotRoomType),Y
; add secret room
    jsr _FindValidSecretRoomLocations
    rep #$30
    ldx #mapgenUsedTiles
    lda.w mapgenNumUsedTiles
    and #$00FF
    jsl SortRoomsByEndpointCount
    sep #$30 ; 8b AXY
    ; insert
    lda.b mapgenNumUsedTiles
    dec A
    tax
    lda.b mapgenUsedTiles,X
    sta.b $14
    sta.w roomslot_secret1
    ; setup
    ldx.b $14
    lda #ROOMTYPE_SECRET
    pha
    jsr _InitializeRoomX
    sep #$30
    pla
; Setup rooms
    ldy.w numUsedMapSlots
@loop_setup_tiles:
    ldx.w loword(roomSlotMapPos-1),Y
    jsr _SetupRoomX
    sep #$30 ; 8b AXY
    dey
    bne @loop_setup_tiles
; setup special door rooms
    ; BOSS
        ldx.b $10
        ._UpdateDoors (DOOR_OPEN | DOOR_TYPE_BOSS | DOOR_METHOD_FINISH_ROOM)
    ; ITEM
        ldx.b $11
        lda.w currentFloorIndex
        beq @first_floor
            ._UpdateDoors (DOOR_CLOSED | DOOR_TYPE_TREASURE | DOOR_METHOD_KEY)
            jmp @not_first_floor
        @first_floor:
            ._UpdateDoors (DOOR_OPEN | DOOR_TYPE_TREASURE | DOOR_METHOD_FINISH_ROOM)
        @not_first_floor:
    ; SHOP
        ldx.b $12
        ._UpdateDoors (DOOR_CLOSED | DOOR_TYPE_SHOP | DOOR_METHOD_KEY)
    ; SECRET
        ldx.b $14
        ._UpdateDoors (DOOR_CLOSED | DOOR_TYPE_SECRET | DOOR_METHOD_BOMB)
    ; SUPER SECRET
        ldx.b $13
        ._UpdateDoors (DOOR_CLOSED | DOOR_TYPE_SECRET | DOOR_METHOD_BOMB)
; end
    lda #$FF
    sta.w numTilesToUpdate
    plb
    rtl

_PushRandomRoomFromPool:
    rep #$30 ; 16b AXY
; Get RNG value
    jsl StageRand_Update8
    sta.l DIVU_DIVIDEND
; Put pointer in Y
; For efficiency, Y starts at size*3
    lda [currentRoomPoolBase] ; byte 0 is size
    and #$FF
    sta.b TempValue
    asl
    clc
    adc.b TempValue
    tay
    sep #$20 ; 8b A
    ldx #0 ; Y counts number of valid rooms
    dec.b TempValue ; TempValue is index of current element (i.e. X/3 - 1)
    ; Find rooms with matching door mask, and put their indices into tempData
    sep #$20
    @loop:
        ; dey
        lda [currentRoomPoolBase],Y ; pool+2,Y (bank)
        sta.b TempAddr+2
        rep #$20 ; 16b A
        dey
        dey
        lda [currentRoomPoolBase],Y ; pool,Y (addr)
        dey
        sta.b TempAddr
        ; Ensure that RoomMask is a subset of DefMask
        ; Need to check that:
        ;     RoomMask & DefMask = RoomMask
        ;     (RoomMask)(DefMask) xor (RoomMask)(1) = 0
        ;     (RoomMask)(1 xor DefMask) = 0
        sep #$20 ; 8b A
        lda [TempAddr] ; get DefMask
        and.b TempDoorMask
        cmp.b TempDoorMask
        bne @skip
        lda.b TempValue
        sta.w loword(tempData_7E),X
        inx
    @skip:
        dec.b TempValue
        cpy #0
        bne @loop
; Apply RNG (rand() % X)
    txa
    sta.l DIVU_DIVISOR
    .REPT 8
        NOP ; (8 * 2 cycle)
    .ENDR
    rep #$20 ; 16b A
    lda.l DIVU_REMAINDER ; index into tempData
    tax
    stz.w loword(tempData_7E)+1,X ; Need to make next byte 0 so that it doesn't get added to 16b result
    lda.w loword(tempData_7E),X
    asl
    clc
    adc.w loword(tempData_7E),X
    tay ; Y now contains index into pool's roomList
    sep #$20 ; 8b A
    iny
    iny
    iny
    lda [currentRoomPoolBase],Y ; bank
    plx ; <2 pull return address
    pha ; >1
    rep #$20 ; 16b A
    dey
    dey
    lda [currentRoomPoolBase],Y ; addr
    pha ; >2
    phx ; >2 push return address
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
    stz.w roomslot_star
    stz.w roomslot_boss
    stz.w roomslot_start
    stz.w roomslot_shop
    stz.w roomslot_secret1
    stz.w roomslot_secret2
    .ClearWRam_ZP mapTileTypeTable, MAP_MAX_SIZE
    .ClearWRam_ZP mapTileFlagsTable, MAP_MAX_SIZE
    .ClearWRam_ZP mapTileSlotTable, MAP_MAX_SIZE
    .ClearWRam_ZP private_mapDoorHorizontalEmptyBuf, (MAP_MAX_SIZE*2 + MAP_MAX_WIDTH + MAP_MAX_HEIGHT)
    pld
    rts

.ENDS