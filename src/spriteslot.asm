.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "SpriteSlotManager"

.MakeChainTableStatic loword(spriteTableKey),loword(spriteTablePtr),SPRITE_TABLE_SIZE,SPRITE_TABLE_CELLAR_SIZE,"_sprite"

; Bank needs to be $7E
spriteman_init:
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
    rtl

; get next free slot
; Returns index as X
; Useful for animated objects which need their own slots
; Bank needs to be $7E
spriteman_get_raw_slot:
    sep #$30
    ldx.w loword(spriteQueueTabNext)+SPRITE_LIST_EMPTY
    lda.w loword(spriteQueueTabNext),X
    ; queue->next = queue->next->next (skip X)
    sta.w loword(spriteQueueTabNext)+SPRITE_LIST_EMPTY
    rtl

; Free slot in X
spriteman_free_raw_slot:
    sep #$30
    lda.w loword(spriteQueueTabNext)+SPRITE_LIST_EMPTY
    ; X->next = queue->next
    sta.w loword(spriteQueueTabNext),X
    ; queue->next = X
    stx.w loword(spriteQueueTabNext)+SPRITE_LIST_EMPTY
    rtl

; Allocate a 16x16 sprite slot
; Loads sprite id stored in A
; Returns reference in X
; Useful for objects which don't need to upload sprites very often
spriteman_new_sprite_ref:
    ; insert unique sprite; determine if sprite ID already in use
    jsl table_insert_unique_sprite
    .INDEX 16
    .ACCU 16
    cpy #0
    beq @did_insert
    ; value already existed, increment ref and return
    inc.w loword(spriteTableValue.count),X
    rtl
@did_insert:
    ; get sprite slot
    stx.b $00
    jsl spriteman_get_raw_slot
    .INDEX 8
    .ACCU 8
    ; update sprite table
    txa
    rep #$10 ; 16b X, 8b A
    ldx.b $00
    sta.w loword(spriteTableValue.spritemem),X
    lda.b #1
    sta.w loword(spriteTableValue.count),X
    ; TODO: upload sprite via vqueue
    rtl

; Increment reference 
spriteman_incref:
    .INDEX 16
    sep #$20 ; 8b A
    inc.w loword(spriteTableValue.count),X
    rtl

; Decrement reference
spriteman_unref:
    .INDEX 16
    sep #$20 ; 8b A
    dec.w loword(spriteTableValue.count),X
    beq @remove
        ; --X->count > 0
        rtl
@remove:
    stx.b $00
    lda.w loword(spriteTableValue.spritemem),X
    tax
    sep #$10 ; 8b XY
    jsl spriteman_free_raw_slot
    rep #$30 ; 16b AXY
    ldx.b $00
    lda.w loword(spriteTableKey),X
    jsl table_remove_sprite
    rtl

.ENDS