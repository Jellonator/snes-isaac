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
    ; sta.l roomSlotTiles.1.tilePos,X
    ; TODO: set door flags
    ; write room size
    ldy #$01
    lda [$0A],Y
    ; sta.l roomSlotTiles.1.roomSize,X
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
    rtl

; Initialize a room slot from a room definition
; Push order:
;   room slot index         [db] $04
LoadRoomSlotIntoLevel:
    ; first, clear existing level
    jsl entity_free_all
    sep #$20 ; 8 bit A
    ; Turn slot index into slot address in X
    lda #lobyte(_sizeof_roominfo_t)
    sta MULTS_A
    lda #hibyte(_sizeof_roominfo_t)
    sta MULTS_A
    lda $04,s
    sta currentRoomSlot
    sta MULTS_B
    sta.w loadedMapSlot
    rep #$30 ; 16 bit AXY
    lda MULTS_RESULT_LOW
    tax
    lda.l roomSlotTiles.1.roomDefinition,X
    sta.b $0A ; $0A: roomDefinition
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
    sep #$10 ; 8b XY
    lda #ROOM_TILE_HEIGHT
    sta $04 ; $04 = Y iterations
    ldy #0
@loop_tile_y: ; do {
    lda #ROOM_TILE_WIDTH
    sta $06 ; $06 = X iterations
    @loop_tile_x:
        lda [currentRoomTileTypeTableAddress],Y
        asl
        tax
        lda.w BlockVariantAddresses,X
        sta $08
        lda [currentRoomTileVariantTableAddress],Y
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
    ldx currentRoomSlot
    lda.l roomSlotMapPos,X
    tay
    tax ; X now contains map position
    lda.l mapDoorVertical-MAP_MAX_WIDTH,X ; top door
    beq +
        rep #$30 ; 16b AXY
        ; TODO: choose door
        ldx $10 ; X is now bin offset
        lda #$000C
        sta.l $7F0000 + ( 7 * 2),X
        lda #$000E
        sta.l $7F0000 + ( 8 * 2),X
        lda #$002C
        sta.l $7F0000 + (23 * 2),X
        lda #$002E
        sta.l $7F0000 + (24 * 2),X
        sep #$30 ; 8b AXY
        tyx
    +:
    lda.l mapDoorVertical,X ; bottom door
    beq +
        rep #$30 ; 16b AXY
        ldx $10 ; X is now bin offset
        lda #$802C
        sta.l $7F0000 + ((16*(2 + ROOM_TILE_HEIGHT) +  7) * 2),X
        lda #$802E
        sta.l $7F0000 + ((16*(2 + ROOM_TILE_HEIGHT) +  8) * 2),X
        lda #$800C
        sta.l $7F0000 + ((16*(2 + ROOM_TILE_HEIGHT) + 23) * 2),X
        lda #$800E
        sta.l $7F0000 + ((16*(2 + ROOM_TILE_HEIGHT) + 24) * 2),X
        sep #$30 ; 8b AXY
        tyx
    +:
    lda.l mapDoorHorizontal-1,X ; left door
    beq +
        rep #$30 ; 16b AXY
        ldx $10 ; X is now bin offset
        lda #$0040
        sta.l $7F0000 + ((16*(2 + 3) +  0) * 2),X
        lda #$0042
        sta.l $7F0000 + ((16*(2 + 3) +  1) * 2),X
        lda #$0060
        sta.l $7F0000 + ((16*(2 + 3) + 16) * 2),X
        lda #$0062
        sta.l $7F0000 + ((16*(2 + 3) + 17) * 2),X
        sep #$30 ; 8b AXY
        tyx
    +:
    lda.l mapDoorHorizontal,X ; right door
    beq +
        rep #$30 ; 16b AXY
        lda #$002C
        ldx $10 ; X is now bin offset
        lda #$4042
        sta.l $7F0000 + ((16*(2 + 3) + 14) * 2),X
        lda #$4040
        sta.l $7F0000 + ((16*(2 + 3) + 15) * 2),X
        lda #$4062
        sta.l $7F0000 + ((16*(2 + 3) + 30) * 2),X
        lda #$4060
        sta.l $7F0000 + ((16*(2 + 3) + 31) * 2),X
        sep #$30 ; 8b AXY
    +:
; spawn entities
    rep #$30 ; 16B AXY
    lda $0A
    tax
    lda.l $020000 + roomdefinition_t.numObjects,X
    and #$00FF
    tay ; Y = num entities
    beq @end
    txa
    clc
    adc #_sizeof_roomdefinition_t
    tax
@loop:
    lda $020000 + objectdef_t.objectType,X
    phy
    phx
    jsl entity_create
    rep #$30
    plx
    sep #$20 ; 8B A
    lda $020000 + objectdef_t.x,X ; X coord
    clc
    adc #ROOM_LEFT
    sta.w entity_posx+1,Y
    lda $020000 + objectdef_t.y,X ; Y coord
    clc
    adc #ROOM_TOP
    sta.w entity_posy+1,Y
    rep #$20 ; 16B A
    ply
    dey
    beq @end
    inx
    inx
    inx
    inx
    bra @loop
@end:
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
    sta $00
    lda [currentRoomTileVariantTableAddress],Y ; get VARIANT
    and #$00FF
    asl
    tay
    lda vqueueNumMiniOps
    asl
    asl
    tax
    lda ($00),Y ; A now contains the actual tile value
    sta vqueueMiniOps.1.data,X
    lda currentConsideredTileY
    asl
    asl
    asl
    asl
    asl
    clc
    adc gameRoomBG2Offset
    clc
    adc currentConsideredTileX
    clc
    adc #2 + 2*32
    sta vqueueMiniOps.1.vramAddr,X
    inc vqueueNumMiniOps
    plb
    rts

.ENDS

.BANK $00 SLOT "ROM"
.SECTION "LevelData" FREE

BlockVariantCount:
    .db 1
    .db 1
    .db 1
    .db 1

BlockVariantAddresses:
    .dw BlockEmptyVariants
    .dw BlockRockVariants
    .dw BlockRockTintedVariants
    .dw BlockPoopVariants

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

.ENDS