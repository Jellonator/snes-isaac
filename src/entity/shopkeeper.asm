.include "base.inc"

.define _palette entity_velocx

.BANK $02 SLOT "ROM"
.SECTION "Entity Shopkeeper" SUPERFREE

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefinel "true_entity_shopkeeper_tick"
    lda #0
    ; check signal
    .ForceSetAX 8, 8
    lda #ENTITY_SIGNAL_KILL
    and.w entity_signal,Y
    beq +
        ; set shopkeeper flag
        lda.l devil_deal_flags
        ora #DEVILFLAG_BOMBED_SHOPKEEPER
        sta.l devil_deal_flags
        .PushContext
        .SetAX 16, 16
        .call "Entity.Free"
        rtl
        .PopContextSoft
    +:
; draw
    .ForceSetX 16
    .REPT 4 INDEX i
        ldx.w loword(entity_custom.{i+1}),Y
        lda.w loword(spriteTableValue + spritetab_t.spritemem),X
        tax
        lda.l SpriteSlotIndexTable,X
        ldx.w objectIndex
        sta.w objectData.{i+1}.tileid,X
    .ENDR
    lda.w entity_box_x1,Y
    sec
    sbc #8
    sta.w objectData.1.pos_x,X
    sta.w objectData.3.pos_x,X
    clc
    adc #16
    sta.w objectData.2.pos_x,X
    sta.w objectData.4.pos_x,X
    lda.w entity_box_y1,Y
    sec
    sbc #8
    sta.w objectData.1.pos_y,X
    sta.w objectData.2.pos_y,X
    clc
    adc #16
    sta.w objectData.3.pos_y,X
    sta.w objectData.4.pos_y,X
    lda.w _palette,Y
    .PaletteIndexToPaletteSpriteA
    ora #%00100001
    sta.w objectData.1.flags,X
    sta.w objectData.2.flags,X
    sta.w objectData.3.flags,X
    sta.w objectData.4.flags,X
    .ForceSetAX 16, 16
    phy
    .SetCurrentObjectS_Inc
    .SetCurrentObjectS_Inc
    .SetCurrentObjectS_Inc
    .SetCurrentObjectS_Inc
    ply
; set public entity info
    .EntityEasySetBox 16 16
    lda #ENTITY_MASK_BOMBABLE
    sta.w entity_mask,Y
    lda #0
    sta.w entity_signal,Y
    lda.w entity_box_y1,Y
    clc
    adc #16
    sta.w loword(entity_ysort),Y
    rtl
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefinel "true_entity_shopkeeper_init"
    ; set hp
    .SetAX 16, 16
    lda #1
    sta.w entity_health,Y
    ; load palette
    phy
    ldy #loword(palettes.shopkeeper)
    lda #8
    jsl Palette.find_or_upload_opaque
    .ForceSetAX 16, 16
    ply
    txa
    sta.w _palette,Y
    .PaletteIndex_X_ToSpriteDef_A
    sta.b $10
    ; load sprite
    .REPT 4 INDEX i
        phy
        lda #sprite.shopkeepers.{i}
        ora.b $10
        jsl Spriteman.NewSpriteRef
        .ForceSetAX 16, 16
        ply
        txa
        sta.w loword(entity_custom.{i+1}),Y
    .ENDR
    rtl
.endproc

.ENDS

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Shopkeeper Hooks" FREE

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "entity_shopkeeper_init", "IEntityInit"
    .call "true_entity_shopkeeper_init"
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "entity_shopkeeper_free", "IEntityFree"
    ; free sprite
    .REPT 4 INDEX i
        phy
        ldx.w loword(entity_custom.{i+1}),Y
        jsl Spriteman.UnrefSprite
        .ForceSetAX 16, 16
        ply
    .ENDR
    ; free palette
    ldx.w _palette,Y
    jsl Palette.free
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "entity_shopkeeper_tick", "IEntityTick"
    .call "true_entity_shopkeeper_tick"
    rts
.endproc

.ENDS
