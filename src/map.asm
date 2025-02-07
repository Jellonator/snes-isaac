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
    lda #lobyte(_sizeof_roominfo_t)
    sta.l MULTS_A
    lda #hibyte(_sizeof_roominfo_t)
    sta.l MULTS_A
    lda $07,s
    sta.l MULTS_B
    rep #$30 ; 16 bit AXY
    lda.l MULTS_RESULT_LOW
    sta.b $0D ; store pointer for later use
    tax
    lda $04,s
    sta.l roomSlotTiles.1.roomDefinition,X
    sep #$20 ; 8 bit A, 16 bit XY
    ; write tile position
    lda $08,s
    ; TODO: set door flags
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
    sep #$30 ; 8 bit AXY
    ; Turn slot index into slot address in X
    lda #lobyte(_sizeof_roominfo_t)
    sta MULTS_A
    lda #hibyte(_sizeof_roominfo_t)
    sta MULTS_A
    lda $04,s
    sta.b currentRoomSlot
    sta MULTS_B
    rep #$30 ; 16 bit AXY
    lda MULTS_RESULT_LOW
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
; load tiles
    ; Copy default data to vqueueBinData
    .CopyROMToVQueueBin EmptyRoomTiles, 16*16*2
    ; Create operations. 12 are required to copy whole map.
    ; This will also Update the vqueueBinData offset
    rep #$30 ; 16 bit AXY
    lda.w vqueueBinOffset
    sta $10 ; $10 is copy of bin offset
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
    lda.w vqueueBinOffset
    sta.l vqueueOps.1.aAddr,X
    clc
    adc #16*2
    sta.w vqueueBinOffset
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
    ; check doors
    php
    jsr _UpdateDoorTileNorth
    jsr _UpdateDoorTileSouth
    jsr _UpdateDoorTileEast
    jsr _UpdateDoorTileWest
    plp
    jsl Room_Init
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
    .ChangeDataBank $00
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

_UpdateDoorTileNorth:
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
    rts

_UpdateDoorTileSouth:
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
    rts

_UpdateDoorTileWest:
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
    rts

_UpdateDoorTileEast:
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
    rts

updateAllDoorsInRoom:
    jsr _UpdateDoorTileNorth
    jsr _UpdateDoorTileSouth
    jsr _UpdateDoorTileEast
    jsr _UpdateDoorTileWest
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
        .dw BlockPoopVariants
    .ELIF i == BLOCK_SPIKE
        .dw BlockPoopVariants
    .ELIF i == BLOCK_METAL
        .dw BlockPoopVariants
    .ELSE
        .dw BlockEmptyVariants
    .ENDIF
.ENDR

BlockEmptyVariants:
    .dw deft($20, 2)
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
        .dw deft($100, 2) | T_FLIPV
    .ELSE
        .dw deft($06, 2)
    .ENDIF
    .REPT 12
        .dw 0
    .ENDR
    .IF i == 0
        .dw deft($104, 2) | T_FLIPH
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
    .dw 0
.ENDR

; INDEXED BY method
; 4B per item
; (doortype & F0) >> 4
DoorTileBaseTable_TOP:
    .dw deft($26, 2), deft($26, 2) ; 0 wall
    .dw deft($88, 2), deft($8A, 2) ; 1 key
    .dw deft($26, 2), deft($26, 2) ; 2 wall
    .dw deft($26, 2), deft($26, 2) ; 3 wall
    .dw deft($68, 2), deft($6A, 2) ; 4 room finish
    .dw deft($26, 2), deft($26, 2) ; 5 wall
    .dw deft($26, 2), deft($26, 2) ; 6 wall
    .dw deft($26, 2), deft($26, 2) ; 7 wall
    .REPT 8
        .dw deft($48, 2), deft($4A, 2) ; 8 open
    .ENDR

DoorTileBaseTable_LEFT:
    .dw deft($06, 2), deft($06, 2) ; 0 wall
    .dw deft($CC, 2), deft($EC, 2) ; 1 key
    .dw deft($06, 2), deft($06, 2) ; 2 wall
    .dw deft($06, 2), deft($06, 2) ; 3 wall
    .dw deft($CA, 2), deft($EA, 2) ; 4 room finish
    .dw deft($06, 2), deft($06, 2) ; 5 wall
    .dw deft($06, 2), deft($06, 2) ; 6 wall
    .dw deft($06, 2), deft($06, 2) ; 7 wall
    .REPT 8
        .dw deft($C8, 2), deft($E8, 2) ; open
    .ENDR

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

.ENDS