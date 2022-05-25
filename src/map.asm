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
    sta $10
    sep #$20 ; 8 bit A, 16 bit XY
    lda $06,s
    sta $12
    ; Turn slot index into slot address in X
    lda #lobyte(_sizeof_roominfo_t)
    sta MULTS_A
    lda #hibyte(_sizeof_roominfo_t)
    sta MULTS_A
    lda $07,s
    sta MULTS_B
    ldx MULTS_RESULT_LOW
    ; write tile position
    lda $08,s
    sta.l roomInfoSlots.1.tilePos,X
    ; TODO: set door flags
    ; write room size
    ldy #$01
    lda [$10],Y
    sta.l roomInfoSlots.1.roomSize,X
    ; Copy tile data, applying variants
    ldy #roomdefinition_t.tileData
@tile_copy_loop: ; do {
    lda [$10],Y
    sta.l roomInfoSlots.1.tileTypeTable,X
    ; TODO: proper variant handling
    lda #0
    sta.l roomInfoSlots.1.tileVariantTable,X
    ; while (++Y != ROOM_TILE_COUNT);
    iny
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
    sta loadedMapSlot
    rep #$30 ; 16 bit AXY
    ldx MULTS_RESULT_LOW
    stx loadedMapAddressOffset
    ; load tiles
    ; TODO: improve this
    
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
    .dw $00A0
BlockRockTintedVariants:
    .dw $00A2
BlockPoopVariants:
    .dw $0080

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

.ENDS