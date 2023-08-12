.include "base.inc"

.DEFINE TempTileX $08
.DEFINE TempTileY $0A
.DEFINE TempTileX2 $0C
.DEFINE TempTileY2 $0E
.DEFINE TempTemp1 $14
.DEFINE TempTemp2 $16

.MACRO .PositionToIndex_A
    xba
    and #$00F0
    lsr
    lsr
    lsr
    lsr
.ENDM

.MACRO .IndexToPosition_A
    asl
    asl
    asl
    asl
    xba
.ENDM

.BANK $01 SLOT "ROM"
.SECTION "Projectilecode" FREE

; Get the next available tear slot, and store it in X
; if there are no available slots, the tear with the lowest life will be chosen
projectile_slot_get:
    rep #$30 ; 16 bit AXY
    ldx.w projectile_count_2x
    cpx #PROJECTILE_LIST_SIZE_2X
    bne @has_empty_slots
; no empty slots available:
; find the slot with the lowest lifetime
    lda #$7FFF
    sta $00 ; $00 is best value
    ldx #0 ; x is current index
    ldy #0 ; Y is best index
@iter_tears:
    lda.w projectile_lifetime,X
    cmp $00
    bcs @skip_store
    sta $00
    txy ; if tears[X].lifetime < tears[Y].lifetime: Y=X
@skip_store:
    inx
    inx
; X == 0
    cpx.w projectile_count_2x
    bne @iter_tears
; Finish, transfer Y to X
    tyx
    rts
; empty slots available:
@has_empty_slots:
    inx
    inx
    stx.w projectile_count_2x
    dex
    dex
    rtl

; Remove the tear at the index X
; AXY must be 16bit
projectile_slot_free:
    rep #$30 ; 16 bit AXY
    ; decrement number of used tears
    ldy.w projectile_count_2x
    beq @skip_copy
    dey
    dey
    sty.w projectile_count_2x
    ; Check if X is the last available tear slot
    cpx.w projectile_count_2x
    beq @skip_copy
    ; copy last tear slot to slot being removed
    .REPT 8 INDEX i
        lda.w projectile_velocx+(PROJECTILE_ARRAY_MAX_COUNT*2*i),Y
        sta.w projectile_velocx+(PROJECTILE_ARRAY_MAX_COUNT*2*i),X
    .ENDR
@skip_copy:
    rtl

_projectile_update_sprite:
    ; send to OAM
    sep #$20 ; 8A, 16XY
    ldy.w objectIndex
    lda.w projectile_posx+1,X
    sta.w objectData.1.pos_x,Y
    lda.w projectile_posy+1,X
    sec
    sbc $08
    sta.w objectData.1.pos_y,Y
    lda #$21
    sta.w objectData.1.tileid,Y
    lda #%00101010
    sta.w objectData.1.flags,Y
    iny
    iny
    iny
    iny
    sty.w objectIndex
    rts

_projectile_tile_do_nothing:
    .INDEX 16
    .ACCU 16
    rts

_projectile_tile_poop:
    .INDEX 16
    .ACCU 16
    sep #$20 ; 8 bit A
    lda [currentRoomTileVariantTableAddress],Y
    cmp #2
    beq @removeTile
    inc A
    sta [currentRoomTileVariantTableAddress],Y
    rep #$20 ; 16 bit A
    jsr HandleTileChanged
    rts
@removeTile:
    sep #$20 ; 8 bit A
    lda #0
    sta [currentRoomTileVariantTableAddress],Y
    lda #BLOCK_REGULAR
    sta [currentRoomTileTypeTableAddress],Y
    rep #$20 ; 16 bit A
    jsr HandleTileChanged
    rts

_ProjectileTileHandlerTable:
.REPT 256 INDEX i
    .IF i == BLOCK_POOP
        .dw _projectile_tile_poop
    .ELSE
        .dw _projectile_tile_do_nothing
    .ENDIF
.ENDR

projectile_update_loop:
    rep #$30 ; 16 bit AXY
    phb
    .ChangeDataBank $7E
    ldx #$0000
    cpx.w projectile_count_2x
    bcc @iter
    plb
    rtl
@iter_remove:
    jsl projectile_slot_free
    ; No ++X, but do check that this is the end of the array
    cpx.w projectile_count_2x ; X < tear_bytes_used
    bcc @iter
    plb
    rtl
@iter:
; Handle lifetime
    lda.w projectile_lifetime,X
    dec A
    beq @iter_remove
    sta.w projectile_lifetime,X
    AMINUI 8
    sta.w $08 ; $08 is tear height
; Apply speed to position
    lda.w projectile_posx,X
    clc
    adc.w projectile_velocx,X
    sta.w projectile_posx,X
    clc
    adc #(4-ROOM_LEFT)*256
    .PositionToIndex_A
    sta currentConsideredTileX
    lda.w projectile_posy,X
    clc
    adc.w projectile_velocy,X
    sta.w projectile_posy,X
    clc
    adc #(-ROOM_TOP)*256
    .PositionToIndex_A
    sta currentConsideredTileY
; Check tile
    .BranchIfTileXYOOB currentConsideredTileX, currentConsideredTileY, @iter_remove
    .TileXYToIndexA currentConsideredTileX, currentConsideredTileY, TempTemp1
    tay
    sep #$20
    lda [currentRoomTileTypeTableAddress],Y
    rep #$20
    bpl @skipTileHandler
    phx
    php
    and #$00FF
    asl
    tax
    jsr (_ProjectileTileHandlerTable,X)
    plp
    plx
    brl @iter_remove
@skipTileHandler:
; Check collisions
    pha
    phx
    phy
    sep #$30
    lda #ENTITY_MASK_TEAR
    sta.b $00
    lda.w projectile_posx+1,X
    clc
    adc #4
    sta.b $01
    lda.w projectile_posy+1,X
    clc
    adc #4
    sta.b $02
    jsl GetEntityCollisionAt
    cpy #0
    beq @skipCollisionHandler
        ; found object:
        ; Add veloc
        rep #$30
        lda $03,S
        tax
        lda.w projectile_velocx,X
        .ShiftRight_SIGN 1, FALSE
        adc.w entity_velocx,Y
        sta.w entity_velocx,Y
        lda.w projectile_velocy,X
        .ShiftRight_SIGN 1, FALSE
        adc.w entity_velocy,Y
        sta.w entity_velocy,Y
        ; reduce HP
        lda.w entity_health,Y
        sec
        sbc #4
        sta.w entity_health,Y
        bcs +
            ; kill target
            sep #$20
            lda.w entity_signal,Y
            ora #ENTITY_SIGNAL_KILL
            sta.w entity_signal,Y
            rep #$30
        +:
        ply
        plx
        pla
        brl @iter_remove
@skipCollisionHandler:
    rep #$30
    ply
    plx
    pla
; Update rest of tear info
    jsr _projectile_update_sprite
    rep #$30 ; 16AXY
    inx
    inx
    cpx.w projectile_count_2x
    bcs @end
    jmp @iter
@end:
    plb
    rtl

.ENDS