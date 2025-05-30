.include "base.inc"

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Familiar" FREE

.DEFINE _gfxptr.1 loword(entity_custom.1)
.DEFINE _gfxptr.2 loword(entity_custom.1+1)
.DEFINE _familiar_parent loword(entity_custom.2)
.DEFINE _palette loword(entity_custom.2+1)
.DEFINE _spritebuffer loword(entity_custom.3)
.DEFINE _shoot_timer entity_timer

.DEFINE FAMILIAR_FOLLOW_DISTANCE 20

.DEFINE BROTHER_BOBBY_FIRE_TIME 32
.DEFINE BROTHER_BOBBY_TEAR_LIFETIME 60
.DEFINE BROTHER_BOBBY_TEAR_DAMAGE 8
.DEFINE BROTHER_BOBBY_TEAR_SPEED $0100

entity_familiar_init:
    .ACCU 16
    .INDEX 16
    sty.b $10
    ; allocate sprite slots
    sep #$30
    .spriteman_get_raw_slot_lite
    txa
    sta.w _gfxptr.1,Y
    .spriteman_get_raw_slot_lite
    txa
    sta.w _gfxptr.2,Y
    ; set or clear parent, depending on context
    ldx.b entityExecutionContext
    cpx #ENTITY_CONTEXT_FAMILIAR
    bne @skip_get_parent
        lda.b entityParentChain
        ; set this entity as next in parent chain
        sty.b entityParentChain
    @skip_get_parent:
    sta.w _familiar_parent,Y
    ; upload palette
    rep #$30
    ldy #loword(palettes.item_brother_bobby)
    lda #8
    jsl Palette.find_or_upload_opaque
    rep #$30
    ldy.b $10
    txa
    sep #$20
    sta.w _palette,Y
    ; upload sprite to buffer
    rep #$30
    .PaletteIndex_X_ToSpriteDef_A
    ora #sprite.familiar.brother_bobby
    jsl Spriteman.NewBufferRef
    rep #$30
    ldy.b $10
    txa
    sta.w _spritebuffer,Y
    ; upload head
    pea $7F7F
    lda.w _spritebuffer,Y
    tax
    lda.w loword(spriteTableValue.1.spritemem),X
    and #$00FF
    xba
    lsr
    clc
    adc #loword(spriteAllocBuffer) + 32*4
    pha
    adc #64
    pha
    lda.w _gfxptr.1,Y
    and #$00FF
    tax
    jsl Spriteman.WriteSpriteToRawSlot
    rep #$30
    pla
    pla
    pla
    ; upload body
    ldy.b $10
    pea $7F7F
    lda.w _spritebuffer,Y
    tax
    lda.w loword(spriteTableValue.1.spritemem),X
    and #$00FF
    xba
    lsr
    clc
    adc #loword(spriteAllocBuffer) + 32*16
    pha
    adc #64
    pha
    lda.w _gfxptr.2,Y
    and #$00FF
    tax
    jsl Spriteman.WriteSpriteToRawSlot
    rep #$30
    pla
    pla
    pla
    ldy.b $10
    rts

entity_familiar_tick:
    .ACCU 16
    .INDEX 16
    ; friction
    lda.w entity_velocx,Y
    .ShiftRight_SIGN 1, 0
    sta.w entity_velocx,Y
    lda.w entity_velocy,Y
    .ShiftRight_SIGN 1, 0
    sta.w entity_velocy,Y
    ; handle movement
    lda.w _familiar_parent,Y
    and #$00FF
    tax
    beql @skip_handle_follow
        ; get distance
        lda.w entity_posx,X
        sec
        sbc.w entity_posx,Y
        .ABS_A16_POSTSBC
        sta.b $00
        lda.w entity_posy,X
        sec
        sbc.w entity_posy,Y
        .ABS_A16_POSTSBC
        clc
        adc.b $00
        ror
        cmp #FAMILIAR_FOLLOW_DISTANCE * $0080
        bcc @skip_handle_follow
        stz.b tempDP
        cmp #(FAMILIAR_FOLLOW_DISTANCE + 8) * $0080
        bcc @continue_to_angle
        inc.b tempDP
        cmp #(FAMILIAR_FOLLOW_DISTANCE + 16) * $0080
        bcc @continue_to_angle
        inc.b tempDP
        cmp #(FAMILIAR_FOLLOW_DISTANCE + 24) * $0080
        bcc @continue_to_angle
        inc.b tempDP
    @continue_to_angle:
        lda.b tempDP
        sta.b tempDP+2
        ; get angle
        jsl Entity.Enemy.DirectTargetEntity
        .ACCU 8
        .INDEX 8
        ldx.b entityTargetAngle
        lda.l SinTable8,X
        .Convert8To16_SIGNED 1, 0
        sta.b $00
        @loop_mult_y:
            dec.b tempDP
            bmi @end_mult_y
            adc.b $00
            jmp @loop_mult_y
        @end_mult_y:
        clc
        adc.w entity_velocy,Y
        sta.w entity_velocy,Y
        sep #$20
        ldx.b entityTargetAngle
        lda.l CosTable8,X
        .Convert8To16_SIGNED 1, 0
        sta.b $00
        @loop_mult_x:
            dec.b tempDP+2
            bmi @end_mult_x
            adc.b $00
            jmp @loop_mult_x
        @end_mult_x:
        clc
        adc.w entity_velocx,Y
        sta.w entity_velocx,Y
    @skip_handle_follow:
    ; add velocity
    rep #$30
    lda.w entity_velocx,Y
    clc
    adc.w entity_posx,Y
    sta.w entity_posx,Y
    lda.w entity_velocy,Y
    clc
    adc.w entity_posy,Y
    sta.w entity_posy,Y
    ; clear X if small enough
    lda.w entity_velocx,Y
    .ABS_A16_POSTLOAD
    cmp #12
    bcs +
        lda #0
        sta.w entity_velocx,Y
    +:
    ; clear Y if small enough
    lda.w entity_velocy,Y
    .ABS_A16_POSTLOAD
    cmp #12
    bcs +
        lda #0
        sta.w entity_velocy,Y
    +:
    ; get tile IDs
    sep #$30
    ldx.w _gfxptr.1,Y
    lda.l SpriteSlotIndexTable,X
    sta.b $00
    ldx.w _gfxptr.2,Y
    lda.l SpriteSlotIndexTable,X
    sta.b $01
    ; write data
    ldx.w objectIndex
    lda.b $01
    sta.w objectData.2.tileid,X
    lda.w entity_posx + 1,Y
    sta.w objectData.1.pos_x,X
    sta.w objectData.2.pos_x,X
    lda.w entity_posy + 1,Y
    clc
    adc #8
    sta.w objectData.2.pos_y,X
    sec
    sbc #16
    sta.w objectData.1.pos_y,X
    ; flags
    lda.w _palette,Y
    .PaletteIndexToPaletteSpriteA
    ora #%00100001
    sta.w objectData.2.flags,X
    sta.w objectData.1.flags,X
    lda.b $00
    sta.w objectData.1.tileid,X
    ; inc object index
    rep #$30
    phy
    .SetCurrentObjectS_Inc
    .SetCurrentObjectS_Inc
    ply
    ; put shadow
    sep #$20
    pea $0405
    jsl EntityPutShadow
    rep #$30
    pla
    ; set box and flags
    .EntityEasySetBox 16, 16
    sep #$20
    lda.w entity_box_y1,Y
    clc
    adc #8
    sta.w loword(entity_ysort),Y
    ; Maybe create projectile
    sep #$30
    lda.w entity_timer,Y
    inc A
    cmp #BROTHER_BOBBY_FIRE_TIME
    bccl @dont_fire_tear
    ; check input
        rep #$20
        lda.w joy1held
        bit #(JOY_A|JOY_B|JOY_Y|JOY_X)
        beql @end_fire_tear
    ; create entity
        jsl Projectile.CreateAndInheritVelocity
        .ACCU 16
        .INDEX 8
        ; life
        lda #BROTHER_BOBBY_TEAR_LIFETIME
        sta.w projectile_lifetime,X
        ; flags
        lda #0
        sta.w loword(projectile_flags),X
        ; damage
        lda #BROTHER_BOBBY_TEAR_DAMAGE
        sta.w projectile_damage,X
        ; velocity
        lda #BROTHER_BOBBY_TEAR_SPEED
        sta.b $00
        jsl Projectile.AddInputVelocity
        ; size
        sep #$20
        lda #2
        sta.w loword(projectile_size),X
        ; type
        lda #PROJECTILE_TYPE_PLAYER_BASIC
        sta.w projectile_type,X
    ; set timer to 0
        sep #$20
        lda #0
@dont_fire_tear:
    sta.w entity_timer,Y
@end_fire_tear:
    ; end
    rts

entity_familiar_free:
    .ACCU 16
    .INDEX 16
    ; free sprites
    sep #$30
    ldx.w _gfxptr.1,Y
    .spriteman_free_raw_slot_lite
    ldx.w _gfxptr.2,Y
    .spriteman_free_raw_slot_lite
    ; free buffer
    rep #$30
    ldx.w _spritebuffer,Y
    phy
    php
    jsl Spriteman.UnrefBuffer
    plp
    ply
    ; free palette
    ldx.w _palette,Y
    jsl Palette.free
    ; end
    rts

.ENDS

.BANK $02 SLOT "ROM"
.SECTION "Entity Familiar Extra" SUPERFREE

Familiars.RefreshFamiliars:
    phb
    .ChangeDataBank $7E
    rep #$20
    lda.b entityExecutionContext
    pha
    lda #ENTITY_CONTEXT_FAMILIAR
    sta.b entityExecutionContext
; determine number of each familiar type needed
    sep #$10
    ldx #0
    @loop_clear:
        stz.w loword(tempData_7E),X
        inx
        inx
        bne @loop_clear
    sep #$30
    ; count from items
    lda.w playerData.playerItemStackNumber + ITEMID_BROTHER_BOBBY
    sta.w loword(tempData_7E) + ENTITY_FAMILIAR_BROTHER_BOBBY
; subtract entities from count
    ldx.w numEntities
    beq @end_loop_entities
    @loop_entities:
        ; get entity at [X]
        ldy.w entityExecutionOrder-1,X
        ; check if entity.type == FAMILIAR, skip otherwise
        lda.w entity_type,Y
        cmp #ENTITY_TYPE_FAMILIAR
        bne @skip_entity
        ; decrement number of familiars needed to spawn for variant
        phx
        ldx.w entity_variant,Y
        dec.w loword(tempData_7E),X
        bpl @skip_entity_plx
        ; if resulting count is less than 0, then free this entity
        ; the previous entity will now be in [X], so we don't need any shenanigans
        php
        jsl entity_free
        plp
    @skip_entity_plx:
        plx
    @skip_entity:
        dex
        bne @loop_entities
    @end_loop_entities:
    lda #ENTITY_INDEX_PLAYER
    sta.b entityParentChain
; now, for each familiar type, spawn familiars
    ldx #0
    @loop_spawn:
        dec.w loword(tempData_7E),X
        bmi @skip_spawn
        phx
        php
        rep #$30
        txa
        xba
        ora #ENTITY_TYPE_FAMILIAR
        jsl entity_create
        lda.w player_posx
        sta.w entity_posx,Y
        lda.w player_posy
        sta.w entity_posy,Y
        jsl entity_init
        plp
        plx
        jmp @loop_spawn
    @skip_spawn:
        inx
        bne @loop_spawn
; end
    rep #$20
    pla
    sta.b entityExecutionContext
    plb
    rtl

Familiars.MoveFamiliarsToPlayer:
    rep #$20
    sep #$10
    ldx.w numEntities
    beq @end_loop_entities
    @loop_entities:
        ; get entity at [X]
        ldy.w entityExecutionOrder-1,X
        ; check if entity.type == FAMILIAR, skip otherwise
        lda.w entity_type,Y
        and #$00FF
        cmp #ENTITY_TYPE_FAMILIAR
        bne @skip_entity
        ; set position
        lda.w player_posx
        sta.w entity_posx,Y
        lda.w player_posy
        sta.w entity_posy,Y
        lda.w player_box_x1
        sta.w entity_box_x1,Y
    @skip_entity:
        dex
        bne @loop_entities
    @end_loop_entities:
    rtl

.ENDS
