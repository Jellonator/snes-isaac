.include "base.inc"
.include "palettes.inc"
.include "rng.inc"
.include "trinket.inc"
.include "consumables.inc"
.include "spriteslot.inc"

; steal state and timer, since they are serialized
.define pickup_price entity_state
.define consumable_type entity_timer ; consumable or trinket type
.define has_put_text loword(entity_custom.2 + 1)
.define pickup_prevention_timer loword(entity_custom.1) ; top byte is pickup prevention flag
.define anim_timer loword(entity_custom.2)
.define loaded_sprite loword(entity_custom.3)
.define loaded_palette loword(entity_custom.3 + 1)
.define sprite_tile loword(entity_custom.0)

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procinterfaces "IVariantHandler"
    .InvalidateAX
.endproc

.BANK $02 SLOT "ROM"
.SECTION "Entity Pickup" SUPERFREE

_variant_sprite_tileflag:
    .dw $0000 ; 0 - null
    .dw $2080 ; 1 - penny
    .dw $2082 ; 2 - nickle
    .dw $2084 ; 3 - dime
    .dw $2088 ; 4 - bomb
    .dw $208E ; 5 - key
    .dw $00A8 ; 6 - battery
    .dw $20AA ; 7 - heart
    .dw $20AC ; 8 - soul heart
    .dw $20A6 ; 9 - consumable (TODO: unique sprites for pills)
    .dw $00A0 ; A - trinket (ignored)

_variant_handlers:
    .dw _handle_null       ; 0 - null
    .dw _handle_penny      ; 1 - penny
    .dw _handle_nickle     ; 2 - nickle
    .dw _handle_dime       ; 3 - dime
    .dw _handle_bomb       ; 4 - bomb
    .dw _handle_key        ; 5 - key
    .dw _handle_battery    ; 6 - battery
    .dw _handle_heart      ; 7 - heart
    .dw _handle_soul_heart ; 8 - soul heart
    .dw _handle_consumable ; 9 - consumable
    .dw _handle_trinket    ; A - trinket

_variant_init:
    .dw _handle_null     ; 0 - null
    .dw _handle_null     ; 1 - penny
    .dw _handle_null     ; 2 - nickle
    .dw _handle_null     ; 3 - dime
    .dw _handle_null     ; 4 - bomb
    .dw _handle_null     ; 5 - key
    .dw _handle_null     ; 6 - battery
    .dw _handle_null     ; 7 - heart
    .dw _handle_null     ; 8 - soul heart
    .dw _handle_null     ; 9 - consumable
    .dw _init_trinket    ; A - trinket

_variant_free:
    .dw _handle_null     ; 0 - null
    .dw _handle_null     ; 1 - penny
    .dw _handle_null     ; 2 - nickle
    .dw _handle_null     ; 3 - dime
    .dw _handle_null     ; 4 - bomb
    .dw _handle_null     ; 5 - key
    .dw _handle_null     ; 6 - battery
    .dw _handle_null     ; 7 - heart
    .dw _handle_null     ; 8 - soul heart
    .dw _handle_null     ; 9 - consumable
    .dw _free_trinket    ; A - trinket

.DEFINE SPAWN_ANIM_FRAMES 22

_spawn_anim_y:
    ; rise: 5
    .db -2, -3, -4, -5, -5,
    ; peak: 6
    .db -6, -6, -6, -6, -6, -6
    ; fall: 5
    .db -5, -5, -4, -3, -1
    ; bounce: 6
    .db 0, -1, -2, -2, -1, 0

; Note: prices are in DECIMAL MODE
PickupVariantPrices:
    .db $01 ; 0 - null
    .db $01 ; 1 - penny
    .db $05 ; 2 - nickle
    .db $10 ; 3 - dime
    .db $05 ; 4 - bomb
    .db $05 ; 5 - key
    .db $05 ; 6 - battery
    .db $03 ; 7 - heart
    .db $05 ; 8 - soul heart
    .db $05 ; 9 - tarot card
    .db $05 ; A - trinket

PickupRandomizerTables:
    .dw PickupTable_Shop
    .dw PickupTable_Any
    .dw PickupTable_Coin
    .dw PickupTable_Heart
    .dw PickupTable_Bomb

PickupTable_Shop:
    .dw   $20, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_BOMB)
    .dw   $20, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_KEY)
    .dw   $20, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_FULL)
    .dw   $20, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_SOUL)
    .dw   $20, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_BATTERY)
    .dw   $20, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_CONSUMABLE)
    .dw   $20, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_TRINKET)
    .dw $FFFF, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_FULL)

PickupTable_Coin:
    .dw     5, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_DIME)
    .dw    25, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_NICKEL)
    .dw $FFFF, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_PENNY)

PickupTable_Heart:
    .dw    50, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_SOUL)
    .dw $FFFF, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_FULL)

PickupTable_Bomb:
    .dw $FFFF, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_BOMB)

PickupTable_Any:
    .dw    48, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_PENNY)
    .dw     3, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_NICKEL)
    .dw     1, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_DIME)
    .dw    50, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_BOMB)
    .dw    50, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_KEY)
    .dw    38, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_FULL)
    .dw     5, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_SOUL)
    .dw    10, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_BATTERY)
    .dw    14, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_CONSUMABLE)
    .dw     7, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_TRINKET)
    .dw $FFFF, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_PENNY)

PickupTable_RoomReward:
    .dw    48, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_PENNY)
    .dw     3, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_NICKEL)
    .dw     1, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_DIME)
    .dw    50, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_BOMB)
    .dw    50, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_KEY)
    .dw    38, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_FULL)
    .dw     5, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_SOUL)
    .dw    10, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_BATTERY)
    .dw    14, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_CONSUMABLE)
    .dw     7, entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_TRINKET)
    .dw $FFFF, 0

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_subtract_money"
    phy
    php
    .ForceSetA 8
    lda.w pickup_price,Y
    beq @skip
    sep #$08
    lda.w playerData.money
    sec
    sbc.w pickup_price,Y
    sta.w playerData.money
    .PlayerHasTrinketEffect TRINKET_PENNY_ON_A_STRING
    beq +
        lda.w playerData.money
        clc
        adc #1
        sta.w playerData.money
    +:
    rep #$08
    jsl UI.update_money_display
@skip:
    plp
    ply
    ; rts - save one byte by just falling through to _handle_null
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_handle_null", "IVariantHandler"
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_handle_penny", "IVariantHandler"
    phy
    php
    .sep $28 ; enable decimal
    lda.w playerData.money
    sec
    sbc.w pickup_price,Y
    clc
    adc #$01
    bcc +
        lda #$99
    +:
    rep #$08 ; disable decimal
    sta.w playerData.money
    jsl UI.update_money_display
    plp
    ply
    ; KILL
    .callsetup "Entity.Free", SETUP_FLAGS
    .call "Entity.Free"
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_handle_nickle", "IVariantHandler"
    phy
    php
    .sep $28 ; enable decimal
    .SoftSetA 8
    lda.w playerData.money
    sec
    sbc.w pickup_price,Y
    clc
    adc #$05
    bcc +
        lda #$99
    +:
    rep #$08 ; disable decimal
    sta.w playerData.money
    jsl UI.update_money_display
    plp
    ply
    ; KILL
    .callsetup "Entity.Free", SETUP_FLAGS
    .call "Entity.Free"
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_handle_dime", "IVariantHandler"
    phy
    php
    .sep $28 ; enable decimal
    .SoftSetA 8
    lda.w playerData.money
    sec
    sbc.w pickup_price,Y
    clc
    adc #$10
    bcc +
        lda #$99
    +:
    rep #$08 ; disable decimal
    sta.w playerData.money
    jsl UI.update_money_display
    plp
    ply
    ; KILL
    .callsetup "Entity.Free", SETUP_FLAGS
    .call "Entity.Free"
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_handle_bomb", "IVariantHandler"
    phy
    php
    sep #$08 ; enable decimal
    lda.w playerData.bombs
    cmp #$99
    beq @skip_add_bombs
    clc
    adc #$01
@skip_add_bombs:
    sta.w playerData.bombs
    rep #$08 ; disable decimal
    jsl UI.update_bomb_display
    plp
    ply
    .callsetup "_subtract_money", SETUP_FLAGS
    .call "_subtract_money"
    ; KILL
    .callsetup "Entity.Free", SETUP_FLAGS
    .call "Entity.Free"
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_handle_key", "IVariantHandler"
    phy
    php
    sep #$08 ; enable decimal
    lda.w playerData.keys
    cmp #$99
    beq @skip_add_keys
    clc
    adc #$01
    sta.w playerData.keys
@skip_add_keys:
    rep #$08 ; disable decimal
    jsl UI.update_key_display
    plp
    ply
    .callsetup "_subtract_money", SETUP_FLAGS
    .call "_subtract_money"
    ; KILL
    .callsetup "Entity.Free", SETUP_FLAGS
    .call "Entity.Free"
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_handle_battery", "IVariantHandler"
    phy
    php
    jsl Item.can_add_charge
    .ForceSetA 8
    cmp #0
    beq @skip
    jsl Item.add_charge_battery
    plp
    ply
    .callsetup "_subtract_money", SETUP_FLAGS
    .call "_subtract_money"
    ; KILL
    .callsetup "Entity.Free", SETUP_FLAGS
    .call "Entity.Free"
    rts
@skip:
    plp
    ply
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_handle_heart", "IVariantHandler"
    phy
    php
    .ForceSetAX 8, 8
    lda #2
    jsl Player.Heal
    cmp #2
    beq +
        ; healed some amount, remove heart
        plp
        ply
        .callsetup "_subtract_money", SETUP_FLAGS
    .call "_subtract_money"
        .callsetup "Entity.Free", SETUP_FLAGS
        .call "Entity.Free"
        rts
    +:
    plp
    ply
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_handle_soul_heart", "IVariantHandler"
    phy
    php
    .ForceSetAX 8, 8
    lda #2
    jsl Player.AddSoulHearts
    cmp #2
    beq +
        ; healed some amount, remove heart
        plp
        ply
        .callsetup "_subtract_money", SETUP_FLAGS
    .call "_subtract_money"
        .callsetup "Entity.Free", SETUP_FLAGS
        .call "Entity.Free"
        rts
    +:
    plp
    ply
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_handle_consumable", "IVariantHandler"
    .callsetup "_subtract_money", SETUP_FLAGS
    .call "_subtract_money"
    .ForceSetAX 8, 8
    phy
    php
    lda.w consumable_type,Y
    jsl Consumable.pickup
    plp
    ply
    .callsetup "Entity.Free", SETUP_FLAGS
    .call "Entity.Free"
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_handle_trinket", "IVariantHandler"
    .callsetup "_subtract_money", SETUP_FLAGS
    .call "_subtract_money"
    .ForceSetAX 8, 8
    phy
    php
    lda.w consumable_type,Y
    jsl Trinket.Pickup
    plp
    ply
    .callsetup "Entity.Free", SETUP_FLAGS
    .call "Entity.Free"
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_init_trinket", "IVariantHandler"
    ; get item definition for trinket
    lda.w consumable_type,Y
    and #$00FF
    asl
    tax
    lda.l Trinket.trinkets,X
    tax
    lda.l bankaddr(Trinket.trinkets) | trinketdef_t.palette_depth,X
    and #$00FF
    sta.b $10
    lda.l bankaddr(Trinket.trinkets) | trinketdef_t.palette_ptr,X
    sta.b $12
    lda.l bankaddr(Trinket.trinkets) | trinketdef_t.sprite_index,X
    and #$00FF
    clc
    adc #sprite.trinkets_small.0
    sta.b $14
    ; load palette for trinket
    phy
    lda.b $10
    ldy.b $12
    jsl Palette.find_or_upload_opaque
    .ForceSetAX 16, 16
    ply
    txa
    .ForceSetA 8
    sta.w loaded_palette,Y
    ; load sprite for trinket
    .ForceSetAX 16, 16
    .PaletteIndex_X_ToSpriteDef_A
    ora.b $14
    phy
    .call "Spriteman.NewSpriteRef"
    .ForceSetAX 16, 16
    ply
    txa
    .ForceSetA 8
    sta.w loaded_sprite,Y
    ; set tile
    lda.w loword(spriteTableValue + spritetab_t.spritemem),X
    tax
    lda.l SpriteSlotIndexTable,X
    sta.w sprite_tile,Y
    ; set flags
    lda.w loaded_palette,Y
    .PaletteIndexToPaletteSpriteA
    ora #%00100001
    sta.w sprite_tile+1,Y
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "_free_trinket", "IVariantHandler"
    .SetAX 16, 16
    phy
    lda.w loaded_sprite,Y
    and #$00FF
    tax
    .callsetup "Spriteman.UnrefSprite", SETUP_FLAGS
    .call "Spriteman.UnrefSprite"
    .SetAX 16, 16
    ply
    ldx.w loaded_palette,Y
    phy
    jsl Palette.free
    .ForceSetAX 16, 16
    ply
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefinel "true_entity_pickup_tick"
    lda #0
    .ForceSetA 8
    lda.w anim_timer,Y
    cmp #SPAWN_ANIM_FRAMES-1
    bcs +
        inc A
        sta.w anim_timer,Y
    +:
    tax
    lda.l _spawn_anim_y,X
    sta.b $00
    ; tile ID
    .ForceSetA 16
    lda.w sprite_tile,Y
    .OX_Get
    sta.w objectData.0.tileid,X
    ; X position
    .ForceSetA 8
    lda.w entity_posx + 1,Y
    sta.w objectData.0.pos_x,X
    ; Y position
    lda.w entity_posy + 1,Y
    clc
    adc.b $00
    sta.w objectData.0.pos_y,X
    sta.w loword(entity_ysort),Y
    .OX_Next_S
; collision detection
    .EntityEasySetBox 16 16
    ; decrement pickup prevention timer
    .ForceSetA 8
    lda.w pickup_prevention_timer,Y
    beq +
        dec a
        sta.w pickup_prevention_timer,Y
    +:
    ; check money
    lda.w playerData.money
    cmp.w pickup_price,Y
    bcc @not_standing_on_pickup
    ; check hitbox
    .EntityEasyCheckNoPlayerCollision_Center @not_standing_on_pickup, 8, 10
        .ForceSetAX 16, 16
        lda.w pickup_prevention_timer,Y ; timer must be 0 and player must have stepped off
        bne @skip_pickup
        lda.w entity_variant,Y
        and #$00FF
        asl
        tax
        .setupcall_in "IVariantHandler"
        jsr (_variant_handlers,X)
        .setupcall_out "IVariantHandler"
        ; if we freed, then quit early
        .ForceSetA 8
        lda.w entity_type,Y
        cmp #ENTITY_TYPE_PICKUP
        beq +
            .EntityTickEnd
        +:
        jmp @skip_pickup
    @not_standing_on_pickup:
        ; disable pickup prevention flag
        .ForceSetA 8
        lda #0
        sta.w pickup_prevention_timer+1,Y
    @skip_pickup:
; maybe put text
    .ForceSetAX 8, 8
    lda.b entityExecutionContext
    cmp #ENTITY_CONTEXT_STANDARD
    bne @no_put_price_text
    lda.w pickup_price,Y
    beq @no_put_price_text
    lda.w has_put_text,Y
    bne @no_put_price_text
        inc A
        sta.w has_put_text,Y
        ; get address
        .ForceSetAX 16, 16
        lda.w entity_box_x1,Y
        and #$00FF
        lsr
        lsr
        lsr
        sta.b $00
        lda.w entity_box_y1,Y
        and #$00F8
        clc
        adc #16
        asl
        asl
        clc
        adc.b $00
        clc
        adc #BG1_TILE_BASE_ADDR
        sta.b $00
        ; get ops
        lda.w vqueueNumMiniOps
        asl
        asl
        tax
        inc.w vqueueNumMiniOps
        inc.w vqueueNumMiniOps
        inc.w vqueueNumMiniOps
        ; set vram address
        lda.b $00
        dec A
        sta.l vqueueMiniOps.0.vramAddr,X
        inc A
        sta.l vqueueMiniOps.1.vramAddr,X
        inc A
        sta.l vqueueMiniOps.2.vramAddr,X
        ; set data
        lda.w pickup_price,Y
        and #$00F0
        beq +
            lsr
            lsr
            lsr
            lsr
            ora #deft(TILE_TEXT_UINUMBER_BASE,5) | T_HIGHP
        +:
        sta.l vqueueMiniOps.0.data,X
        lda.w pickup_price,Y
        and #$000F
        ora #deft(TILE_TEXT_UINUMBER_BASE,5) | T_HIGHP
        sta.l vqueueMiniOps.1.data,X
        lda #deft(TILE_TEXT_UINUMBER_BASE+10,5) | T_HIGHP
        sta.l vqueueMiniOps.2.data,X
@no_put_price_text:
; indicate that this pickup may be bombed
    .SetAX 8, 8
    lda.w has_put_text,Y
    bne @skip_movement
    lda #ENTITY_MASK_BOMBABLE
    sta.w loword(entity_mask),Y
    lda #0
    sta.w entity_signal,Y
; perform movement
    .SetAX 16, 16
    lda.w entity_velocx,Y
    ora.w entity_velocy,Y
    beq @skip_movement
        .SetAX 8, 8
        lda #16
        sta.b $00
        sta.b $01
        .call "Entity.MoveAndCollide"
        .SetAX 16, 16
        lda.w entity_velocx,Y
        .ShiftRight_SIGN 4, FALSE
        bne @continue_friction_x
            sta.w entity_velocx,Y
            jmp @end_friction_x
    @continue_friction_x:
        sta.b $00
        lda.w entity_velocx,Y
        sec
        sbc.b $00
        sta.w entity_velocx,Y
    @end_friction_x:
        lda.w entity_velocy,Y
        .ShiftRight_SIGN 4, FALSE
        bne @continue_friction_y
            sta.w entity_velocy,Y
            jmp @end_friction_y
    @continue_friction_y:
        sta.b $00
        lda.w entity_velocy,Y
        sec
        sbc.b $00
        sta.w entity_velocy,Y
    @end_friction_y:
@skip_movement:
    .EntityTickEnd
.endproc

.SoftSetAX 8, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefinel "true_entity_pickup_init_spawn"
    lda #0
    sta.w pickup_price,Y
    sta.w has_put_text,Y
    sta.b $04
    lda.w entity_variant,Y
    cmp #ENTITY_PICKUP_RANDOM_SHOP
    bne +
        inc.b $04
    +:
    lda.w entity_variant,Y
    bpl @no_pool_randomize
    cmp #$C0
    bcs @no_pool_randomize
        ; get table
        .ForceSetAX 16, 16
        and #$7F
        asl
        tax
        lda.l PickupRandomizerTables,X
        tax
        ; pick from table
        .PushBank
        .ChangeDataBank bankbyte(PickupRandomizerTables)
        lda #$00FF
        .call "Random.Room.PickFromTable"
        .PopBank
        .ForceSetA 8
        xba
        sta.w entity_variant,Y
@no_pool_randomize:
    .SetAX 8, 8
; set price if this is a shop item
    lda #0
    xba
    lda.b $04
    beq @no_set_price
        lda.w entity_variant,Y
        tax
        lda.l PickupVariantPrices,X
        sta.w pickup_price,Y
@no_set_price:
; subtype randomization
    lda.w entity_variant,Y
    ; choose tarot card type if this is a random tarot card
    .SoftSetAX 8, 8
    cmp #ENTITY_PICKUP_RANDOM_CARD
    bne @dont_set_random_card
        ; setup division
        ldx #NUM_CARDS
        jsr _setup_division ; 6 (rts)
        ; variant = consumable
        lda #ENTITY_PICKUP_VARIANT_CONSUMABLE ; 2
        sta entity_variant,Y ; 5
        ; starting index = cards
        lda #CARDS_FIRST_ID ; 2
        jmp @add_subtype ; 3 + 6
        ; = 24 ≥ 16
@dont_set_random_card:
    ; choose pill type if this is a random pill
    .SoftSetAX 8, 8
    cmp #ENTITY_PICKUP_RANDOM_PILL
    bne @dont_set_random_pill
        ; setup division
        ldx #NUM_PILLS
        jsr _setup_division ; 6 (rts)
        ; variant = consumable
        lda #ENTITY_PICKUP_VARIANT_CONSUMABLE ; 2
        sta entity_variant,Y ; 5
        ; starting index = pills
        lda #PILLS_FIRST_ID ; 2
        jmp @add_subtype ; 3 + 6
        ; = 24 ≥ 16
@dont_set_random_pill:
    ; choose consumable type if this is a consumable
    .SoftSetAX 8, 8
    cmp #ENTITY_PICKUP_VARIANT_CONSUMABLE
    bne @dont_set_consumable_type
        ; setup division
        ldx #CONSUMABLE_COUNT-1
        jsr _setup_division ; 6 (rts)
        ; starting index = 1
        lda #1 ; 2
        jmp @add_subtype ; 3 + 6
        ; = 17 ≥ 16
@dont_set_consumable_type:
    ; choose trinket type if this is a trinket
    .SoftSetAX 8, 8
    cmp #ENTITY_PICKUP_VARIANT_TRINKET
    bne @dont_set_trinket_type
        ; setup division
        ldx #TRINKET_COUNT-1
        jsr _setup_division ; 6 (rts)
        ; starting index = 1
        lda #1 ; 2
        jmp @add_subtype ; 3 + 6
        ; = 17 ≥ 16
@add_subtype:
    .SoftSetAX 8, 8
    clc ; 2
    adc.l DIVU_REMAINDER ; 4
    sta.w consumable_type,Y
@dont_set_trinket_type:
    rtl
.endproc

    .ClearContext
    .SoftSetBank $7E
_setup_division:
    .SoftSetAX 8, 8
    .SetA 16
    .call "Random.Room.Update8"
    sta.l DIVU_DIVIDEND
    .SetA 8
    txa
    sta.l DIVU_DIVISOR
    rts
    .ClearContext

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefinel "true_entity_pickup_init"
    lda.b entityExecutionContext
    cmp #ENTITY_CONTEXT_INIT_DESERIALIZE
    beq @deserialized
    cmp #ENTITY_CONTEXT_INIT_DROP
    beq @deserialized
        .SetA 8
        .call "true_entity_pickup_init_spawn"
@deserialized:
    .ForceSetA 8
    lda #0
    sta.w pickup_prevention_timer+1,Y
    sta.w has_put_text,Y
    lda.b entityExecutionContext
    cmp #ENTITY_CONTEXT_INIT_DROP
    bne +
        ; indicate that player must step off of drop before they can pick it up again
        lda #1
        sta.w pickup_prevention_timer+1,Y
    +:
    lda #30
    sta.w pickup_prevention_timer,Y
    .ForceSetX 16
    lda #SPAWN_ANIM_FRAMES-1
    ldx.b entityExecutionContext
    cpx #ENTITY_CONTEXT_STANDARD
    bne +
        lda #0
    +:
    sta.w anim_timer,Y
    ; set default tile
    .ForceSetAX 16, 16
    lda.w entity_variant,Y
    and #$00FF
    asl
    tax
    lda.l _variant_sprite_tileflag,X
    ora #%00100000 * $0100
    sta.w sprite_tile,Y
    ; setup box
    ; necessary so that, if we spawn multiple pickups on the same frame,
    ; they won't overlap.
    .EntityEasySetBox 16 16
    ; initialize pickup by type
    .ForceSetAX 16, 16
    lda.w entity_variant,Y
    and #$00FF
    asl
    tax
    .setupcall_in "IVariantHandler"
    jsr (_variant_init,X)
    .setupcall_out "IVariantHandler"
    rtl
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefinel "true_entity_pickup_free"
    ; free pickup by type
    .SetAX 16, 16
    lda.w entity_variant,Y
    and #$00FF
    asl
    tax
    .setupcall_in "IVariantHandler"
    jsr (_variant_free,X)
    .setupcall_out "IVariantHandler"
    ; maybe erase text
    .ForceSetAX 8, 8
    lda.b entityExecutionContext
    cmp #ENTITY_CONTEXT_STANDARD
    bne @no_erase_price_text
    lda.w has_put_text,Y
    beq @no_erase_price_text
        ; get address
        .ForceSetAX 16, 16
        lda.w entity_box_x1,Y
        and #$00FF
        lsr
        lsr
        lsr
        sta.b $00
        lda.w entity_box_y1,Y
        and #$00F8
        clc
        adc #16
        asl
        asl
        clc
        adc.b $00
        clc
        adc #BG1_TILE_BASE_ADDR
        sta.b $00
        ; get ops
        lda.w vqueueNumMiniOps
        asl
        asl
        tax
        inc.w vqueueNumMiniOps
        inc.w vqueueNumMiniOps
        inc.w vqueueNumMiniOps
        ; set vram address
        lda.b $00
        dec A
        sta.l vqueueMiniOps.0.vramAddr,X
        inc A
        sta.l vqueueMiniOps.1.vramAddr,X
        inc A
        sta.l vqueueMiniOps.2.vramAddr,X
        ; set data
        lda #0
        sta.l vqueueMiniOps.0.data,X
        sta.l vqueueMiniOps.1.data,X
        sta.l vqueueMiniOps.2.data,X
@no_erase_price_text:
    rtl
.endproc

.ENDS

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Pickup Hooks" FREE

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "entity_pickup_init", "IEntityInit"
    .call "true_entity_pickup_init"
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "entity_pickup_free", "IEntityFree"
    .call "true_entity_pickup_free"
    rts
.endproc

.SoftSetAX 16, 16
.SoftSetBank $7E
.SoftSetDirect $0000
.procdefines "entity_pickup_tick", "IEntityTick"
    .tailcall "true_entity_pickup_tick"
.endproc

.ENDS
