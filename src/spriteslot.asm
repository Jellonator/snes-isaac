.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "SpriteSlotManager"

.MakeChainTableStatic loword(spriteTableKey),loword(spriteTablePtr),SPRITE_TABLE_SIZE,SPRITE_TABLE_CELLAR_SIZE,"_sprite"

Spriteman.Init:
    phb
    .ChangeDataBank $7E
    ; initialize sprite queue
    sep #$30
    lda #64
    sta.w loword(spiteTableAvailableSlots)
    ldx #SPRITE_TABLE_SIZE
@loop:
    txa
    sta.w loword(spriteQueueTabNext)-1,X
    dex
    bne @loop
    lda #$FF
    sta.w loword(spriteQueueTabNext)+63
    lda #0
    sta.w loword(spriteQueueTabNext)+SPRITE_LIST_BEGIN
    lda #63
    sta.w loword(spriteQueueTabNext)+SPRITE_LIST_END
    ; initialize sprite alloc
    lda #0
    sta.w loword(spriteAllocTabNext) + 1
    sta.w loword(spriteAllocTabPrev) + 1
    sta.w loword(spriteAllocTabActive) + 1
    lda #255
    sta.w loword(spriteAllocTabSize) + 1
    ; end
    plb
    rtl

; Get a sprite slot. a 'raw' sprite slot just refers to a single 16x16px tile
; in VRAM to which a sprite can be uploaded. This location will always be in
; the second name table.
; The actual VRAM location this refers to can be looked up via SpriteSlotMemTable.
; Add $0100 to get the VRAM location of the second half of the sprite.
; Assumes data bank is $7E
; The sprite tile index to write into the object table can be looked up via 
; SpriteSlotIndexTable.
Spriteman.GetRawSlot:
    sep #$30
    .spriteman_get_raw_slot_lite
    rtl

; Write character data to a raw sprite slot, allocated with `Spriteman.GetRawSlot`,
; or `.spriteman_get_raw_slot_lite`.
; Args:
; sprite_bank           [db] $05
; spriteTop_location    [dw] $03
; spriteBottom_location [dw] $01
; Assumes data bank is $7E (though any bank $00-$3F, $80-$CF will also work)
Spriteman.WriteSpriteToRawSlot:
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

; Frees a sprite slot
; Assumes data bank is $7E
Spriteman.FreeRawSlot:
    sep #$30
    .spriteman_free_raw_slot_lite
    rtl

SpriteSlotIndexTable:
    .REPT 64 INDEX i
        .db ((i & $7) * 2) + ((i & $38) * 4)
    .ENDR

SpriteSlotMemTable:
    .REPT 64 INDEX i
        .dw ((((i & $7) * 2) + ((i & $38) * 4)) * 16) + SPRITE2_BASE_ADDR
    .ENDR

.DEFINE SPRITEID_PAL $E000
.DEFINE SPRITEID_SPRITE $1FFF

; Allocate a 16x16 sprite slot
; Loads sprite id stored in A
; Sprite ID format: pppsssss ssssssss
;    where `s` is the Sprite index into SpriteDefs, and `p` is the palette format.
;    The palette format is important for swizzling sprite data before upload.
; Returns reference in X.
; Useful for objects which don't need to upload sprites very often.
; To get the raw slot index, lookup via `spriteTableValue + spritetab_t.spritemem`
; Assumes data bank is $7E
Spriteman.NewSpriteRef:
    sta.b $02 ; $02 is sprite ID
    ; insert unique sprite; determine if sprite ID already in use
    jsl table_insert_unique_sprite
    .INDEX 16
    .ACCU 16
    cpy #0
    beq @did_insert
    ; value already existed, increment ref and return
    inc.w loword(spriteTableValue.1.count),X
    rtl
@did_insert:
    stx.b $00 ; $00 is 16b sprite table ptr
    ; get sprite slot
    sep #$30
    .spriteman_get_raw_slot_lite
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
    ; get Sprite address
    lda.b $02
    and #SPRITEID_SPRITE
    asl
    asl
    phx
    tax
    lda.l SpriteDefs + entityspriteinfo_t.sprite_addr,X
    sta.b $04
    lda.l SpriteDefs + entityspriteinfo_t.sprite_bank,X
    sta.b $06
    ; interlude: determine swizzle
    lda.b $02
    rol
    rol
    rol
    rol
    and #$0007
    sta.b $08
    tax
    lda.l PaletteAllocNeedSwizzle,X
    and #$00FF
    beq @no_swizzle
        ; swizzle step 1: Copy sprite to vqueueBinData
        .CopyROMToVQueueBin P_DIR, $04, 128
        ; swizzle step 2: Swizzle
        rep #$30
        ldx.w vqueueBinOffset
        lda.b $08
        ldy #4
        jsl SpritePaletteSwizzle_B7F
        ; step 3: set new address
        sep #$20
        lda #$7F
        sta.b $06
        rep #$20
        lda.w vqueueBinOffset
        sta.b $04
@no_swizzle:
    ; aAddr = SpriteDefs[spriteId].addr
    plx
    lda.b $04
    sta.l vqueueOps.1.aAddr,X
    clc
    adc #64
    sta.l vqueueOps.2.aAddr,X
    sep #$20
    lda.b $06
    sta.l vqueueOps.1.aAddr+2,X
    sta.l vqueueOps.2.aAddr+2,X
    ldx.b $00
    rtl

; Increment reference
; Assumes data bank is $7E
Spriteman.IncRef:
    .INDEX 16
    sep #$20 ; 8b A
    inc.w loword(spriteTableValue.1.count),X
    rtl

; Decrement reference
; Assumes data bank is $7E
Spriteman.Unref:
    .INDEX 16
    sep #$20 ; 8b A
    dec.w loword(spriteTableValue.1.count),X
    beq @remove
        ; --X->count > 0
        rtl
@remove:
    stx.b $00
    lda.w loword(spriteTableValue.1.spritemem),X
    tax
    sep #$30
    .spriteman_free_raw_slot_lite
    rep #$30 ; 16b AXY
    ldx.b $00
    lda.w loword(spriteTableKey),X
    jsl table_remove_sprite
    rtl

_spriteman_allocbuffer_fail:
    .INDEX 8
    .ACCU 8
    ldx #$00
    rts
; Allocate [A] tiles of sprite *buffer* in RAM
; This buffer can be used for any purpose, but is intended for decompressing,
; swizzling, or other operations on sprite data that is intended to be uploaded
; to VRAM on demand. e.g., animated sprites with custom palettes
Spriteman.AllocRawBuffer:
    sep #$30
    ldx #1
; search for block with appropriate size
    @loop_search:
        ; if this block is active, then skip
        ldy.w loword(spriteAllocTabActive),X
        bne @search_skip
            ; check if block has enough space
            cmp.w loword(spriteAllocTabSize),X
            bcc @found
            beq @found
        @search_skip:
        ; set X to next block index
        xba
        lda.w loword(spriteAllocTabNext),X
        beq _spriteman_allocbuffer_fail ; if NEXT == 0: fail
        tax
        xba
        jmp @loop_search
@store_and_ret:
; set block's size and active status without modifying anything else
    sta.w loword(spriteAllocTabSize),X
    lda #1
    sta.w loword(spriteAllocTabActive),X
    rtl
@found:
; if size does not change, then perform shortcut
    cmp.w loword(spriteAllocTabSize),X
    beq @store_and_ret
; set block's size and active status
    sta.w loword(spriteAllocTabSize),X
    lda #1
    sta.w loword(spriteAllocTabActive),X
; split block into two, at `size` boundary
    pha
    ; NEXT = CURRENT + CURRENT->size
    txa
    clc
    adc.w loword(spriteAllocTabSize),X
    tay
    ; NEXT->next = CURRENT->next
    lda.w loword(spriteAllocTabNext),X
    sta.w loword(spriteAllocTabNext),Y
    ; NEXT->prev = CURRENT
    txa
    sta.w loword(spriteAllocTabPrev),Y
    ; CURRENT->next = NEXT
    tya
    sta.w loword(spriteAllocTabNext),X
    ; NEXT->active = 0
    lda #0
    sta.w loword(spriteAllocTabActive),Y
    ; NEXT->size = previous_size - CURRENT->size
    pla
    sec
    sbc.w loword(spriteAllocTabSize),X
    sta.w loword(spriteAllocTabSize),Y
    ; if NEXT->next != NULL:
    lda.w loword(spriteAllocTabNext),Y
    beq @dont_set_next_prev
        ; NEXT->next->prev = NEXT
        tay ; Y = NEXT->next
        lda.w loword(spriteAllocTabNext),X
        sta.w loword(spriteAllocTabPrev),Y
@dont_set_next_prev:
; end
    rtl

; Free sprite memory buffer [X]
Spriteman.FreeRawBuffer:
    sep #$30
    cpx #0
    beq @skip_merge_prev
    ; indicate block is inactive
    stz.w loword(spriteAllocTabActive),X
; check if next block is inactive. if so, then merge with this block
    ; Y = X->next
    ldy.w loword(spriteAllocTabNext),X
    beq @skip_merge_next ; skip if X->next == NULL
    lda.w loword(spriteAllocTabActive),Y
    bne @skip_merge_next ; skip if X->next->active == true
        ; X->size = X->size + Y->size
        lda.w loword(spriteAllocTabSize),X
        clc
        adc.w loword(spriteAllocTabSize),Y
        sta.w loword(spriteAllocTabSize),X
        ; X->next = Y->next
        lda.w loword(spriteAllocTabNext),Y
        sta.w loword(spriteAllocTabNext),X
        ; Y->next->prev = X
        tay ; Y = Y->next
        beq @skip_merge_next ; skip if Y->next == NULL
        txa
        sta.w loword(spriteAllocTabPrev),Y
@skip_merge_next:
; check if prev block is inactive. if so, then merge into previous block
    ; Y = X->prev
    ldy.w loword(spriteAllocTabPrev),X
    beq @skip_merge_prev ; skip if X->next == NULL
    lda.w loword(spriteAllocTabNext),Y
    bne @skip_merge_prev ; skip if X->prev->active == true
        ; Y->size = X->size + Y->size
        lda.w loword(spriteAllocTabSize),X
        clc
        adc.w loword(spriteAllocTabSize),Y
        sta.w loword(spriteAllocTabSize),Y
        ; Y->next = X->next
        lda.w loword(spriteAllocTabNext),X
        sta.w loword(spriteAllocTabNext),Y
        ; X->next->prev = Y
        tax ; X = X->next
        beq @skip_merge_prev
        tya
        sta.w loword(spriteAllocTabPrev),X
@skip_merge_prev:
    rtl

; Swizzle a sprite that is located in bank 7F according to palette
; Parameters:
;     X - pointer to sprite
;     A - swizzle mode (0-7); see PALLETE_ALLOC_
;     Y - number of tiles
; Only the third and fourth bitplanes are modified
SpritePaletteSwizzle_B7F:
    .INDEX 16
    .ACCU 16
    sep #$20
    cmp #PALLETE_ALLOC_8B
    beql _Swizzle_B7F_B_AB@entry
    cmp #PALLETE_ALLOC_12B
    beql _Swizzle_B7F_B_AB@entry
    cmp #PALLETE_ALLOC_8C
    beql _Swizzle_B7F_A_A@entry
    cmp #PALLETE_ALLOC_12C
    beql _Swizzle_B7F_AB_B@entry
    rtl

_Swizzle_B7F_A_A:
    .INDEX 16
    .ACCU 8
@loop:
    rep #$20
    txa
    clc
    adc #32
    tax
    sep #$20
@entry:
    .REPT 8 INDEX i
        lda.l $7F0000+2*i+16,X
        sta.l $7F0000+2*i+17,X
    .ENDR
    dey
    bne @loop
    rtl

_Swizzle_B7F_B_AB:
    .INDEX 16
    .ACCU 8
@loop:
    rep #$20
    txa
    clc
    adc #32
    tax
    sep #$20
@entry:
    .REPT 8 INDEX i
        lda.l $7F0000+2*i+17,X
        xba
        lda.l $7F0000+2*i+17,X
        ora.l $7F0000+2*i+16,X
        sta.l $7F0000+2*i+17,X
        xba
        sta.l $7F0000+2*i+16,X
    .ENDR
    dey
    bnel @loop
    rtl

_Swizzle_B7F_AB_B:
    .INDEX 16
    .ACCU 8
@loop:
    rep #$20
    txa
    clc
    adc #32
    tax
    sep #$20
@entry:
    .REPT 8 INDEX i
        lda.l $7F0000+2*i+17,X
        ora.l $7F0000+2*i+16,X
        sta.l $7F0000+2*i+16,X
    .ENDR
    dey
    bne @loop
    rtl

; Make a sprite Opaque
; Parameters:
;     X - pointer to sprite
;     A - color (0-15)
;     Y - number of tiles
; Only the third and fourth bitplanes are modified
SpritePaletteOpaqueify_7F:
    rep #$10
    sep #$20
    stz.b $00
    stz.b $01
    stz.b $02
    stz.b $03
    bit #$01
    beq +
        dec.b $00
    +:
    bit #$02
    beq +
        dec.b $01
    +:
    bit #$04
    beq +
        dec.b $02
    +:
    bit #$08
    beq +
        dec.b $03
    +:
@loop_begin:
    .REPT 8 INDEX i
        ; get mask
        lda.l $7F0000+2*i+$00,X
        ora.l $7F0000+2*i+$01,X
        ora.l $7F0000+2*i+$10,X
        ora.l $7F0000+2*i+$11,X
        sta.b $06
        eor #$FF
        sta.b $05
        ; AND self
        lda.b $06
        and.l $7F0000+2*i+$00,X
        sta.l $7F0000+2*i+$00,X
        lda.b $06
        and.l $7F0000+2*i+$01,X
        sta.l $7F0000+2*i+$01,X
        lda.b $06
        and.l $7F0000+2*i+$10,X
        sta.l $7F0000+2*i+$10,X
        lda.b $06
        and.l $7F0000+2*i+$11,X
        sta.l $7F0000+2*i+$11,X
        ; OR new color
        lda.b $05
        and.b $00
        ora.l $7F0000+2*i+$00,X
        sta.l $7F0000+2*i+$00,X
        lda.b $05
        and.b $01
        ora.l $7F0000+2*i+$01,X
        sta.l $7F0000+2*i+$01,X
        lda.b $05
        and.b $02
        ora.l $7F0000+2*i+$10,X
        sta.l $7F0000+2*i+$10,X
        lda.b $05
        and.b $03
        ora.l $7F0000+2*i+$11,X
        sta.l $7F0000+2*i+$11,X
    .ENDR
    dey
    beq @loop_end
    rep #$20
    txa
    clc
    adc #32
    tax
    sep #$20
    jmp @loop_begin
@loop_end:
    rtl

.ENDS