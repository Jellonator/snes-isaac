.IFNDEF _SPRITESLOT_INC
.DEFINE _SPRITESLOT_INC

.InvalidateAX
.SoftSetBank $7E
.SoftSetDirect $0000
.procheaderl "Spriteman.Init"
    .SoftSetAX 8, 8
.endproc

; Get a sprite slot. a 'raw' sprite slot just refers to a single 16x16px tile
; in VRAM to which a sprite can be uploaded. This location will always be in
; the second name table.
; The actual VRAM location this refers to can be looked up via SpriteSlotMemTable.
; Add $0100 to get the VRAM location of the second half of the sprite.
; The sprite tile index to write into the object table can be looked up via 
; SpriteSlotIndexTable.
.SoftSetAX 8, 8
.SoftSetBank $7E
.SoftSetDirect $0000
.procheaderl "Spriteman.GetRawSlot"
.endproc

; Free raw sprite slot in [X]
.SoftSetAX 8, 8
.SoftSetBank $7E
.SoftSetDirect $0000
.procheaderl "Spriteman.FreeRawSlot"
.endproc

; Write character data to a raw sprite slot, allocated with `Spriteman.GetRawSlot`,
; or `.spriteman_get_raw_slot_lite`.
; Args:
; sprite_bank           [db] $05
; spriteTop_location    [dw] $03
; spriteBottom_location [dw] $01
.SoftSetAX 16, 16
.SoftSetBank D_BANK_MIRROR_LOWRAM
.SoftSetDirect $0000
.procheaderl "Spriteman.WriteSpriteToRawSlot"
.endproc

; Allocate a 16x16 sprite slot
; Loads sprite id stored in A
; Sprite ID format: ppssssss ssssssss
;    where `s` is the Sprite index into SpriteDefs, and `p` is the palette swizzle.
;    The palette format is important for swizzling sprite data before upload.
; Returns reference in X.
; Useful for objects which don't need to upload sprites very often.
; To get the raw slot index, lookup via `spriteTableValue + spritetab_t.spritemem`
.SoftSetA 16
.InvalidateX
.SoftSetBank $7E
.SoftSetDirect $0000
.procheaderl "Spriteman.NewSpriteRef"
    .SoftSetA 8
    .InvalidateX
.endproc

; Allocate a 16x16 sprite slot, without writing to it
; Uses unique key stored in A
; Returns reference in X.
; Useful for sharing a sprite between identically animated objects.
; Also returns A=1 if this slot was just allocated, 0 otherwise
; To get the raw slot index, lookup via `spriteTableValue + spritetab_t.spritemem`
; Assumes data bank is $7E
.SoftSetA 16
.InvalidateX
.SoftSetBank $7E
.SoftSetDirect $0000
.procheaderl "Spriteman.NewSpriteRefEmpty"
    .SoftSetAX 16, 16
.endproc

; Increment reference to sprite slot
.SoftSetAX 8, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procheaderl "Spriteman.IncRef"
.endproc

; Decrement reference to sprite slot.
; When the reference count reaches 0, this will free the sprite slot.
.SoftSetAX 8, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procheaderl "Spriteman.UnrefSprite"
    .InvalidateAX
.endproc

; Allocate [A] tiles of sprite *buffer* in RAM
; Returns buffer INDEX in [X]
; This buffer can be used for any purpose, but is intended for decompressing,
; swizzling, or other operations on sprite data that is intended to be uploaded
; to VRAM on demand. e.g., animated sprites with custom palettes.
.SoftSetAX 8, 8
.SoftSetBank $7E
.SoftSetDirect $0000
.procheaderl "Spriteman.AllocRawBuffer"
.endproc

; Free sprite memory buffer [X]
.SoftSetAX 8, 8
.SoftSetBank $7E
.SoftSetDirect $0000
.procheaderl "Spriteman.FreeRawBuffer"
.endproc

; Automatically get or allocate a sprite buffer in RAM.
; This is similar to Spriteman.NewSpriteRef, but for loading animated sprites into RAM.
; Loads sprite id stored in A
; Sprite ID format: ppssssss ssssssss
;    where `s` is the Sprite index into SpriteDefs, and `p` is the palette swizzle.
;    The palette format is important for swizzling sprite data before upload.
; Returns reference in X.
; Unlike NewSpriteRef, the loaded sprite may be multiple tiles in size, and
; will the appropriate amount of RAM.
.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procheaderl "Spriteman.NewBufferRef"
    .SoftSetAX 16, 16
.endproc

; Decrement reference
.SoftSetAX 8, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procheaderl "Spriteman.UnrefBuffer"
    .InvalidateAX
.endproc

; get next free slot
; Returns index as X
; Useful for animated objects which need their own slots
; Bank needs to be $7E, INDEX and ACCU must be 8
.MACRO .spriteman_get_raw_slot_lite
    .ASSERT D_BANK == $7E
    .SetAX 8, 8
    dec.w loword(spriteTableAvailableSlots)
    ; ret = *begin->next
    ldx.w loword(spriteQueueTabNext)+SPRITE_LIST_BEGIN
    lda.w loword(spriteQueueTabNext),X
    ; begin->next = begin->next->next (skip X)
    sta.w loword(spriteQueueTabNext)+SPRITE_LIST_BEGIN
.ENDM

; Free slot in X
; Bank needs to be $7E, INDEX and ACCU must be 8
.MACRO .spriteman_free_raw_slot_lite
    .ASSERT D_BANK == $7E
    .SetAX 8, 8
    ; TODO: handle when queue is empty
    inc.w loword(spriteTableAvailableSlots)
    ; tmp = *end
    lda.w loword(spriteQueueTabNext)+SPRITE_LIST_END
    ; *end = X
    stx.w loword(spriteQueueTabNext)+SPRITE_LIST_END
    ; tmp->next = X
    tax
    lda.w loword(spriteQueueTabNext)+SPRITE_LIST_END
    sta.w loword(spriteQueueTabNext),X
.ENDM

.ENDIF