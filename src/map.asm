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
    sta $0A
    sep #$20 ; 8 bit A, 16 bit XY
    lda $06,s
    sta $0C
    ; Turn slot index into slot address in X
    lda #lobyte(_sizeof_roominfo_t)
    sta.l MULTS_A
    lda #hibyte(_sizeof_roominfo_t)
    sta.l MULTS_A
    lda $07,s
    sta.l MULTS_B
    rep #$30 ; 16 bit AXY
    lda.l MULTS_RESULT_LOW
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
    rtl

; Initialize a room slot from a room definition
; Push order:
;   room slot index         [db] $04
LoadRoomSlotIntoLevel:
    ; first, clear existing level
    jsl entity_free_all
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
    lda #(%00000001 + ($0100 * $18))
    sta.l vqueueOps.1.param,X ; both param and bAddr
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

; Update the VRAM tile in currentConsideredTile
; Clobbers A, X, and Y
HandleTileChanged:
    .ACCU 16
    .INDEX 16
    phb
    .ChangeDataBank $00
    .TileXYToIndexA currentConsideredTileX, currentConsideredTileY, $04
    tay
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
    lda.b currentConsideredTileY
    asl
    asl
    asl
    asl
    asl
    clc
    adc.w gameRoomBG2Offset
    clc
    adc.b currentConsideredTileX
    clc
    adc #2 + 2*32
    sta.l vqueueMiniOps.1.vramAddr,X
    inc.w vqueueNumMiniOps
    plb
    rts

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

.BANK $00 SLOT "ROM"
.SECTION "LevelData" FREE

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
    .ELSE
        .dw BlockEmptyVariants
    .ENDIF
.ENDR

BlockEmptyVariants:
    .dw $002A
BlockRockVariants:
    .dw ($00A0 | 1024*1)
BlockRockTintedVariants:
    .dw ($00A2 | 1024*1)
BlockPoopVariants:
    .dw ($0080 | 1024*1) ; 0: full
    .dw ($0082 | 1024*1) ; 1: slightly damaged
    .dw ($0084 | 1024*1) ; 2: mostly damaged

.DSTRUCT RoomDefinitionTest INSTANCEOF roomdefinition_t VALUES
    doorMask:   .db DOOR_DEF_MASK
    roomSize:   .db ROOM_SIZE_REGULAR
    numObjects: .db 0
    tileData:
        ;            ;;;;;
        .db 0 0 0 0 0 0 0 0 0 0 0 0
        .db 0 1 1 0 0 0 0 0 0 2 2 0
        .db 0 1 0 0 0 0 0 0 0 0 2 0
        .db 0 0 0 0 0 0 0 0 0 0 0 0 ;
        .db 0 0 0 0 0 0 0 0 0 0 0 0 ;
        .db 0 1 0 0 0 0 0 0 0 0 3 0
        .db 0 2 3 0 0 0 0 0 0 3 3 0
        .db 0 0 0 0 0 0 0 0 0 0 0 0
        ;            ;;;;;
.ENDST

EmptyRoomTiles:
.dw $0002 $0004 $0004 $0004 $0004 $0004 $0004 $0004 $0004 $0004 $0004 $0004 $0004 $0004 $0004 $4002
.dw $0022 $0024 $0026 $0026 $0026 $0026 $0026 $0026 $0026 $0026 $0026 $0026 $0026 $0026 $4024 $4022
;              [                                                                       ]
.dw $0022 $0006 $0008 $000A $000A $000A $000A $000A $000A $000A $000A $000A $000A $4008 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $8008 $800A $800A $800A $800A $800A $800A $800A $800A $800A $800A $C008 $4006 $4022
;              [                                                                       ]
.dw $0022 $8024 $8026 $8026 $8026 $8026 $8026 $8026 $8026 $8026 $8026 $8026 $8026 $8026 $C024 $4022
.dw $8002 $8004 $8004 $8004 $8004 $8004 $8004 $8004 $8004 $8004 $8004 $8004 $8004 $8004 $8004 $C002
.dw $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000
.dw $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000
.dw $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000
.dw $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000

; INDEXED BY method
; 4B per item
; (doortype & F0) >> 4
DoorTileBaseTable_TOP:
    .dw deft($26, 0), deft($26, 0) ; 0 wall
    .dw deft($88, 0), deft($8A, 0) ; 1 key
    .dw deft($26, 0), deft($26, 0) ; 2 wall
    .dw deft($26, 0), deft($26, 0) ; 3 wall
    .dw deft($68, 0), deft($6A, 0) ; 4 room finish
    .dw deft($26, 0), deft($26, 0) ; 5 wall
    .dw deft($26, 0), deft($26, 0) ; 6 wall
    .dw deft($26, 0), deft($26, 0) ; 7 wall
    .REPT 8
        .dw deft($48, 0), deft($4A, 0) ; 8 open
    .ENDR

DoorTileBaseTable_LEFT:
    .dw deft($06, 0), deft($06, 0) ; 0 wall
    .dw deft($CC, 0), deft($EC, 0) ; 1 key
    .dw deft($06, 0), deft($06, 0) ; 2 wall
    .dw deft($06, 0), deft($06, 0) ; 3 wall
    .dw deft($CA, 0), deft($EA, 0) ; 4 room finish
    .dw deft($06, 0), deft($06, 0) ; 5 wall
    .dw deft($06, 0), deft($06, 0) ; 6 wall
    .dw deft($06, 0), deft($06, 0) ; 7 wall
    .REPT 8
        .dw deft($C8, 0), deft($E8, 0) ; 8 open
    .ENDR

; INDEX BY type
; 4B per item
; doortype & 0xF
DoorTileTopperTable_TOP:
    .dw deft($04, 0), deft($04, 0) ; 0 wall
    .dw deft($4C, 0), deft($4E, 0) ; 1 normal
    .dw deft($6C, 0), deft($6E, 0) ; 2 item
    .dw deft($8C, 0), deft($8E, 0) ; 3 shop
    .dw deft($AC, 0), deft($AE, 0) ; 4 boss

DoorTileTopperTable_LEFT:
    .dw deft($22, 0), deft($22, 0) ; 0 wall
    .dw deft($C0, 0), deft($E0, 0) ; 1 normal
    .dw deft($C2, 0), deft($E2, 0) ; 2 item
    .dw deft($C4, 0), deft($E4, 0) ; 3 shop
    .dw deft($C6, 0), deft($E6, 0) ; 4 boss

.ENDS