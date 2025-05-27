.include "base.inc"

.BANK $02 SLOT "ROM"
.SECTION "Entity Tile" SUPERFREE

.DEFINE _entity_spriteptr loword(entity_custom.1)
.DEFINE _entity_hits loword(entity_custom.2)
.DEFINE _entity_paletteptr loword(entity_custom.3)
.DEFINE _entity_bufferptr loword(entity_custom.4)

.DEFINE _entityid $10

true_entity_tile_tick:
    .ACCU 16
    .INDEX 16
    sty.b _entityid
    lda #0
    sep #$20
    ; tile ID 2
    ldx.w _entity_spriteptr,Y
    lda.w loword(spriteTableValue + spritetab_t.spritemem),X
    tax
    lda.l SpriteSlotIndexTable,X
    ldx.w objectIndex
    sta.w objectData.1.tileid,X
    ; X position
    lda.w entity_posx + 1,Y
    sta.w objectData.1.pos_x,X
    ; Y position
    lda.w entity_posy + 1,Y
    sec
    sbc #4
    sta.w objectData.1.pos_y,X
    ; flags
    lda.w _entity_paletteptr,Y
    .PaletteIndexToPaletteSpriteA
    ora #%00100001
    sta.b $02
    lda.w loword(entity_damageflash),Y
    beq +
        dec A
        sta.w loword(entity_damageflash),Y
        lda #%00101111
        sta.b $02
    +:
    lda.b $02
    sta.w objectData.1.flags,X
    rep #$30
    .SetCurrentObjectS_Inc
    ; set box and mask
    ldy.b _entityid
    .EntityEasySetBox 16 14
    sep #$20
    lda #ENTITY_MASK_TEAR | ENTITY_MASK_BOMBABLE
    sta.w entity_mask,Y
    ; check signal
    lda.w entity_signal,Y
    bit #ENTITY_SIGNAL_BOMBED
    bne @destroy
    bit #ENTITY_SIGNAL_DAMAGE
    beq @not_damaged
        lda.w _entity_hits,Y
        dec A
        beq @destroy
        sta.w _entity_hits,Y
        jmp @not_damaged
    @destroy:
        jsl entity_free
        rtl
    @not_damaged:
    lda #0
    sta.w entity_signal,Y
    lda.w entity_box_y1,Y
    clc
    adc #8
    sta.w loword(entity_ysort),Y
    ; damage entities in hitbox
    sep #$30
    lda.w entity_box_y1,Y
    and #$F0
    sta.b $02
    ldx.w entity_box_x1,Y
    lda.l Div16,X
    ora.b $02
    sta.b $02
    tax
    .REPT SPATIAL_LAYER_COUNT INDEX i
        .IF i > 0
            ldx.b $02
        .ENDIF
        ldy.w spatial_partition.{i+1},X
        beql @no_col
        lda.w entity_mask,Y
        bit #ENTITY_MASK_BURNABLE
        beq +
        ; check position
        ldx.b _entityid
        lda.w entity_box_x1,Y
        clc
        adc.w entity_box_x2,Y
        ror
        cmp.w entity_box_x1,X
        bcc +
        cmp.w entity_box_x2,X
        bcs +
        lda.w entity_box_y1,Y
        clc
        adc.w entity_box_y2,Y
        ror
        cmp.w entity_box_y1,X
        bcc +
        cmp.w entity_box_y2,X
        bcs +
            ; burn them
            rep #$20
            lda.w entity_health,Y
            dec A
            sta.w entity_health,Y
            sep #$20
            php
            lda.w entity_signal,Y
            ora #ENTITY_SIGNAL_DAMAGE
            plp
            bpl ++
                ora #ENTITY_SIGNAL_KILL
            ++:
            sta.w entity_signal,Y
        +:
    .ENDR
@no_col:
; update frame, maybe
    ; Set X to a pointer to memory shared between sprite owners
    ; Since the allocated buffer is at least two tiles, we can use unused
    ; data in spriteAllocTabActive
    rep #$30
    ldy.b _entityid
    ldx.w _entity_bufferptr,Y
    lda.w loword(spriteTableValue.1.spritemem),X
    and #$00FF
    tax
    inx
    lda #0
    sep #$20
    ; get frame index
    lda.w tickCounter
    lsr
    lsr
    lsr
    and #$03
    ; skip if frame is current
    cmp.w loword(spriteAllocTabActive),X
    beq @skip_upload
        sta.w loword(spriteAllocTabActive),X
        rep #$30
        jsl entity_tile_set_frame
@skip_upload:
    rtl

entity_tile_set_frame:
    .ACCU 16
    .INDEX 16
    pea $7F7F
    xba
    lsr
    sta.b $00
    ldx.w _entity_bufferptr,Y
    lda.w loword(spriteTableValue.1.spritemem)-1,X
    and #$FF00
    lsr
    adc #loword(spriteAllocBuffer)
    clc
    adc.b $00
    pha
    clc
    adc #64
    pha
    ldx.w _entity_spriteptr,Y
    lda.w loword(spriteTableValue.1.spritemem),X
    and #$00FF
    tax
    jsl Spriteman.WriteSpriteToRawSlot
    ldy.b _entityid
    rep #$30
    pla
    pla
    pla
    rtl

.ENDS

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Tile Hooks" FREE

entity_tile_init:
    .ACCU 16
    .INDEX 16
    sty.b _entityid
    lda #$7FFF
    sta.w entity_health,Y
    lda #3
    sta.w _entity_hits,Y
    ; upload palette
    ldy #loword(palettes.tilesprite_fire_normal)
    lda #8
    jsl Palette.find_or_upload_transparent
    rep #$30
    ldy.b _entityid
    txa
    sta.w _entity_paletteptr,Y
    .PaletteIndex_X_ToSpriteDef_A
    sta.b tempDP
    ; allocate sprite ram
    ora #sprite.tilesprite_fire
    jsl Spriteman.NewBufferRef
    rep #$30
    ldy.b _entityid
    txa
    sta.w _entity_bufferptr,Y
    ; allocate sprite tile
    lda.b tempDP
    ora #sprite.tilesprite_fire_dummy
    jsl Spriteman.NewSpriteRefEmpty
    rep #$30
    ldy.b _entityid
    sta.b tempDP+2
    txa
    sta.w _entity_spriteptr,Y
    ; If this is the first allocation, then upload sprite frame
    lda.b tempDP+2
    beq @dont_upload_sprite
        lda #0
        jsl entity_tile_set_frame
@dont_upload_sprite:
    rts

entity_tile_free:
    .ACCU 16
    .INDEX 16
    sty.b _entityid
    ; Free sprite tile
    lda.w _entity_spriteptr,Y
    tax
    jsl Spriteman.UnrefSprite
    ; free palette
    rep #$30
    ldy.b _entityid
    ldx.w _entity_paletteptr,Y
    jsl Palette.free
    ; free buffer
    rep #$30
    ldy.b _entityid
    ldx.w _entity_bufferptr,Y
    jsl Spriteman.UnrefBuffer
    rts

entity_tile_tick:
    .ACCU 16
    .INDEX 16
    pla
    phk
    pha
    jml true_entity_tile_tick

.ENDS
