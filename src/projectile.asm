.include "base.inc"

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

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "ProjectileHooks" FREE

projectile_entity_init:
    ; creator is responsible for setting position, velocity
    rep #$20
    lda #0
    sta.w entity_mask,Y
    ; sta.w entity_signal,Y; implicit by 16b store
    sta.w entity_state,Y
    ; sta.w entity_timer,Y; implicit by 16b store
    sta.w projectile_flags,Y
    sta.w projectile_velocz,Y
    lda #-$0800
    sta.w projectile_height
    rts

projectile_entity_tick:
    jsl projectile_tick__
    rts

projectile_entity_free:
    rts

.ENDS

.BANK $01 SLOT "ROM"
.SECTION "Projectilecode" FREE

; Remove the tear at the index X
; AXY must be 16bit
projectile_slot_free:
    rtl

_projectile_update_sprite:
    ; send to OAM
    sep #$20 ; 8A, 16XY
    rep #$10
    tyx
    ldy.w objectIndex
    lda.w entity_posx+1,X
    sta.w objectData.1.pos_x,Y
    lda.w entity_posy+1,X
    clc
    adc.w projectile_height+1,X
    sta.w objectData.1.pos_y,Y
    lda #$21
    sta.w objectData.1.tileid,Y
    lda #%00101010
    sta.w objectData.1.flags,Y
    lda.w projectile_type,X
    bpl +
        ; different gfx for enemy projectile
        lda #%00101110
        sta.w objectData.1.flags,Y
    +:
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

.define PROJECTILE_TMP_IDX $20
.define PROJECTILE_TMP_POSX $01
.define PROJECTILE_TMP_POSY $02
.define PROJECTILE_TMP_VAL $12
_projectile_delete:
    rep #$30
    ldy.b PROJECTILE_TMP_IDX
    jsl entity_free ; tail call optimization
    rtl

projectile_tick__:
    .INDEX 16
    .ACCU 16
    rep #$30
    sty.b PROJECTILE_TMP_IDX
; Handle lifetime
    lda.w projectile_lifetime,Y
    dec A
    beq _projectile_delete
    sta.w projectile_lifetime,Y
; Apply speed to position
    ; X
    lda.w entity_posx,Y
    clc
    adc.w entity_velocx,Y
    sta.w entity_posx,Y
    ; store X index
    xba
    sep #$20
    clc
    adc #$04
    sta.b PROJECTILE_TMP_POSX
    sta.w entity_box_x2,Y
    lsr
    lsr
    lsr
    lsr
    sta.b PROJECTILE_TMP_VAL
    ; Y
    rep #$20
    lda.w entity_posy,Y
    clc
    adc.w entity_velocy,Y
    sta.w entity_posy,Y
    xba
    sep #$30
    clc
    adc #$04
    sta.b PROJECTILE_TMP_POSY
    sta.w entity_box_y2,Y
; Check tile
    and #$F0
    ora.b PROJECTILE_TMP_VAL
    tax
    lda.l GameTileToRoomTileIndexTable,X
    cmp #97
    bcs _projectile_delete ; remove if oob
    tay
    lda [currentRoomTileTypeTableAddress],Y
    bpl @skipTileHandler
    rep #$30
    and #$00FF
    asl
    tax
    jsr (_ProjectileTileHandlerTable,X)
    jmp _projectile_delete
@skipTileHandler:
; Check collisions
    sep #$30
    ; set detection mask
    lda #ENTITY_MASK_TEAR
    sta.b $00
    lda.w projectile_type,X
    bpl +
        ; enemy projectile: change mask
        lda #ENTITY_MASK_PROJECTILE
        sta.b $00
    +:
    jsl GetEntityCollisionAt ; Y = new entity
    cpy #0
    beq @skipCollisionHandler
        ; found object:
        ; Add veloc
        rep #$30
        ldx.b PROJECTILE_TMP_IDX
        lda.w entity_velocx,X
        .ShiftRight_SIGN 1, FALSE
        adc.w entity_velocx,Y
        sta.w entity_velocx,Y
        lda.w entity_velocy,X
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
        jmp _projectile_delete
@skipCollisionHandler:
    ldy.b PROJECTILE_TMP_IDX
    jsr _projectile_update_sprite
    rtl

.ENDS