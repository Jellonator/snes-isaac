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
    sep #$20 ; 8 bit A, 16 bit XY
    ; write tile position
    lda $08,s
    sta.l roomInfoSlots.1.tilePos,X
    ; TODO: set door flags
    ; write room size
    ldy #$01
    lda [$0A],Y
    sta.l roomInfoSlots.1.roomSize,X
    ; Copy tile data, applying variants
    ldy #roomdefinition_t.tileData
@tile_copy_loop: ; do {
    lda [$0A],Y
    ; lda #5
    sta.l roomInfoSlots.1.tileTypeTable,X
    ; TODO: proper variant handling
    lda #0
    sta.l roomInfoSlots.1.tileVariantTable,X
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
    sep #$20 ; 8 bit A
    ; Turn slot index into slot address in X
    lda #lobyte(_sizeof_roominfo_t)
    sta MULTS_A
    lda #hibyte(_sizeof_roominfo_t)
    sta MULTS_A
    lda $04,s
    sta MULTS_B
    sta.w loadedMapSlot
    rep #$30 ; 16 bit AXY
    ldx MULTS_RESULT_LOW
    txa
    clc
    adc #loword(roomInfoSlots)
    sta.w loadedMapAddressOffset
; load tiles
    ; Copy default data to vqueueBinData
    .CopyROMToVQueueBin EmptyRoomTiles, 16*16*2
    ; Create operations. 12 are required to copy whole map.
    ; This will also Update the vqueueBinData offset
    rep #$30 ; 16 bit AXY
    lda.w vqueueBinOffset
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
    adc #BG2_TILE_BASE_ADDR
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
    lda.w loadedMapAddressOffset
    clc
    adc #roominfo_t.tileTypeTable
    sta $10 ; $10 = src tile
    clc
    adc #roominfo_t.tileVariantTable-roominfo_t.tileTypeTable
    sta $18 ; $18 = src variant
    lda #$7F
    sta $02 ; $00 = dest bin
    lda #$7E
    sta $12
    sta $1A
    ; Begin iteration
    sep #$10 ; 8b XY
    lda #ROOM_TILE_HEIGHT
    sta $04 ; $04 = Y iterations
@loop_tile_y: ; do {
    lda #ROOM_TILE_WIDTH
    sta $06 ; $06 = X iterations
    @loop_tile_x:
        lda [$10]
        asl
        tax
        lda.w BlockVariantAddresses,X
        sta $08
        lda [$18]
        asl
        tay
        lda ($08),Y
        sta [$00]
        inc $10
        inc $18
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
    rtl

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
    .dw ($0080 | 1024*1)


.DSTRUCT RoomDefinitionTest INSTANCEOF roomdefinition_t VALUES
    doorMask:   .db DOOR_MASK
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
.dw $0002 $0004 $0004 $0004 $0004 $0004 $0004 $000C $000E $0004 $0004 $0004 $0004 $0004 $0004 $4002
.dw $0022 $0024 $0026 $0026 $0026 $0026 $0026 $002C $002E $0026 $0026 $0026 $0026 $0026 $4024 $4022
;              [                                                                       ]
.dw $0022 $0006 $0008 $000A $000A $000A $000A $000A $000A $000A $000A $000A $000A $4008 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0040 $0042 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4042 $4040
.dw $0060 $0062 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4062 $4060
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $8008 $800A $800A $800A $800A $800A $800A $800A $800A $800A $800A $C008 $4006 $4022
;              [                                                                       ]
.dw $0022 $8024 $8026 $8026 $8026 $8026 $8026 $802C $802E $8026 $8026 $8026 $8026 $8026 $C024 $4022
.dw $8002 $8004 $8004 $8004 $8004 $8004 $8004 $800C $800E $8004 $8004 $8004 $8004 $8004 $8004 $C002
.dw $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000
.dw $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000
.dw $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000
.dw $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000

.ENDS