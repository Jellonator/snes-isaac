.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "SpriteSlotManager"

.MakeChainTableStatic loword(spriteTableKey),loword(spriteTablePtr),SPRITE_TABLE_SIZE,SPRITE_TABLE_CELLAR_SIZE,"_sprite"

; Bank needs to be $7E
spriteman_init:
    phb
    .ChangeDataBank $7E
    sep #$30
    ldx #SPRITE_TABLE_SIZE
@loop:
    txa
    sta.w loword(spriteQueueTabNext)-1,X
    dex
    bne @loop
    lda #$FF
    sta.w loword(spriteQueueTabNext)+63
    lda #0
    sta.w loword(spriteQueueTabNext)+SPRITE_LIST_EMPTY
    plb
    rtl

; get next free slot
; Returns index as X
; Useful for animated objects which need their own slots
; Bank needs to be $7E
.MACRO .spriteman_get_raw_slot_lite
    sep #$30 ; 8b AXY
    ; ret = *queue->next
    ldx.w loword(spriteQueueTabNext)+SPRITE_LIST_EMPTY
    lda.w loword(spriteQueueTabNext),X
    ; queue->next = queue->next->next (skip X)
    sta.w loword(spriteQueueTabNext)+SPRITE_LIST_EMPTY
    ; rtl
.ENDM

spriteman_get_raw_slot:
    phb
    .ChangeDataBank $7E
    .spriteman_get_raw_slot_lite
    plb
    rtl

; write to spritemem X
; Args:
; sprite_bank           [db] $05
; spriteTop_location    [dw] $03
; spriteBottom_location [dw] $01
spriteman_write_sprite_to_raw_slot:
    phb ; >1
    rep #$30 ; 16 bit AXY
; increment vqueueops; just trust that we aren't already in bank $7F
    .VQueueOpToA
    inc.w vqueueNumOps 
    inc.w vqueueNumOps
    tay

; mode[] = VQUEUE_MODE_VRAM
    .ChangeDataBank $7F
    lda #VQUEUE_MODE_VRAM
    sta.w loword(vqueueOps.1.mode),Y ; both param and bAddr
    sta.w loword(vqueueOps.2.mode),Y
; vramaddr[0] = spritemem + SPRITE2_BASE_ADDR
    txa
    asl
    tax
    lda.l SpriteSlotMemTable,X
    sta.w loword(vqueueOps.1.vramAddr),Y
; vramaddr[1] = spritemem + SPRITE2_BASE_ADDR + $100
    clc
    adc #$100
    sta.w loword(vqueueOps.2.vramAddr),Y
; numBytes[] = 2 * 2 * (8 * 8 * 4) / 8 = 128
    lda #64
    sta.w loword(vqueueOps.1.numBytes),Y
    sta.w loword(vqueueOps.2.numBytes),Y
; memAddr[i] = input[i]
    lda $03 + 4,S
    sta.w loword(vqueueOps.1.aAddr),Y
    lda $01 + 4,S
    sta.w loword(vqueueOps.2.aAddr),Y
    sep #$20 ; 8B A
    lda $05 + 4,S
    sta.w loword(vqueueOps.1.aAddr+2),Y
    sta.w loword(vqueueOps.2.aAddr+2),Y
; end
    plb ; <1
    rtl

; Free slot in X
.MACRO .spriteman_free_raw_slot_lite
    sep #$30 ; 8b AXY
    lda.w loword(spriteQueueTabNext)+SPRITE_LIST_EMPTY
    ; X->next = queue->next
    sta.w loword(spriteQueueTabNext),X
    ; queue->next = X
    stx.w loword(spriteQueueTabNext)+SPRITE_LIST_EMPTY
.ENDM

spriteman_free_raw_slot:
    phb
    .ChangeDataBank $7E
    .spriteman_free_raw_slot_lite
    plb
    rtl

SpriteSlotIndexTable:
    .REPT 64 INDEX i
        .db ((i & $7) * 2) + ((i & $38) * 4)
    .ENDR

SpriteSlotMemTable:
    .REPT 64 INDEX i
        .dw ((((i & $7) * 2) + ((i & $38) * 4)) * 16) + SPRITE2_BASE_ADDR
    .ENDR

; Allocate a 16x16 sprite slot
; Loads sprite id stored in A
; Returns reference in X
; Useful for objects which don't need to upload sprites very often
spriteman_new_sprite_ref:
    phb
    .ChangeDataBank $7E
    sta.b $02 ; $02 is sprite ID
    ; insert unique sprite; determine if sprite ID already in use
    jsl table_insert_unique_sprite
    .INDEX 16
    .ACCU 16
    cpy #0
    beq @did_insert
    ; value already existed, increment ref and return
    inc.w loword(spriteTableValue.1.count),X
    plb
    rtl
@did_insert:
    stx.b $00 ; $00 is 16b sprite table ptr
    ; get sprite slot
    .spriteman_get_raw_slot_lite
    .INDEX 8
    .ACCU 8
    ; update sprite table
    txa
    rep #$10 ; 16b X, 8b A
    ldy.b $00
    sta.w loword(spriteTableValue.1.spritemem),Y
    lda.b #1
    sta.w loword(spriteTableValue.1.count),Y
; write sprite data
    rep #$30 ; 16 bit AXY
    .VQueueOpToA
    tax
    lda.w vqueueNumOps
    clc
    adc #2
    sta.w vqueueNumOps
; param[] = 0b00000001, bAddr[] = $18
    lda #VQUEUE_MODE_VRAM
    sta.l vqueueOps.1.mode,X ; both param and bAddr
    sta.l vqueueOps.2.mode,X
; vramaddr[0] = spritemem.x * 32 + spritemem.y * 64 + SPRITE2_BASE_ADDR
    lda loword(spriteTableValue.1.spritemem),Y
    and #$00FF
    asl
    phx
    tax
    lda.l SpriteSlotMemTable,X
    plx
    sta.l vqueueOps.1.vramAddr,X
; vramaddr[1] = spritemem * 16 + SPRITE2_BASE_ADDR + $100
    clc
    adc #$100
    sta.l vqueueOps.2.vramAddr,X
    ; numBytes = 2 * 2 * (8 * 8 * 4) / 8 = 128
    lda #64
    sta.l vqueueOps.1.numBytes,X
    sta.l vqueueOps.2.numBytes,X
    ; aAddr = SpriteDefs[spriteId].addr
    lda.b $02
    dec A
    asl
    asl
    phx
    tax
    tay
    lda.l SpriteDefs + entityspriteinfo_t.sprite_addr,X
    plx
    sta.l vqueueOps.1.aAddr,X
    clc
    adc #64
    sta.l vqueueOps.2.aAddr,X
    sep #$20 ; 8B A
    phx
    tyx
    lda.l SpriteDefs + entityspriteinfo_t.sprite_bank,X
    plx
    sta.l vqueueOps.1.aAddr+2,X
    sta.l vqueueOps.2.aAddr+2,X
    plb
    ldx.b $00
    rtl

; Increment reference 
spriteman_incref:
    phb
    .ChangeDataBank $7E
    .INDEX 16
    sep #$20 ; 8b A
    inc.w loword(spriteTableValue.1.count),X
    plb
    rtl

; Decrement reference
spriteman_unref:
    phb
    .ChangeDataBank $7E
    .INDEX 16
    sep #$20 ; 8b A
    dec.w loword(spriteTableValue.1.count),X
    beq @remove
        ; --X->count > 0
        plb
        rtl
@remove:
    stx.b $00
    lda.w loword(spriteTableValue.1.spritemem),X
    tax
    sep #$10 ; 8b XY
    .spriteman_free_raw_slot_lite
    rep #$30 ; 16b AXY
    ldx.b $00
    lda.w loword(spriteTableKey),X
    jsl table_remove_sprite
    plb
    rtl

.ENDS