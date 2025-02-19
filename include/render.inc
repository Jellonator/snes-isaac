; SPRITE

; A sprite object
.STRUCT object_t
    pos_x db
    pos_y db
    tileid db
    flags db ; vhoopppN
.ENDST

; VRAM
; VRAM is 64KB of 16b words addressed $0000-$7FFF

; sprite OBJ page 0; granularity is (X % $2000) words
; Each 'page' is $1000 words
.DEFINE SPRITE1_BASE_ADDR $6000
; sprite OBJ page 1; should be offset by $1000-$4000 words from page 0
; granularity is (C % $1000) words
.DEFINE SPRITE2_BASE_ADDR $7000
; tile addresses; granularity is (X % $0400) words
.DEFINE BG1_TILE_BASE_ADDR $5400
.DEFINE BG2_TILE_BASE_ADDR $5C00
.DEFINE BG3_TILE_BASE_ADDR $0C00
; character addresses; granularity is (X % $1000) words
.DEFINE BG1_CHARACTER_BASE_ADDR $1000 ; UI
.DEFINE BG2_CHARACTER_BASE_ADDR $3000 ; Background
.DEFINE BG3_CHARACTER_BASE_ADDR $0000 ; Effects

.DEFINE BG2_TILE_ADDR_OFFS_X %0000000000010000
.DEFINE BG2_TILE_ADDR_OFFS_Y %0000001000000000

; VQUEUE

; Maximum number of vqueue elements
.DEFINE VQUEUE_MAX_SIZE 128

; Vqueue - copy to VRAM
.DEFINE VQUEUE_MODE_VRAM 0
; Vqueue - copy to CGRAM
.DEFINE VQUEUE_MODE_CGRAM 2
; Vqueue - clear mem
.DEFINE VQUEUE_MODE_VRAM_CLEAR 4

; VQUEUE OPERATION
; Defines structure for VQueue operation
; An operation copies some amount of memory to VRAM
.STRUCT vqueueop_t SIZE 8
    vramAddr dw
    aAddr dl
    numBytes dw
    mode db
.ENDST

; VQUEUE MINI OPERATION
; Used directly with DMA transfer to VADDR and VDATA
; i.e., copy single words to VRAM
.STRUCT vqueueminiop_t SIZE 4
    vramAddr dw
    data dw
.ENDST

; SPRITE TABLE

; sprite table info
.DEFINE SPRITE_TABLE_SIZE 64
.DEFINE SPRITE_TABLE_CELLAR_SIZE 16
.DEFINE SPRITE_TABLE_TOTAL_SIZE (SPRITE_TABLE_SIZE + SPRITE_TABLE_CELLAR_SIZE)

.ENUMID 64
.ENUMID SPRITE_LIST_EMPTY
.ENUMID SPRITE_QUEUE_SIZE

; SPRITE TABLE ENTRY
; 2-byte structure for extra data contained in sprite table
.STRUCT spritetab_t
    spritemem db ; sprite memory index
    count db ; number of users
.ENDST

; PALETTE INFO

; Palette allocation mode
; bit 1 indicates that [X] is allocated (almost always true)
; bit 2 indicates that [X+1] is allocated
; bit 3 indicates that [X+2] is allocated
.DEFINE PALLETE_ALLOC_NONE 0
.DEFINE PALLETE_ALLOC_8A  %00000001
.DEFINE PALLETE_ALLOC_8B  %00000010
.DEFINE PALLETE_ALLOC_8C  %00000100
.DEFINE PALLETE_ALLOC_12A %00000011
.DEFINE PALLETE_ALLOC_12B %00000110
.DEFINE PALLETE_ALLOC_12C %00000101
.DEFINE PALLETE_ALLOC_16  %00000111

; COLOR FUNCTIONS
.FUNCTION colorf(red, green, blue) ((round(blue * 31) << 10) + (round(green * 31) << 5) + round(blue * 31))
.DEFINE CLEAR_COLOR colorf(0, 0, 0)

; Copy memory from ROM into the next available VQUEUE BIN buffer
.MACRO .CopyROMToVQueueBin ARGS METHOD, ROMADDR, NBYTES
    rep #$20 ; 16 bit A
    lda #NBYTES
    sta.l DMA0_SIZE
    .IF METHOD == P_IMM
        lda #loword(ROMADDR)
    .ELSE
        .g_instruction lda METHOD, ROMADDR
    .ENDIF
    sta.l DMA0_SRCL
    lda.w vqueueBinOffset
    sec
    sbc #NBYTES
    sta.w vqueueBinOffset
    sta.l WMADDL
    sep #$20 ; 8 bit A
    .IF METHOD == P_IMM
        lda #bankbyte(ROMADDR)
    .ELSE
        .g_instruction lda METHOD, (ROMADDR+2)
    .ENDIF
    sta.l DMA0_SRCH
    lda #$7F
    sta.l WMADDH
    ; Absolute address, no increment, 1 byte at a time
    lda #%00000000
    sta.l DMA0_CTL
    ; Write to WRAM
    lda #$80
    sta.l DMA0_DEST
    lda #$01
    sta.l MDMAEN
.ENDM

; Clear a section of WRAM
; Included in render.inc since it is similar to other methods here
.MACRO .ClearWRam ARGS ADDRL, NBYTES
    rep #$20 ; 16 bit A
    lda #NBYTES
    sta.w DMA0_SIZE
    lda #loword(EmptyData)
    sta.w DMA0_SRCL
    lda #loword(ADDRL)
    sta.w WMADDL
    sep #$20 ; 8 bit A
    lda #bankbyte(EmptyData)
    sta.w DMA0_SRCH
    lda #bankbyte(ADDRL)
    sta.w WMADDH
    ; Absolute address, no increment, 1 byte at a time
    lda #%00001000
    sta.w DMA0_CTL
    ; Write to WRAM
    lda #$80
    sta.w DMA0_DEST
    lda #$01
    sta.w MDMAEN
.ENDM

; Clear a section of WRAM
; Only works if D register is $4300
; Slightly faster
; Included in render.inc since it is similar to other methods here
.MACRO .ClearWRam_ZP ARGS ADDRL, NBYTES
    rep #$20 ; 16 bit A
    lda #NBYTES
    sta.b <DMA0_SIZE
    lda #loword(EmptyData)
    sta.b <DMA0_SRCL
    lda #loword(ADDRL)
    sta.l WMADDL
    sep #$20 ; 8 bit A
    lda #bankbyte(EmptyData)
    sta.b <DMA0_SRCH
    lda #bankbyte(ADDRL)
    sta.l WMADDH
    ; Absolute address, no increment, 1 byte at a time
    lda #%00001000
    sta.b <DMA0_CTL
    ; Write to WRAM
    lda #$80
    sta.b <DMA0_DEST
    lda #$01
    sta.l MDMAEN
.ENDM

; Set the S flag in the high table of the current objectIndex
.MACRO .SetCurrentObjectS
    ldx.w objectIndex
    lda.l SpriteIndexToExtMaskS+2,X
    tay
    lda.l SpriteIndexToExtMaskS,X
    ora.w objectDataExt,Y
    sta.w objectDataExt,Y
.ENDM

; Set the S flag in the high table of the current objectIndex
; Increments objectIndex
.MACRO .SetCurrentObjectS_Inc
    .SetCurrentObjectS
    inx
    inx
    inx
    inx
    stx.w objectIndex
.ENDM

; Set the X flag in the high table of the current objectIndex
.MACRO .SetCurrentObjectX
    ldx.w objectIndex
    lda.l SpriteIndexToExtMaskX+2,X
    tay
    lda.l SpriteIndexToExtMaskX,X
    ora.w objectDataExt,Y
    sta.w objectDataExt,Y
.ENDM


; Set the X flag in the high table of the current objectIndex
; Increments objectIndex
.MACRO .SetCurrentObjectX_Inc
    .SetCurrentObjectX
    inx
    inx
    inx
    inx
    stx.w objectIndex
.ENDM

; Set the X and S flags in the high table of the current objectIndex
.MACRO .SetCurrentObjectXS
    ldx.w objectIndex
    lda.l SpriteIndexToExtMaskXS+2,X
    tay
    lda.l SpriteIndexToExtMaskXS,X
    ora.w objectDataExt,Y
    sta.w objectDataExt,Y
.ENDM

; Set the X and S flags in the high table of the current objectIndex
; Increments objectIndex
.MACRO .SetCurrentObjectXS_Inc
    .SetCurrentObjectXS
    inx
    inx
    inx
    inx
    stx.w objectIndex
.ENDM

; get position of sprite object in X
; Result is stored in A
.MACRO .GetObjectPos_X
    phy
    phx
    txa
    lsr
    lsr
    lsr
    lsr
    tay ; Y is index into objectDataExt [0,31]
    lda $01,S
    and #3
    tax ; X is index into SpriteIndexToExtMaskX [0,3]
    lda.l SpriteIndexToExtMaskX,X
    and #$FF
    and.w objectDataExt,Y ; Get X mask
    beq @@@@@\.\@pos
@@@@@\.\@neg:
    plx
    lda.w objectData.1.pos_x,X
    and #$FF
    eor #$FFFF
    sec
    adc #1
    bra @@@@@\.\@end
@@@@@\.\@pos:
    plx
    lda.w objectData.1.pos_x,X
    and #$FF
@@@@@\.\@end:
    ply
.ENDM

; Put the value A into the sprite at index X
.MACRO .PutObjectPos_X
; push
    phy
    pha
    phx
; Y is index into objectDataExt [0,31]
    txa
    lsr
    lsr
    lsr
    lsr
    tay
; X is index into SpriteIndexToExtMaskX [0,3]
    lda $01,S
    and #3
    tax
; Check if A is positive or negative
    lda $03,S
    bpl @@@@@\.\@pos
@@@@@\.\@neg:
    lda.l SpriteIndexToExtMaskX,X
    and #$FF
    ora.w objectDataExt,Y
    sta.w objectDataExt,Y
    lda $03,S
    eor #$FFFF
    sec
    adc #1
    sep #$20 ; 8b A
    plx
    sta.w objectData.1.pos_x,X
    rep #$20 ; 16b A
    bra @@@@@\.\@end
@@@@@\.\@pos:
    lda.l SpriteIndexToExtMaskX,X
    eor #$FFFF
    ora #$FF00
    and.w objectDataExt,Y
    sta.w objectDataExt,Y
    lda $03,S
    sep #$20 ; 8b A
    plx
    sta.w objectData.1.pos_x,X
    rep #$20 ; 16b A
@@@@@\.\@end:
    pla
    ply
.ENDM

; Increment objectIndex
.MACRO .IncrementObjectIndex
    ldx.w objectIndex
    inx
    inx
    inx
    inx
    stx.w objectIndex
.ENDM

; Store current vqueue operation pointer in A
.MACRO .VQueueOpToA
    lda.w vqueueNumOps
    asl
    asl
    asl
.ENDM

; Increment vqueue operation pointer in X
; Clobbers A
.MACRO .VQueueOpIncX
    txa
    clc
    adc #8
    tax
.ENDM

; Copy vqueue bin pointer to X
.MACRO .VQueueBinToX
    ldx.w vqueueBinOffset
.ENDM

; Increments vqueue bin pointer by 'amount'
.MACRO .VQueuePushBinA ARGS method, amount
    lda.w vqueueBinOffset
    sec
    .g_instruction sbc, method, amount
    sta.w vqueueBinOffset
.ENDM

; define tile with character `chr` and palette `pal` [1-7]
.FUNCTION deft(chr, pal) (chr | (pal << 10))

; TILE FLAGS

.DEFINE T_HIGHP 0x2000  ; high priority
.DEFINE T_FLIPH 0x4000  ; flip horizontal
.DEFINE T_FLIPV 0x8000  ; flip vertical
.DEFINE T_FLIPVH 0xC000 ; flip horizontal and vertical

; get next free slot
; Returns index as X
; Useful for animated objects which need their own slots
; Bank needs to be $7E, INDEX and ACCU must be 8
.MACRO .spriteman_get_raw_slot_lite
    dec.w loword(spiteTableAvailableSlots)
    ; ret = *queue->next
    ldx.w loword(spriteQueueTabNext)+SPRITE_LIST_EMPTY
    lda.w loword(spriteQueueTabNext),X
    ; queue->next = queue->next->next (skip X)
    sta.w loword(spriteQueueTabNext)+SPRITE_LIST_EMPTY
    ; rtl
.ENDM

; Free slot in X
; Bank needs to be $7E, INDEX and ACCU must be 8
.MACRO .spriteman_free_raw_slot_lite
    inc.w loword(spiteTableAvailableSlots)
    lda.w loword(spriteQueueTabNext)+SPRITE_LIST_EMPTY
    ; X->next = queue->next
    sta.w loword(spriteQueueTabNext),X
    ; queue->next = X
    stx.w loword(spriteQueueTabNext)+SPRITE_LIST_EMPTY
.ENDM

.MACRO .PaletteIndexToPaletteSpriteA
    .DivideStatic 4
.ENDM

.MACRO .PaletteIndex_X_ToSpriteDef_A
    lda.w paletteAllocMode+1,X
    ror
    ror
    ror
    ror
    ror
    and #$E000
.ENDM