.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "LevelCode" FREE

; Initialize a room slot from a room definition
; Push order:
;   tile position           [db] $08
;   room slot index         [db] $07
;   room definition address [dl] $04
InitializeRoomSlot:
    rep #$30 ; 16 bit AXY
    ; Put room definition address into ZP so that it can be used with
    ; direct indirect long addressing mode
    lda $04,s
    sta.b $0A
    sep #$20 ; 8 bit A, 16 bit XY
    lda $06,s
    sta.b $0C
    ; Turn slot index into slot address in X
    rep #$30
    lda $07,S
    and #$00FF
    sta.b $0D
    .MultiplyIndexByRoomSizeA P_DIR, $0D
    sta.b $0D ; store pointer for later use
    tax
    lda $04,s
    sta.l roomSlotTiles.1.roomDefinition,X
    sep #$20 ; 8 bit A, 16 bit XY
    ; write tile position
    lda $08,s
    ; write room size
    ldy #$01
    lda [$0A],Y
    ; Copy tile data, applying variants
    ldy #roomdefinition_t.tileData
@tile_copy_loop: ; do {
    lda [$0A],Y
    ; lda #5
    sta.l roomSlotTiles.1.tileTypeTable,X
    ; TODO: proper variant handling
    lda #0
    sta.l roomSlotTiles.1.tileVariantTable,X
    ; while (++Y != ROOM_TILE_COUNT);
    iny
    inx
    cpy #roomdefinition_t.tileData+ROOM_TILE_COUNT
    bne @tile_copy_loop
    ; set extra tiles
    lda #BLOCK_HOLE
    sta.l roomSlotTiles.1.tileTypeTable,X
    lda #BLOCK_IMPERVIOUS
    sta.l roomSlotTiles.1.tileTypeTable+1,X
    lda #0
    sta.l roomSlotTiles.1.tileVariantTable,X
    sta.l roomSlotTiles.1.tileVariantTable+1,X
    ; Clear entity store table
    ldx.b $0D
    lda #0
    .REPT ENTITY_STORE_COUNT INDEX i
        sta.l roomSlotTiles.1.entityStoreTable.{i+1}.type,X
    .ENDR
    ; set room rng
    jsl StageRand_Update32
    sta.l roomSlotTiles.1.rng,X
    tya
    sta.l roomSlotTiles.1.rng+2,X
    rtl

.MACRO .CopyGroundAddr ARGS addr
    lda #bankbyte(addr)
    sta.w currentRoomGroundData+2
    lda #hibyte(addr)
    sta.w currentRoomGroundData+1
    lda #lobyte(addr)
    sta.w currentRoomGroundData+0
.ENDM

; Initialize a room slot from a room definition
; Push order:
;   room slot index         [db] $04
LoadRoomSlotIntoLevel:
    ; first, clear existing level
    jsl entity_free_all
    jsl Palette.init_data
    ; determine current ground data
    sep #$30 ; 8 bit AXY
    ldx.b loadedRoomIndex
    lda.w mapTileTypeTable,X
    cmp #ROOMTYPE_START
    beq @ground_start
    jmp @ground_default
    @ground_start:
        lda.w currentFloorIndex
        bne @ground_default
        .CopyGroundAddr spritedata.basement_ground_starting_room
        jmp @ground_end
    @ground_default:
        rep #$30
        ldx.w currentFloorPointer
        lda.l FLOOR_DEFINITION_BASE + floordefinition_t.chapter,X
        and #$00FF
        asl
        tax
        lda.l ChapterDefinitions,X
        tax
        lda.l FLOOR_DEFINITION_BASE + chapterdefinition_t.ground,X
        sta.w currentRoomGroundData
        sep #$20
        lda.l FLOOR_DEFINITION_BASE + chapterdefinition_t.ground+2,X
        sta.w currentRoomGroundData+2
        rep #$20
        lda.l FLOOR_DEFINITION_BASE + chapterdefinition_t.groundPalette,X
        sta.w currentRoomGroundPalette
    @ground_end:
    ; then, clear floor
    jsl GroundOpClear
    ; Turn slot index into slot address in X
    sep #$30
    lda $04,S
    sta.b currentRoomSlot
    rep #$30
    and #$00FF
    sta.b $10
    .MultiplyIndexByRoomSizeA P_DIR, $10
    tax
    lda.l roomSlotTiles.1.roomDefinition,X
    sta.b currentRoomDefinition ; $0A: roomDefinition
    txa
    clc
    adc #loword(roomSlotTiles) + roominfo_t.tileTypeTable
    sta.b currentRoomTileTypeTableAddress
    clc
    adc #roominfo_t.tileVariantTable - roominfo_t.tileTypeTable
    sta.b currentRoomTileVariantTableAddress
    clc
    adc #roominfo_t.rng - roominfo_t.tileVariantTable
    sta.b currentRoomRngAddress_Low
    inc A
    inc A
    sta.b currentRoomRngAddress_High
; load tiles
    ; Copy default data to vqueueBinData
    .CopyROMToVQueueBin P_IMM, EmptyRoomTiles, 16*16*2
    ; Create operations. 12 are required to copy whole map.
    ; This will also Update the vqueueBinData offset
    rep #$30 ; 16 bit AXY
    lda.w vqueueBinOffset
    sta.b $10 ; $10 is copy of bin offset
    clc
    adc #16*2*2 + 2*2
    sta $00
    .VQueueOpToA
    tax
    lda.w vqueueNumOps
    clc
    adc #12
    sta.w vqueueNumOps
    ldy #0
@loop_op_copy:
    tya
    asl
    asl
    asl
    asl
    asl
    clc
    adc.w gameRoomBG2Offset
    sta.l vqueueOps.1.vramAddr,X
    lda #VQUEUE_MODE_VRAM
    sta.l vqueueOps.1.mode,X ; VRAM mode
    lda.w $10
    sta.l vqueueOps.1.aAddr,X
    clc
    adc #16*2
    sta.w $10
    lda.w #$7F
    sta.l vqueueOps.1.aAddr+2,X
    lda #16*2
    sta.l vqueueOps.1.numBytes,X
    txa ; ++X
    clc
    adc #_sizeof_vqueueop_t
    tax
    iny ; ++Y
    cpy #12
    bne @loop_op_copy
; Update tile data
    lda #$7F
    sta $02 ; $00 = dest bin
    sta $1A
    ; Begin iteration
    ; sep #$10 ; 8b XY
    lda #ROOM_TILE_HEIGHT
    sta $04 ; $04 = Y iterations
    ldy #0
@loop_tile_y: ; do {
    lda #ROOM_TILE_WIDTH
    sta $06 ; $06 = X iterations
    @loop_tile_x:
        lda [currentRoomTileTypeTableAddress],Y
        and #$00FF
        asl
        tax
        lda.w BlockVariantAddresses,X
        sta $08
        lda [currentRoomTileVariantTableAddress],Y
        and #$00FF
        asl
        tyx
        tay
        lda ($08),Y
        txy
        sta [$00]
        iny
        inc $00
        inc $00
        dec $06
        bne @loop_tile_x
    lda $00 ; bin += 8b
    clc
    adc #8
    sta $00
    dec $04 ; } while (--iy);
    bne @loop_tile_y
; update doors
    sep #$30 ; 8b AXY
    ldx.b currentRoomSlot
    lda.l roomSlotMapPos,X
    tay
    ; store map position variables
    rep #$20
    tya
    clc
    adc #loword(mapDoorHorizontal)
    sta.b mapDoorEast
    dec A
    sta.b mapDoorWest
    tya
    clc
    adc #loword(mapDoorVertical)
    sta.b mapDoorSouth
    sec
    sbc #MAP_MAX_WIDTH
    sta.b mapDoorNorth
    sep #$20
    php
    ; safety-check: if this is a secret room and all doors are closed, open all bomb doors
    ldx.b loadedRoomIndex
    lda.w mapTileTypeTable,X
    cmp #ROOMTYPE_SECRET
    bne @dont_open_secret
    lda [mapDoorEast]
    bmi @dont_open_secret
    lda [mapDoorWest]
    bmi @dont_open_secret
    lda [mapDoorSouth]
    bmi @dont_open_secret
    lda [mapDoorNorth]
    bmi @dont_open_secret
        lda [mapDoorEast]
        and #DOOR_MASK_OPEN_METHOD
        cmp #DOOR_METHOD_BOMB
        bne +
            lda [mapDoorEast]
            ora #DOOR_OPEN
            sta [mapDoorEast]
    +:
        lda [mapDoorWest]
        and #DOOR_MASK_OPEN_METHOD
        cmp #DOOR_METHOD_BOMB
        bne +
            lda [mapDoorWest]
            ora #DOOR_OPEN
            sta [mapDoorWest]
    +:
        lda [mapDoorSouth]
        and #DOOR_MASK_OPEN_METHOD
        cmp #DOOR_METHOD_BOMB
        bne +
            lda [mapDoorSouth]
            ora #DOOR_OPEN
            sta [mapDoorSouth]
    +:
        lda [mapDoorNorth]
        and #DOOR_MASK_OPEN_METHOD
        cmp #DOOR_METHOD_BOMB
        bne +
            lda [mapDoorNorth]
            ora #DOOR_OPEN
            sta [mapDoorNorth]
    +:
@dont_open_secret:
    ; safety-check: if this is a special room, open all locks
    ldx.b loadedRoomIndex
    lda.w mapTileTypeTable,X
    cmp #ROOMTYPE_NORMAL
    beq @dont_open_locks
    cmp #ROOMTYPE_START
    beq @dont_open_locks
        lda [mapDoorEast]
        and #DOOR_MASK_OPEN_METHOD
        cmp #DOOR_METHOD_KEY
        bne +
            lda [mapDoorEast]
            ora #DOOR_OPEN
            sta [mapDoorEast]
    +:
        lda [mapDoorWest]
        and #DOOR_MASK_OPEN_METHOD
        cmp #DOOR_METHOD_KEY
        bne +
            lda [mapDoorWest]
            ora #DOOR_OPEN
            sta [mapDoorWest]
    +:
        lda [mapDoorSouth]
        and #DOOR_MASK_OPEN_METHOD
        cmp #DOOR_METHOD_KEY
        bne +
            lda [mapDoorSouth]
            ora #DOOR_OPEN
            sta [mapDoorSouth]
    +:
        lda [mapDoorNorth]
        and #DOOR_MASK_OPEN_METHOD
        cmp #DOOR_METHOD_KEY
        bne +
            lda [mapDoorNorth]
            ora #DOOR_OPEN
            sta [mapDoorNorth]
    +:
@dont_open_locks:
    ; check doors
    jsl UpdateDoorTileNorth
    jsl UpdateDoorTileSouth
    jsl UpdateDoorTileEast
    jsl UpdateDoorTileWest
    plp
    rtl

; Push order:
;   room slot index         [db] $04
LoadAndInitRoomSlotIntoLevel:
    sep #$20
    lda $04,S
    pha
    jsl LoadRoomSlotIntoLevel
    sep #$20
    pla
InitLoadedRoomslot:
    ; initialize and update certain variables
    jsl Room_Init
    jsl Game.UpdateAllPathfinding
    rtl

TileLocationMap:
.REPT 8 INDEX iy
    .REPT 12 INDEX ix
        .dw (32 * iy) + ix + 2 + 2*32
    .ENDR
.ENDR

; Update the VRAM tile in currentConsideredTile
; Clobbers A, X, and Y
HandleTileChanged:
    .ACCU 16
    .INDEX 16
    phb
    phy
    .ChangeDataBank $80
    lda [currentRoomTileTypeTableAddress],Y ; get TYPE
    and #$00FF
    asl
    tax
    lda.w BlockVariantAddresses,X
    sta.b $00
    lda [currentRoomTileVariantTableAddress],Y ; get VARIANT
    and #$00FF
    asl
    tay
    lda.w vqueueNumMiniOps
    asl
    asl
    tax
    lda ($00),Y ; A now contains the actual tile value
    sta.l vqueueMiniOps.1.data,X
    phx
    lda $03,S
    asl
    tax
    lda.l TileLocationMap,X
    clc
    adc.w gameRoomBG2Offset
    plx
    sta.l vqueueMiniOps.1.vramAddr,X
    inc.w vqueueNumMiniOps
    ply
    plb
    rtl

UpdateDoorTileNorth:
    rep #$30
    ; Init vqueue
    lda.w vqueueNumMiniOps
    asl
    asl
    tax
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    ; set up tile indices
    lda.w gameRoomBG2Offset
    clc
    adc #7
    sta.l vqueueMiniOps.1.vramAddr,X
    inc A
    sta.l vqueueMiniOps.2.vramAddr,X
    clc
    adc #32 - 1
    sta.l vqueueMiniOps.3.vramAddr,X
    inc A
    sta.l vqueueMiniOps.4.vramAddr,X
    ; set up tile values
    lda [mapDoorNorth]
    and #$0F
    asl
    asl
    tay
    lda.w DoorTileTopperTable_TOP,Y
    sta.l vqueueMiniOps.1.data,X
    lda.w DoorTileTopperTable_TOP+2,Y
    sta.l vqueueMiniOps.2.data,X
    lda [mapDoorNorth]
    and #$F0
    lsr
    lsr
    tay
    lda.w DoorTileBaseTable_TOP,Y
    sta.l vqueueMiniOps.3.data,X
    lda.w DoorTileBaseTable_TOP+2,Y
    sta.l vqueueMiniOps.4.data,X
    ; Return
    rtl

UpdateDoorTileSouth:
    rep #$30
    ; Init vqueue
    lda.w vqueueNumMiniOps
    asl
    asl
    tax
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    ; set up tile indices
    lda.w gameRoomBG2Offset
    clc
    adc #10*32+7
    sta.l vqueueMiniOps.1.vramAddr,X
    inc A
    sta.l vqueueMiniOps.2.vramAddr,X
    clc
    adc #32 - 1
    sta.l vqueueMiniOps.3.vramAddr,X
    inc A
    sta.l vqueueMiniOps.4.vramAddr,X
    ; set up tile values
    lda [mapDoorSouth]
    and #$0F
    asl
    asl
    tay
    lda.w DoorTileTopperTable_TOP,Y
    ora #$8000
    sta.l vqueueMiniOps.3.data,X
    lda.w DoorTileTopperTable_TOP+2,Y
    ora #$8000
    sta.l vqueueMiniOps.4.data,X
    lda [mapDoorSouth]
    and #$F0
    lsr
    lsr
    tay
    lda.w DoorTileBaseTable_TOP,Y
    ora #$8000
    sta.l vqueueMiniOps.1.data,X
    lda.w DoorTileBaseTable_TOP+2,Y
    ora #$8000
    sta.l vqueueMiniOps.2.data,X
    ; Return
    rtl

UpdateDoorTileWest:
    rep #$30
    ; Init vqueue
    lda.w vqueueNumMiniOps
    asl
    asl
    tax
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    ; set up tile indices
    lda.w gameRoomBG2Offset
    clc
    adc #5*32
    sta.l vqueueMiniOps.1.vramAddr,X
    inc A
    sta.l vqueueMiniOps.2.vramAddr,X
    clc
    adc #32 - 1
    sta.l vqueueMiniOps.3.vramAddr,X
    inc A
    sta.l vqueueMiniOps.4.vramAddr,X
    ; set up tile values
    lda [mapDoorWest]
    and #$0F
    asl
    asl
    tay
    lda.w DoorTileTopperTable_LEFT,Y
    sta.l vqueueMiniOps.1.data,X
    lda.w DoorTileTopperTable_LEFT+2,Y
    sta.l vqueueMiniOps.3.data,X
    lda [mapDoorWest]
    and #$F0
    lsr
    lsr
    tay
    lda.w DoorTileBaseTable_LEFT,Y
    sta.l vqueueMiniOps.2.data,X
    lda.w DoorTileBaseTable_LEFT+2,Y
    sta.l vqueueMiniOps.4.data,X
    ; Return
    rtl

UpdateDoorTileEast:
    rep #$30
    ; Init vqueue
    lda.w vqueueNumMiniOps
    asl
    asl
    tax
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    ; set up tile indices
    lda.w gameRoomBG2Offset
    clc
    adc #5*32+14
    sta.l vqueueMiniOps.1.vramAddr,X
    inc A
    sta.l vqueueMiniOps.2.vramAddr,X
    clc
    adc #32 - 1
    sta.l vqueueMiniOps.3.vramAddr,X
    inc A
    sta.l vqueueMiniOps.4.vramAddr,X
    ; set up tile values
    lda [mapDoorEast]
    and #$0F
    asl
    asl
    tay
    lda.w DoorTileTopperTable_LEFT,Y
    eor #$4000
    sta.l vqueueMiniOps.2.data,X
    lda.w DoorTileTopperTable_LEFT+2,Y
    eor #$4000
    sta.l vqueueMiniOps.4.data,X
    lda [mapDoorEast]
    and #$F0
    lsr
    lsr
    tay
    lda.w DoorTileBaseTable_LEFT,Y
    eor #$4000
    sta.l vqueueMiniOps.1.data,X
    lda.w DoorTileBaseTable_LEFT+2,Y
    eor #$4000
    sta.l vqueueMiniOps.3.data,X
    ; Return
    rtl

updateAllDoorsInRoom:
    jsl UpdateDoorTileNorth
    jsl UpdateDoorTileSouth
    jsl UpdateDoorTileEast
    jsl UpdateDoorTileWest
    rtl

.ENDS

.SECTION "LevelData" BANK ROMBANK_BASE SLOT "ROM" ORGA $8000 SEMIFREE

BlockVariantAddresses:
.REPT 256 INDEX i
    .IF i == BLOCK_REGULAR
        .dw BlockEmptyVariants
    .ELIF i == BLOCK_ROCK
        .dw BlockRockVariants
    .ELIF i == BLOCK_ROCK_TINTED
        .dw BlockRockTintedVariants
    .ELIF i == BLOCK_POOP
        .dw BlockPoopVariants
    .ELIF i == BLOCK_LOGS
        .dw BlockLogVariants
    .ELIF i == BLOCK_SPIKE
        .dw BlockSpikeVariants
    .ELIF i == BLOCK_METAL
        .dw BlockMetalVariants
    .ELSE
        .dw BlockEmptyVariants
    .ENDIF
.ENDR

BlockEmptyVariants:
    .dw deft($20, 1)
    .dw deft($A4, 3) ; 1: rubble
BlockRockVariants:
    .dw deft($A0, 3)
BlockRockTintedVariants:
    .dw deft($A2, 3)
BlockPoopVariants:
    .dw deft($80, 3) ; 0: full
    .dw deft($82, 3) ; 1: slightly damaged
    .dw deft($84, 3) ; 2: mostly damaged
BlockMetalVariants:
    .dw deft($62, 3)
BlockSpikeVariants:
    .dw deft($40, 3) ; 0: out
    .dw deft($42, 3) ; 1: retractable
    .dw deft($44, 3) ; 2: retracted
BlockLogVariants:
    .dw deft($60, 3)

EmptyRoomTiles:
; row 0
.dw deft($02, 2)
.REPT 14
    .dw deft($04, 2)
.ENDR
.dw deft($02, 2) | T_FLIPH
; row 1
.dw deft($22, 2)
.dw deft($24, 2)
.dw deft($102, 2)
.REPT 10
    .dw deft($26, 2)
.ENDR
.dw deft($106, 2) | T_FLIPH
.dw deft($24, 2) | T_FLIPH
.dw deft($22, 2) | T_FLIPH
; rows 2-9
.REPT 8 INDEX i
    .dw deft($22, 2)
    .IF i == 0
        .dw deft($100, 2)
    .ELIF i == 7
        .dw deft($104, 2) | T_FLIPV
    .ELSE
        .dw deft($06, 2)
    .ENDIF
    .REPT 12
        .dw 0
    .ENDR
    .IF i == 0
        .dw deft($100, 2) | T_FLIPH
    .ELIF i == 7
        .dw deft($104, 2) | T_FLIPH | T_FLIPV
    .ELSE
        .dw deft($06, 2) | T_FLIPH
    .ENDIF
    .dw deft($22, 2) | T_FLIPH
.ENDR
; row 10
.dw deft($22, 2)
.dw deft($24, 2) | T_FLIPV
.dw deft($102, 2) | T_FLIPV
.REPT 10
    .dw deft($26, 2) | T_FLIPV
.ENDR
.dw deft($106, 2) | T_FLIPV | T_FLIPH
.dw deft($24, 2) | T_FLIPH | T_FLIPV
.dw deft($22, 2) | T_FLIPH
; row 11
.dw deft($02, 2) | T_FLIPV
.REPT 14
    .dw deft($04, 2) | T_FLIPV
.ENDR
.dw deft($02, 2) | T_FLIPH | T_FLIPV
; row 12-15
.REPT 16*4
    .dw deft($00, 1)
.ENDR

; INDEXED BY method
; 4B per item
; (doortype & F0) >> 4
DoorTileBaseTable_TOP:
    .dw deft($26, 2), deft($26, 2) ; 0 NEVER - wall
    .dw deft($88, 2), deft($8A, 2) ; 1 KEY
    .dw deft($26, 2), deft($26, 2) ; 2 BOMB - wall (secret room)
    .dw deft($26, 2), deft($26, 2) ; 3 COIN - wall (unimplemented)
    .dw deft($68, 2), deft($6A, 2) ; 4 ROOM FINISH - closed door
    .dw deft($26, 2), deft($26, 2) ; 5 UNUSED - wall
    .dw deft($26, 2), deft($26, 2) ; 6 UNUSED - wall
    .dw deft($26, 2), deft($26, 2) ; 7 UNUSED - wall
    .dw deft($48, 2), deft($4A, 2) ; 8 NEVER (OPEN) - open door
    .dw deft($48, 2), deft($4A, 2) ; 9 KEY (OPEN) - open door
    .dw deft($A8, 2), deft($AA, 2) ; A BOMB (OPEN) - exploded wall
    .dw deft($48, 2), deft($4A, 2) ; B COIN (OPEN) - open door
    .dw deft($48, 2), deft($4A, 2) ; C ROOM FINISH (OPEN) - open door
    .dw deft($48, 2), deft($4A, 2) ; D UNUSED (OPEN) - open door
    .dw deft($48, 2), deft($4A, 2) ; E UNUSED (OPEN) - open door
    .dw deft($48, 2), deft($4A, 2) ; F UNUSED (OPEN) - open door

DoorTileBaseTable_LEFT:
    .dw deft($06, 2), deft($06, 2) ; 0 NEVER - wall
    .dw deft($CC, 2), deft($EC, 2) ; 1 KEY
    .dw deft($06, 2), deft($06, 2) ; 2 BOMB - wall (secret room)
    .dw deft($06, 2), deft($06, 2) ; 3 COIN - wall (unimplemented)
    .dw deft($CA, 2), deft($EA, 2) ; 4 ROOM FINISH - closed door
    .dw deft($06, 2), deft($06, 2) ; 5 UNUSED - wall
    .dw deft($06, 2), deft($06, 2) ; 6 UNUSED - wall
    .dw deft($06, 2), deft($06, 2) ; 7 UNUSED - wall
    .dw deft($C8, 2), deft($E8, 2) ; 8 NEVER (OPEN) - open door
    .dw deft($C8, 2), deft($E8, 2) ; 9 KEY (OPEN) - open door
    .dw deft($CE, 2), deft($EE, 2) ; A BOMB (OPEN) - exploded wall
    .dw deft($C8, 2), deft($E8, 2) ; B COIN (OPEN) - open door
    .dw deft($C8, 2), deft($E8, 2) ; C ROOM FINISH (OPEN) - open door
    .dw deft($C8, 2), deft($E8, 2) ; D UNUSED (OPEN) - open door
    .dw deft($C8, 2), deft($E8, 2) ; E UNUSED (OPEN) - open door
    .dw deft($C8, 2), deft($E8, 2) ; F UNUSED (OPEN) - open door

; INDEX BY type
; 4B per item
; doortype & 0xF
DoorTileTopperTable_TOP:
    .dw deft($04, 2), deft($04, 2) ; 0 wall
    .dw deft($4C, 2), deft($4E, 2) ; 1 normal
    .dw deft($6C, 2), deft($6E, 2) ; 2 item
    .dw deft($8C, 2), deft($8E, 2) ; 3 shop
    .dw deft($AC, 3), deft($AE, 3) ; 4 boss
    .REPT 16-5
        .dw deft($04, 2), deft($04, 2) ; wall
    .ENDR

DoorTileTopperTable_LEFT:
    .dw deft($22, 2), deft($22, 2) ; 0 wall
    .dw deft($C0, 2), deft($E0, 2) ; 1 normal
    .dw deft($C2, 2), deft($E2, 2) ; 2 item
    .dw deft($C4, 2), deft($E4, 2) ; 3 shop
    .dw deft($C6, 3), deft($E6, 3) ; 4 boss
    .REPT 16-5
        .dw deft($22, 2), deft($22, 2) ; wall
    .ENDR

; TRANSITION ZONE ;

_transition_ground_right:
    .ACCU 16
    .INDEX 16
    ; get column that was just loaded in
    ; col = (scrollx / 8) % 32
    lda.w gameRoomScrollX
    .DivideStatic 8
    and #$001F
    jmp _transition_ground_horizontal

_transition_ground_left:
    .ACCU 16
    .INDEX 16
    ; get column that was just loaded in
    ; col = (scrollx / 8 - 1) % 32
    lda.w gameRoomScrollX
    .DivideStatic 8
    dec A
    and #$001F
    jmp _transition_ground_horizontal

_transition_ground_down:
    .ACCU 16
    .INDEX 16
    ; get row that was just loaded in
    ; col = ((scrolly + 32) / 8 - 4) % 32
    lda.w gameRoomScrollY
    .DivideStatic 8
    and #$001F
    jmp _transition_ground_vertical

_transition_ground_up:
    .ACCU 16
    .INDEX 16
    ; get row that was just loaded in
    ; col = ((scrolly + 32) / 8 - 1) % 32
    lda.w gameRoomScrollY
    clc
    adc #24
    .DivideStatic 8
    and #$001F
    jmp _transition_ground_vertical

.DEFINE COLUMN (tempDP+0)
.DEFINE ADDR (tempDP+2)
.DEFINE TILE (tempDP+4)
_transition_ground_horizontal:
    .ACCU 16
    .INDEX 16
    sec
    sbc #4
    cmp #24
    bcc +
        rts
    +:
    sta.b COLUMN
; we need 16 vqueue ops: one for each tile, 16B each
    .VQueueOpToA
    tax
    lda.w vqueueNumOps
    clc
    adc #$10
    sta.w vqueueNumOps
    ; size[*] = $10
    lda #$10
    .REPT 16 INDEX i
        sta.l vqueueOps.{i+1}.numBytes,X
    .ENDR
    ; vramAddr[i] = BG3_CHARACTER_BASE_ADDR + i * $00C0 + COLUMN * $08
    lda.b COLUMN
    .MultiplyStatic $08
    clc
    adc #BG3_CHARACTER_BASE_ADDR
    .REPT 16 INDEX i
        sta.l vqueueOps.{i+1}.vramAddr,X
        adc #$00C0 ; assume carry to be clear
    .ENDR
    ; aAddr[i] = currentRoomGroundData + i * $0180 + COLUMN * $10
    lda.b COLUMN
    .MultiplyStatic $10
    clc
    adc.w currentRoomGroundData
    .REPT 16 INDEX i
        sta.l vqueueOps.{i+1}.aAddr,X
        adc #$0180 ; assume carry to be clear
    .ENDR
    sep #$20
    lda.w currentRoomGroundData+2
    .REPT 16 INDEX i
        sta.l vqueueOps.{i+1}.aAddr+2,X
    .ENDR
    ; mode[*] = VQUEUE_MODE_VRAM
    lda #VQUEUE_MODE_VRAM
    .REPT 16 INDEX i
        sta.l vqueueOps.{i+1}.mode,X
    .ENDR
; create mini ops for tile data
    rep #$20
    ; X = vqueueNumMiniOps * 4
    lda.w vqueueNumMiniOps
    asl
    asl
    tax
    ; vqueueNumMiniOps += $10
    lda.w vqueueNumMiniOps
    clc
    adc #$10
    sta.w vqueueNumMiniOps
    ; TILE = COLUMN | PALETTE
    lda.b COLUMN
    ora.w currentRoomGroundPalette
    sta.b TILE
    ; ADDR = BG3_TILE_BASE_ADDR + 4 + COLUMN + 8*$20
    lda.b COLUMN
    clc
    adc #BG3_TILE_BASE_ADDR + 4 + 8*$20
    sta.b ADDR
    ; Y = $10
    ldy #$10
    ; set mini ops for tiles in loop
    @loop:
        lda.b ADDR
        sta.l vqueueMiniOps.1.vramAddr,X
        clc
        adc #$0020
        sta.b ADDR
        lda.b TILE
        sta.l vqueueMiniOps.1.data,X
        clc
        adc #$0018
        sta.b TILE
        inx
        inx
        inx
        inx
        dey
        bne @loop
; end
    rts
.UNDEFINE COLUMN

.DEFINE ROW (tempDP+0)
; we are *transitioning* vertically, so we are writing in a *row* of ground tiles
_transition_ground_vertical:
    .ACCU 16
    .INDEX 16
    sec
    sbc #8
    cmp #16
    bcc +
        rts
    +:
    sta.b ROW
; create vqueue op for character data
    .VQueueOpToA
    tax
    inc.w vqueueNumOps
    ; size = $0180
    lda #$0180
    sta.l vqueueOps.1.numBytes,X
    ; vramAddr = BG3_CHARACTER_BASE_ADDR + ROW * $00C0 (= 3 * $40)
    lda.b ROW
    asl
    clc
    adc.b ROW
    .MultiplyStatic $40
    pha
    clc
    adc #BG3_CHARACTER_BASE_ADDR
    sta.l vqueueOps.1.vramAddr,X
    ; aAddr = currentRoomGroundData + ROW * $0180 (= 3 * $80)
    pla
    asl
    clc
    adc.w currentRoomGroundData
    sta.l vqueueOps.1.aAddr,X
    sep #$20
    lda.w currentRoomGroundData+2
    sta.l vqueueOps.1.aAddr+2,X
    ; mode = VQUEUE_MODE_VRAM
    lda #VQUEUE_MODE_VRAM
    sta.l vqueueOps.1.mode,X
; create mini ops for tile data
    rep #$20
    ; X = vqueueNumMiniOps * 4
    lda.w vqueueNumMiniOps
    asl
    asl
    tax
    ; vqueueNumMiniOps += $18
    lda.w vqueueNumMiniOps
    clc
    adc #$18
    sta.w vqueueNumMiniOps
    ; TILE = ROW * $18 (= 3 * $08) | PALETTE
    lda.b ROW
    asl
    clc
    adc.b ROW
    .MultiplyStatic $08
    ora.w currentRoomGroundPalette
    sta.b TILE
    ; ADDR = BG3_TILE_BASE_ADDR + 4 + ROW*$20 + 8*$20
    lda.b ROW
    .MultiplyStatic $20
    clc
    adc #BG3_TILE_BASE_ADDR + 4 + 8*$20
    sta.b ADDR
    ; Y = $18
    ldy #$18
    ; set mini ops for tiles in loop
    @loop:
        lda.b ADDR
        sta.l vqueueMiniOps.1.vramAddr,X
        inc.b ADDR
        lda.b TILE
        sta.l vqueueMiniOps.1.data,X
        inc.b TILE
        inx
        inx
        inx
        inx
        dey
        bne @loop
; end
    rts
.UNDEFINE ROW
.UNDEFINE ADDR
.UNDEFINE TILE

_transition_ground_func_table:
    .dw _transition_ground_right
    .dw _transition_ground_down
    .dw _transition_ground_left
    .dw _transition_ground_up

.DEFINE HORIZONTAL_OFFSET $20
.DEFINE VERTICAL_OFFSET $22
.DEFINE FRAMES $24
.DEFINE TEMP $26
.DEFINE DIRECTION $28
_transition_loop:
    .ACCU 16
    .INDEX 16
    lda #32
    sta.b FRAMES
@loop:
; wait for NMI
    wai
; upload current data
    .DisableRENDER
    jsl Render.HDMAEffect.Clear
    jsl ProcessVQueue
    jsl UploadSpriteTable
    ; update scroll
    rep #$20
    lda.w gameRoomScrollX
    clc
    adc.b HORIZONTAL_OFFSET
    and #$01FF
    sta.w gameRoomScrollX
    lda.w gameRoomScrollY
    clc
    adc.b VERTICAL_OFFSET
    and #$01FF
    sta.w gameRoomScrollY
    ; update BG2 scroll
    sep #$20
    lda.w gameRoomScrollX
    sta.w BG2HOFS
    lda.w gameRoomScrollX+1
    sta.w BG2HOFS
    lda.w gameRoomScrollY
    sta.w BG2VOFS
    lda.w gameRoomScrollY+1
    sta.w BG2VOFS
    ; update BG1 scroll
    lda.w gameRoomScrollX
    sta.w BG1HOFS
    lda.w gameRoomScrollX+1
    sta.w BG1HOFS
    lda.w gameRoomScrollY
    sta.w BG1VOFS
    lda.w gameRoomScrollY+1
    sta.w BG1VOFS
    ; update BG3 scroll
    lda.w gameRoomScrollX
    sta.w BG3HOFS
    lda.w gameRoomScrollX+1
    sta.w BG3HOFS
    rep #$20
    lda.w gameRoomScrollY
    clc
    adc #32
    sep #$20
    sta.w BG3VOFS
    xba
    sta.w BG3VOFS
    .EnableRENDER
; update ground
    rep #$30
    lda.b DIRECTION
    and #$00FF
    asl
    tax
    jsr (_transition_ground_func_table,X)
; update sprite locations
; maybe end loop
    rep #$20
    dec.b FRAMES
    bnel @loop
    rts

_transition_horizontal_table:
    .dw 8, 0, -8, 0
_transition_vertical_table:
    .dw 0, 8, 0, -8

_transition_bg2eor_table:
    .dw BG2_TILE_ADDR_OFFS_X, BG2_TILE_ADDR_OFFS_Y, BG2_TILE_ADDR_OFFS_X, BG2_TILE_ADDR_OFFS_Y

; Perform a room transition.
; BeginRoomTransition([s8]uint room_id, [s8]uint direction)
; room_id   $05,S
; direction $04,S
TransitionRoomIndex:
    wai
; disable BG1 (temporarily), and copy character data of current room to BG1
    .DisableRENDER
        jsl Render.HDMAEffect.Clear
        jsl ProcessVQueue
        ; copy character data page 1 (8K)
        rep #$30
        ldx.w currentRoomDefinition
        lda.l ROOM_DEFINITION_BASE + roomdefinition_t.chapterOverride,X
        and #$00FF
        bne +
            ldx.w currentFloorPointer
            lda.l FLOOR_DEFINITION_BASE + floordefinition_t.chapter,X
            and #$00FF
        +:
        asl
        tax
        lda.l ChapterDefinitions,X
        tax
        stx.b TEMP
        lda.l FLOOR_DEFINITION_BASE + chapterdefinition_t.tiledata,X
        sta.w DMA0_SRCL
        lda #$2000
        sta.w DMA0_SIZE
        lda #BG1_CHARACTER_BASE_ADDR
        sta.w VMADDR
        sep #$20
        lda.l FLOOR_DEFINITION_BASE + chapterdefinition_t.tiledata + 2,X
        sta.w DMA0_SRCH
        lda #$18
        sta.w DMA0_DEST
        lda #%00000001
        sta.w DMA0_CTL
        lda #$80
        sta.w VMAIN
        lda #1
        sta.w MDMAEN
        ; disable BG1
        lda #%00010110
        sta SCRNDESTM
        ; disable second screen for BG1
        lda #(BG1_TILE_BASE_ADDR >> 8) | %00
        sta.w BG1SC
    .EnableRENDER
    wai
    .DisableRENDER
        ; copy character data page 2 (8K)
        rep #$30
        ldx.b TEMP
        lda.l FLOOR_DEFINITION_BASE + chapterdefinition_t.tiledata,X
        clc
        adc #$2000
        sta.w DMA0_SRCL
        lda #$2000
        sta.w DMA0_SIZE
        lda #BG1_CHARACTER_BASE_ADDR + $1000
        sta.w VMADDR
        sep #$20
        lda.l FLOOR_DEFINITION_BASE + chapterdefinition_t.tiledata + 2,X
        sta.w DMA0_SRCH
        lda #$18
        sta.w DMA0_DEST
        lda #%00000001
        sta.w DMA0_CTL
        lda #$80
        sta.w VMAIN
        lda #1
        sta.w MDMAEN
    .EnableRENDER
    wai
; copy BG2 tile data into RAM
    .DisableRENDER
        ; copy all four palettes (128B)
        .REPT 4 INDEX i
            rep #$30
            ldx.b TEMP
            pea 32
            lda.l FLOOR_DEFINITION_BASE + chapterdefinition_t.palettes + (i*3) + 2,X
            and #$00FF
            ora #$1000 * i + $4000
            pha
            lda.l FLOOR_DEFINITION_BASE + chapterdefinition_t.palettes + (i*3),X
            pha
            jsl CopyPalette
            rep #$30
            pla
            pla
            pla
        .ENDR
        ; VRAM BG2 TILES -> RAM TILES (2KB)
        rep #$20
        lda #loword(tempTileData)
        sta.w DMA0_SRCL
        lda #$0800
        sta.w DMA0_SIZE
        lda #BG2_TILE_BASE_ADDR
        sta.w VMADDR
        lda.w VMDATAREAD
        sep #$20
        lda #bankbyte(tempTileData)
        sta.w DMA0_SRCH
        lda #$39
        sta.w DMA0_DEST
        lda #%10000001
        sta.w DMA0_CTL
        lda #$80
        sta.w VMAIN
        lda #1
        sta.w MDMAEN
    .EnableRENDER
; during CPU, swap palettes for BG2
    rep #$30
    ldx #$0000
    ldy #$0400
    @loop_set_palette:
        lda.l tempTileData,X
        cmp #deft($08, 2)
        bne +
            lda #deft($20, 2)
        +:
        ora #$1000
        sta.l tempTileData,X

        inx
        inx
        dey
        bne @loop_set_palette
    wai
; copy RAM tile data to BG1, clear BG2, and re-enable BG1 with new flags
    .DisableRENDER
        ; RAM TILES -> VRAM BG1 TILES (2KB)
        rep #$20
        lda #BG1_TILE_BASE_ADDR
        sta.w VMADDR
        lda #$0800
        sta.w DMA0_SIZE
        lda #loword(tempTileData)
        sta.w DMA0_SRCL
        sep #$20
        lda #bankbyte(tempTileData)
        sta.w DMA0_SRCH
        lda #$80
        sta.w VMAIN
        lda #$18
        sta.w DMA0_DEST
        lda #%00000001
        sta.w DMA0_CTL
        lda #1
        sta.w MDMAEN
        ; BACKGROUND -> VRAM BG2 tiles (2KB)
        rep #$20
        lda #BG2_TILE_BASE_ADDR
        sta.w VMADDR
        lda #$0800
        sta.w DMA0_SIZE
        lda #loword(EmptyBackgroundTile)
        sta.w DMA0_SRCL
        sep #$20
        lda #bankbyte(EmptyBackgroundTile)
        sta.w DMA0_SRCH
        lda #$80
        sta.w VMAIN
        lda #%00001001
        sta.w DMA0_CTL
        lda #1
        sta.w MDMAEN
        ; TRANSPARENT -> VRAM BG2 tiles current page (512B)
        rep #$20
        lda.w gameRoomBG2Offset
        sta.b TEMP
        lda #loword(TransparentBackgroundTile)
        sta.w DMA0_SRCL
        sep #$20
        lda #bankbyte(TransparentBackgroundTile)
        sta.w DMA0_SRCH
        lda #$80
        sta.w VMAIN
        lda #%00001001
        sta.w DMA0_CTL
        .REPT 12 INDEX i
            rep #$20
            lda.b TEMP
            sta.w VMADDR
            lda #32
            sta.w DMA0_SIZE
            sep #$20
            lda #1
            sta.w MDMAEN
            rep #$20
            lda.b TEMP
            clc
            adc #32
            cmp #BG2_TILE_BASE_ADDR + $0400
            bcc +
                sec
                sbc #$0400
            +:
            sta.b TEMP
        .ENDR
    ; update render flags
        sep #$20
        ; enable BG1
        lda #%00010111
        sta SCRNDESTM
        ; mode 1, with BG1 and BG2 both having 16px tiles
        lda #%00110001
        sta.w BGMODE
        ; update BG1 scroll
        lda.w gameRoomScrollX
        sta.w BG1HOFS
        lda.w gameRoomScrollX+1
        sta.w BG1HOFS
        lda.w gameRoomScrollY
        sta.w BG1VOFS
        lda.w gameRoomScrollY+1
        sta.w BG1VOFS
    .EnableRENDER
    wai
; set up for new room to load
    rep #$30
    lda $04,S
    and #$00FF
    sta.b DIRECTION
    asl
    tax
    lda.l _transition_bg2eor_table,X
    eor.l gameRoomBG2Offset
    sta.l gameRoomBG2Offset
; load new room
    sep #$20
    lda #ENTITY_CONTEXT_TRANSITION
    sta.b entityExecutionContext
    jsl Room_Unload
    sep #$30
    lda $05,S
    sta.b loadedRoomIndex
    tax
    lda.l mapTileSlotTable,X
    pha
    jsl LoadRoomSlotIntoLevel
    sep #$30
    lda #ENTITY_CONTEXT_STANDARD
    sta.b entityExecutionContext
    pla
    rep #$30
    ; TODO: probably in LoadRoomSlotIntoLevel, load new tileset (if available)
; init room, and run one single tick
    jsl InitLoadedRoomslot
    rep #$30
    jsl ClearSpriteTable
    jsl entity_clear_hitboxes
    sep #$20
    lda #ENTITY_CONTEXT_TRANSITION
    sta.b entityExecutionContext
    jsl entity_tick_all
    sep #$20
    lda #ENTITY_CONTEXT_STANDARD
    sta.b entityExecutionContext
; scroll into new room
    rep #$30
    lda $04,S
    and #$00FF
    asl
    tax
    lda.l _transition_horizontal_table,X
    sta.b HORIZONTAL_OFFSET
    lda.l _transition_vertical_table,X
    sta.b VERTICAL_OFFSET
    jsr _transition_loop
; disable UI and re-upload UI character data
    wai
    .DisableRENDER
        ; copy UI to VRAM (8KB)
        pea BG1_CHARACTER_BASE_ADDR
        pea 16*16
        sep #$20 ; 8 bit A
        lda #bankbyte(spritedata.UI)
        pha
        pea spritedata.UI
        jsl CopySprite
        sep #$20 ; 8 bit A
        pla
        rep #$20 ; 16 bit A
        pla
        pla
        pla
        sep #$20
        ; set UI to use 8px tiles
        lda #%00100001
        sta.w BGMODE
        ; re-enable second page of BG1 tile data
        lda #(BG1_TILE_BASE_ADDR >> 8) | %10
        sta.w BG1SC
        ; hide UI
        lda #%00010110
        sta SCRNDESTM
        ; reset scroll
        lda #0
        sta.w BG1HOFS
        sta.w BG1HOFS
        sta.w BG1VOFS
        sta.w BG1VOFS
    .EnableRENDER
; update UI. Make sure that re-enabling UI is done via register queue
    wai
    .DisableRENDER
        jsl InitializeUI ; upload UI (2KB)
        ; upload palettes
        pea 32
        PEA $5000 + bankbyte(palettes.ui_light.w)
        PEA palettes.ui_light.w
        jsl CopyPalette
        rep #$20 ; 16 bit A
        PLA
        PLA
        PEA $6000 + bankbyte(palettes.ui_gold.w)
        PEA palettes.ui_gold.w
        jsl CopyPalette
        rep #$20 ; 16 bit A
        PLA
        PLA
        PEA $4000 + bankbyte(palettes.item_inactive.w)
        PEA palettes.item_inactive.w
        jsl CopyPalette
        rep #$20 ; 16 bit A
        PLA
        PLA
        PLA
    .EnableRENDER
; call some update functions for various UI components
    jsl UI.update_money_display
    jsl UI.update_bomb_display
    jsl UI.update_key_display
    jsl UI.update_all_hearts
    jsl Item.update_active_palette
    sep #$20
    lda #$FF
    sta.w numTilesToUpdate
    jsl UI.update_charge_display
    jsl Consumable.update_display_no_overlay
    rep #$30
    lda.w vqueueNumRegOps
    inc.w vqueueNumRegOps
    asl
    tax
    lda #%00010111 | ($0100 * %11100100)
    sta.l vqueueRegOps_Value,X
    lda #SCRNDESTM
    sta.l vqueueRegOps_Addr,X
; end
    rtl
.ENDS