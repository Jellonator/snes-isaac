.include "base.inc"
.include "room.inc"
.include "consumables.inc"
.include "player.inc"

.BANK $01 SLOT "ROM"
.SECTION "Pathing" FREE

.DSTRUCT Consumable.definitions.null INSTANCEOF consumable_t VALUES
    name: .ASCSTR "null", 0
    tagline: .ASCSTR "May you find a real card", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.22
    sprite_big_palette: .dw 0
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_fool INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Fool", 0
    tagline: .ASCSTR "Where journey begins", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.0
    sprite_big_palette: .dw loword(palettes.tarot_cards1)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _tarot_fool
.ENDST

.DSTRUCT Consumable.definitions.tarot_magician INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Magician", 0
    tagline: .ASCSTR "May you never miss your goal", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.1
    sprite_big_palette: .dw loword(palettes.tarot_cards_magician)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_high_priestess INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The High priestess", 0
    tagline: .ASCSTR "Mother is watching you", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.2
    sprite_big_palette: .dw loword(palettes.tarot_cards_high_priestess)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_empress INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Empress", 0
    tagline: .ASCSTR "May your rage bring power", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.3
    sprite_big_palette: .dw loword(palettes.tarot_cards_empress)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_emperor INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Emperor", 0
    tagline: .ASCSTR "Challenge me!", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.4
    sprite_big_palette: .dw loword(palettes.tarot_cards_emperor)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _tarot_emperor
.ENDST

.DSTRUCT Consumable.definitions.tarot_hierophant INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Hierophant", 0
    tagline: .ASCSTR "Two prayers for the lost", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.5
    sprite_big_palette: .dw loword(palettes.tarot_cards_hierophant)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _tarot_hierophant
.ENDST

.DSTRUCT Consumable.definitions.tarot_lovers INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Lovers", 0
    tagline: .ASCSTR "May you prosper", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.6
    sprite_big_palette: .dw loword(palettes.tarot_cards_lovers)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _tarot_lovers
.ENDST

.DSTRUCT Consumable.definitions.tarot_chariot INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Chariot", 0
    tagline: .ASCSTR "May nothing stand before you", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.7
    sprite_big_palette: .dw loword(palettes.tarot_cards_chariot)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_strength INSTANCEOF consumable_t VALUES
    name: .ASCSTR "Strength", 0
    tagline: .ASCSTR "May your power bring rage", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.8
    sprite_big_palette: .dw loword(palettes.tarot_cards_strength)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_hermit INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Hermit", 0
    tagline: .ASCSTR "May you find solace", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.9
    sprite_big_palette: .dw loword(palettes.tarot_cards_hermit)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _tarot_hermit
.ENDST

.DSTRUCT Consumable.definitions.tarot_wheel_of_fortune INSTANCEOF consumable_t VALUES
    name: .ASCSTR "Wheel of Fortune", 0
    tagline: .ASCSTR "Spin the wheel of destiny", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.10
    sprite_big_palette: .dw loword(palettes.tarot_cards_wheel_of_fortune)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_justice INSTANCEOF consumable_t VALUES
    name: .ASCSTR "Justice", 0
    tagline: .ASCSTR "May your future be balanced", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.11
    sprite_big_palette: .dw loword(palettes.tarot_cards_justice)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _tarot_justice
.ENDST

.DSTRUCT Consumable.definitions.tarot_hanged_man INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Hanged Man", 0
    tagline: .ASCSTR "May you find enlightenment", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.12
    sprite_big_palette: .dw loword(palettes.tarot_cards_hanged_man)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_death INSTANCEOF consumable_t VALUES
    name: .ASCSTR "Death", 0
    tagline: .ASCSTR "Lay waste to your opponents", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.13
    sprite_big_palette: .dw loword(palettes.tarot_cards_death)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_temperance INSTANCEOF consumable_t VALUES
    name: .ASCSTR "Temperance", 0
    tagline: .ASCSTR "May you be pure in heart", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.14
    sprite_big_palette: .dw loword(palettes.tarot_cards1)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _tarot_temperance
.ENDST

.DSTRUCT Consumable.definitions.tarot_devil INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Devil", 0
    tagline: .ASCSTR "Revel in dark power", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.15
    sprite_big_palette: .dw loword(palettes.tarot_cards_devil)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_tower INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Tower", 0
    tagline: .ASCSTR "Destruction brings creation", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.16
    sprite_big_palette: .dw loword(palettes.tarot_cards_tower)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_star INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Stars", 0
    tagline: .ASCSTR "May you find what you desire", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.17
    sprite_big_palette: .dw loword(palettes.tarot_cards_star)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _tarot_star
.ENDST

.DSTRUCT Consumable.definitions.tarot_moon INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Moon", 0
    tagline: .ASCSTR "May you find what you lost", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.18
    sprite_big_palette: .dw loword(palettes.tarot_cards_moon)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _tarot_moon
.ENDST

.DSTRUCT Consumable.definitions.tarot_sun INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Sun", 0
    tagline: .ASCSTR "Bask in the healing light", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.19
    sprite_big_palette: .dw loword(palettes.tarot_cards1)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_judgement INSTANCEOF consumable_t VALUES
    name: .ASCSTR "Judgement", 0
    tagline: .ASCSTR "Judge lest ye be judged", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.20
    sprite_big_palette: .dw loword(palettes.tarot_cards1)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_world INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The World", 0
    tagline: .ASCSTR "May you find your way", 0
    sprite_big_ptr: .dl spritedata.tarot_cards_big.21
    sprite_big_palette: .dw loword(palettes.tarot_cards_world)
    sprite_entity_id: .dw 0
    sprite_entity_palette: .dw 0
    sprite_entity_palette_depth: .db 0
    on_use: .dw _empty_use
.ENDST

.REPT NUM_PILLS INDEX i
    .DSTRUCT Consumable.definitions.pill_{i} INSTANCEOF consumable_t VALUES
        name: .ASCSTR "Pill", 0
        tagline: .ASCSTR "Could be anything", 0
        sprite_big_ptr: .dl spritedata.pills_big.{i # 3}
        sprite_big_palette: .dw loword(palettes.pills.{i / 3})
        sprite_entity_id: .dw sprite.pills.{i # 3}
        sprite_entity_palette: .dw loword(palettes.pills.{i / 3})
        sprite_entity_palette_depth: .db 8
        on_use: .dw _pill_use
    .ENDST
.ENDR

Consumable.consumables:
    .dw Consumable.definitions.null
    .dw Consumable.definitions.tarot_fool
    .dw Consumable.definitions.tarot_magician
    .dw Consumable.definitions.tarot_high_priestess
    .dw Consumable.definitions.tarot_empress
    .dw Consumable.definitions.tarot_emperor
    .dw Consumable.definitions.tarot_hierophant
    .dw Consumable.definitions.tarot_lovers
    .dw Consumable.definitions.tarot_chariot
    .dw Consumable.definitions.tarot_strength
    .dw Consumable.definitions.tarot_hermit
    .dw Consumable.definitions.tarot_wheel_of_fortune
    .dw Consumable.definitions.tarot_justice
    .dw Consumable.definitions.tarot_hanged_man
    .dw Consumable.definitions.tarot_death
    .dw Consumable.definitions.tarot_temperance
    .dw Consumable.definitions.tarot_devil
    .dw Consumable.definitions.tarot_tower
    .dw Consumable.definitions.tarot_star
    .dw Consumable.definitions.tarot_moon
    .dw Consumable.definitions.tarot_sun
    .dw Consumable.definitions.tarot_judgement
    .dw Consumable.definitions.tarot_world
    .REPT NUM_PILLS INDEX i
        .dw Consumable.definitions.pill_{i}
    .ENDR
    .REPT 256 - CONSUMABLE_COUNT
        .dw Consumable.definitions.null
    .ENDR

; Teleport to room at location A
TeleportToRoom:
; TODO: better transition
    .SoftSetX 8
    .SoftSetA 8
    pha
    ; unload current room
    jsl Room_Unload
    jsl PlayerMinimapExitCurrentRoom
    .ForceSetAX 8, 8
    pla
    sta.b loadedRoomIndex
    tax
    lda #ROOM_LOAD_CONTEXT_TELEPORT
    pha
    lda.l mapTileSlotTable,X
    pha
    jsl LoadAndInitRoomSlotIntoLevel
    .ForceSetAX 16, 16
    pla
    jsl PlayerDiscoverNearbyRooms
    ; Find safe spot for player
    .ForceSetAX 8, 8
    lda.b [mapDoorSouth]
    beq +
        .ForceSetA 16
        lda #PLAYER_START_SOUTH_Y
        sta.w player_posy
        lda #PLAYER_START_SOUTH_X
        sta.w player_posx
        jmp @finish
        rtl
    +:
    lda.b [mapDoorNorth]
    beq +
        .ForceSetA 16
        lda #PLAYER_START_NORTH_Y
        sta.w player_posy
        lda #PLAYER_START_NORTH_X
        sta.w player_posx
        jmp @finish
        rtl
    +:
    lda.b [mapDoorEast]
    beq +
        .ForceSetA 16
        lda #PLAYER_START_EAST_X
        sta.w player_posx
        lda #PLAYER_START_EAST_Y
        sta.w player_posy
        jmp @finish
        rtl
    +:
    lda.b [mapDoorWest]
    beq +
        .ForceSetA 16
        lda #PLAYER_START_WEST_X
        sta.w player_posx
        lda #PLAYER_START_WEST_Y
        sta.w player_posy
        jmp @finish
        rtl
    +:
    ; failsafe: spawn at south
    .ForceSetA 16
    lda #PLAYER_START_SOUTH_Y
    sta.w player_posy
    lda #PLAYER_START_SOUTH_X
    sta.w player_posx
@finish:
    ; update x2,y2
    .ForceSetA 8
    lda.w player_box_x1
    clc
    adc #16
    sta.w player_box_x2
    lda.w player_box_y1
    clc
    adc #16
    sta.w player_box_y2
    ; update familiars to player position
    jsl Familiars.MoveFamiliarsToPlayer
    rtl

; Create entity 'A' near the player
CreateEntityNearPlayer:
; change context
    .ForceSetAX 16, 16
    .PushBank
    .ForceSetBank $7E
; save entity type for later
    .pha "reward_type"
; get entity spawn location
    .SetAX 8, 8
    lda.w player_box_x1
    clc
    adc #4
    .pha
    lda.w player_box_y1
    adc #4
    .pha
    .call "Room.GetPositionNear"
; create entity
    .SetAX 16, 16
    lda stk(reward_type),S
    .call "Entity.CreateAndInit"
; pull context
    .SetAX 16, 16
    pla
    .PullSoft 1
    .PullSoft 1
    .pla
    .PopBank
    rtl
.ASSERT D_STACKOFFS == 0

_tarot_fool:
    .ForceSetAX 8, 8
    lda.l roomslot_start
    jsl TeleportToRoom
_empty_use: ; put here to save 1 byte
    rts
_empty_text:
    .ASCSTR "null", 0

_tarot_star:
    .ForceSetAX 8, 8
    lda.l roomslot_star
    jsl TeleportToRoom
    rts

_tarot_moon:
    .ForceSetAX 8, 8
    lda.l roomslot_secret1
    jsl TeleportToRoom
    rts

_tarot_hermit:
    .ForceSetAX 8, 8
    lda.l roomslot_shop
    jsl TeleportToRoom
    rts

_tarot_emperor:
    .ForceSetAX 8, 8
    lda.l roomslot_boss
    jsl TeleportToRoom
    rts

_tarot_hierophant:
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_SOUL)
    jsl CreateEntityNearPlayer
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_SOUL)
    jsl CreateEntityNearPlayer
    rts

_tarot_lovers:
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_FULL)
    jsl CreateEntityNearPlayer
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_HEART_FULL)
    jsl CreateEntityNearPlayer
    rts

_tarot_justice:
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_COIN)
    jsl CreateEntityNearPlayer
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_HEART)
    jsl CreateEntityNearPlayer
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_BOMB)
    jsl CreateEntityNearPlayer
    rts

_tarot_temperance:
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_PILL)
    jsl CreateEntityNearPlayer
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_PILL)
    jsl CreateEntityNearPlayer
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_PILL)
    jsl CreateEntityNearPlayer
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_PILL)
    jsl CreateEntityNearPlayer
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_PILL)
    jsl CreateEntityNearPlayer
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_PILL)
    jsl CreateEntityNearPlayer
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_PILL)
    jsl CreateEntityNearPlayer
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_PILL)
    jsl CreateEntityNearPlayer
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_PILL)
    jsl CreateEntityNearPlayer
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_PILL)
    jsl CreateEntityNearPlayer
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_PILL)
    jsl CreateEntityNearPlayer
    .ForceSetAX 16, 16
    lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_PILL)
    jsl CreateEntityNearPlayer
    rts

; Set current consumable to 'A'
; May spawn a pickup if the player currently has a card in their inventory
Consumable.pickup:
    .ForceSetAX 8, 8
    pha
    ; drop current consumable, if applicable
    lda.w playerData.current_consumable
    beq @skip_drop
        .ForceSetAX 16, 16
        pei (entityExecutionContext)
        lda #ENTITY_CONTEXT_INIT_DROP
        sta.b entityExecutionContext
        lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_CONSUMABLE)
        .PushBank
        .SoftSetDirect $0000
        .ForceSetBank $7E
        .call "Entity.Create"
        .ForceSetAX 8, 8
        lda.w playerData.current_consumable
        sta.w entity_timer,Y
        .ForceSetAX 16, 16
        lda.w player_posx
        sta.w entity_posx,Y
        lda.w player_posy
        sta.w entity_posy,Y
        .call "Entity.Init"
        .ForceSetAX 16, 16
        .PopBank
        pla
        sta.b entityExecutionContext
@skip_drop:
    ; set current consumable
    .ForceSetAX 8, 8
    pla
    sta.w playerData.current_consumable

.InvalidateContext
Consumable.update_display:
    ; Get pointer to consumable
    .ForceSetAX 16, 16
    lda.w playerData.current_consumable
    and #$00FF
    asl
    tax
    lda.l Consumable.consumables,X
    tax
    phx
    ; decompress sprite
    ldy #tempTileData ; decompress into tempTileData; sprite is $200B/$800B
    lda.l bankaddr(Consumable.consumables) | consumable_t.sprite_big_ptr,X
    pha
    lda.l bankaddr(Consumable.consumables) | consumable_t.sprite_big_ptr+2,X
    and #$00FF
    ora #$7F00
    plx
    jsl Decompress.Lz4FromROM
    ; set up vqueue to upload sprite
    pea BG1_CHARACTER_BASE_ADDR + $0C00
    pea 4
    .ForceSetA 8
    lda #bankbyte(tempTileData)
    pha
    .ForceSetA 16
    pea loword(tempTileData)
    .REPT 4 INDEX i
        jsl CopySpriteVQueue
        .IF i < 3
            .ForceSetA 16
            lda $01,S
            clc
            adc #spritesize(4, 4)
            sta $01,S
            lda $06,S
            clc
            adc #$0100
            sta $06,S
        .ENDIF
    .ENDR
    .ForceSetA 16
    pla
    pla
    pla
    .ForceSetA 8
    pla
    ; upload palette
    .ForceSetAX 16, 16
    plx
    phx
    pea 32
    pea $7000 | bankbyte(palettes.palette0.w)
    lda.l bankaddr(Consumable.consumables) | consumable_t.sprite_big_palette,X
    pha
    jsl CopyPaletteVQueue
    .ForceSetAX 16, 16
    pla
    pla
    pla
    ; put text line
    lda.w playerData.current_consumable
    and #$00FF
    beq @no_put_text
        phb
        php
        jsl Overlay.clear
        plp
        .ChangeDataBank bankbyte(Consumable.consumables)
        lda $02,S
        clc
        adc #consumable_t.name
        tax
        jsl Overlay.putline
        .ForceSetAX 16, 16
        lda $02,S
        clc
        adc #consumable_t.tagline
        tax
        jsl Overlay.putline
        plb
@no_put_text:
    .ForceSetAX 16, 16
    plx
    rtl

; Update the consumable display without displaying an overlay message
Consumable.update_display_no_overlay:
    ; Get pointer to consumable
    .ForceSetAX 16, 16
    lda.w playerData.current_consumable
    and #$00FF
    asl
    tax
    lda.l Consumable.consumables,X
    tax
    phx
    ; decompress sprite
    ldy #tempTileData ; decompress into tempTileData; sprite is $200B/$800B
    lda.l bankaddr(Consumable.consumables) | consumable_t.sprite_big_ptr,X
    pha
    lda.l bankaddr(Consumable.consumables) | consumable_t.sprite_big_ptr+2,X
    and #$00FF
    ora #$7F00
    plx
    jsl Decompress.Lz4FromROM
    ; set up vqueue to upload sprite
    pea BG1_CHARACTER_BASE_ADDR + $0C00
    pea 4
    .ForceSetA 8
    lda #bankbyte(tempTileData)
    pha
    .ForceSetA 16
    pea loword(tempTileData)
    .REPT 4 INDEX i
        jsl CopySpriteVQueue
        .IF i < 3
            .ForceSetA 16
            lda $01,S
            clc
            adc #spritesize(4, 4)
            sta $01,S
            lda $06,S
            clc
            adc #$0100
            sta $06,S
        .ENDIF
    .ENDR
    .ForceSetA 16
    pla
    pla
    pla
    .ForceSetA 8
    pla
    ; upload palette
    .ForceSetAX 16, 16
    plx
    phx
    pea 32
    pea $7000 | bankbyte(palettes.palette0.w)
    lda.l bankaddr(Consumable.consumables) | consumable_t.sprite_big_palette,X
    pha
    jsl CopyPaletteVQueue
    .ForceSetAX 16, 16
    pla
    pla
    pla
@no_put_text:
    .ForceSetAX 16, 16
    plx
    rtl

Consumable.use:
    ; run
    .ForceSetAX 16, 16
    lda.w playerData.current_consumable
    and #$00FF
    beq @skip
    asl
    tax
    lda.l Consumable.consumables,X
    tax
    lda.l bankaddr(Consumable.consumables) | consumable_t.on_use,X
    sta.w $0000
    pea @next-1
    lda.w playerData.current_consumable
    and #$00FF
    jmp ($0000)
@next:
    ; set consumable to 0
    .ForceSetA 8
    lda #0
    sta.w playerData.current_consumable
    ; update display
    jml Consumable.update_display_no_overlay
@skip:
    rtl

; PILL FUNCTIONS

.DEFINE PILL_TEAR_ADD 3
.DEFINE PILL_TEAR_SUBTRACT 3
.DEFINE PILL_SPEED_ADD 3
.DEFINE PILL_SPEED_SUBTRACT 3
.DEFINE PILL_TEARSPEED_ADD $0020
.DEFINE PILL_TEARSPEED_SUBTRACT $0020
.DEFINE PILL_TEARLIFE_ADD 10
.DEFINE PILL_TEARLIFE_SUBTRACT 8

.DEFINE STK_TEXT $03

_pill_tears_up_text:
    .ASCSTR "Tears Up", 0
_pill_tears_up:
    .SoftSetAX 16, 16
    lda.w playerData.statadd_tears
    clc
    adc #PILL_TEAR_ADD
    sta.w playerData.statadd_tears
    lda #PLAYER_FLAG_INVALIDATE_ITEM_CACHE
    tsb.w playerData.flags
    rts

_pill_tears_down_text:
    .ASCSTR "Tears Down", 0
_pill_tears_down:
    .SoftSetAX 16, 16
    lda.w playerData.statadd_tears
    sec
    sbc #PILL_TEAR_SUBTRACT
    sta.w playerData.statadd_tears
    lda #PLAYER_FLAG_INVALIDATE_ITEM_CACHE
    tsb.w playerData.flags
    rts

_pill_speed_up_text:
    .ASCSTR "Speed Up", 0
_pill_speed_up:
    .SoftSetAX 16, 16
    lda.w playerData.statadd_accel
    clc
    adc #PILL_SPEED_ADD
    sta.w playerData.statadd_accel
    lda #PLAYER_FLAG_INVALIDATE_ITEM_CACHE
    tsb.w playerData.flags
    rts

_pill_speed_down_text:
    .ASCSTR "Speed Down", 0
_pill_speed_down:
    .SoftSetAX 16, 16
    lda.w playerData.statadd_accel
    sec
    sbc #PILL_SPEED_SUBTRACT
    sta.w playerData.statadd_accel
    lda #PLAYER_FLAG_INVALIDATE_ITEM_CACHE
    tsb.w playerData.flags
    rts

_pill_range_up_text:
    .ASCSTR "Range Up", 0
_pill_range_up:
    .SoftSetAX 16, 16
    lda.w playerData.statadd_tear_lifetime
    clc
    adc #PILL_TEARLIFE_ADD
    sta.w playerData.statadd_tear_lifetime
    lda #PLAYER_FLAG_INVALIDATE_ITEM_CACHE
    tsb.w playerData.flags
    rts

_pill_range_down_text:
    .ASCSTR "Range Down", 0
_pill_range_down:
    .SoftSetAX 16, 16
    lda.w playerData.statadd_tear_lifetime
    sec
    sbc #PILL_TEARLIFE_SUBTRACT
    sta.w playerData.statadd_tear_lifetime
    lda #PLAYER_FLAG_INVALIDATE_ITEM_CACHE
    tsb.w playerData.flags
    rts

_pill_shotspeed_up_text:
    .ASCSTR "Shot Speed Up", 0
_pill_shotspeed_up:
    .SoftSetAX 16, 16
    lda.w playerData.statadd_tear_speed
    clc
    adc #PILL_TEARSPEED_ADD
    sta.w playerData.statadd_tear_speed
    lda #PLAYER_FLAG_INVALIDATE_ITEM_CACHE
    tsb.w playerData.flags
    rts

_pill_shotspeed_down_text:
    .ASCSTR "Shot Speed Down", 0
_pill_shotspeed_down:
    .SoftSetAX 16, 16
    lda.w playerData.statadd_tear_speed
    sec
    sbc #PILL_TEARSPEED_SUBTRACT
    sta.w playerData.statadd_tear_speed
    lda #PLAYER_FLAG_INVALIDATE_ITEM_CACHE
    tsb.w playerData.flags
    rts

_pill_health_up_text:
    .ASCSTR "Health Up", 0
_pill_health_up:
    .SoftSetAX 16, 16
    lda #0
    jsl Player.health_up
    rts

_pill_health_down_text:
    .ASCSTR "Health Down", 0
_pill_health_down:
    .SoftSetAX 16, 16
    ; health down becomes health up when player has at most one red heart
    jsl Player.count_red_heart_slots
    .SoftSetAX 8, 8
    cmp #2
    bcs +
        ; player has 0 or 1 red hearts, add one instead
        lda #0
        jsl Player.health_up
        ; change text
        .ForceSetAX 16, 16
        lda #_pill_health_up_text
        sta STK_TEXT,S
        rts
    +:
    ; player has 2+ red hearts, remove one
    jsl Player.take_heart_container
    rts

_pill_full_heal_text:
    .ASCSTR "Full Health", 0
_pill_full_heal:
    .SoftSetAX 16, 16
    jsl Player.HealFull
    rts

_pill_hurt_text:
    .ASCSTR "Bad Trip", 0
_pill_hurt:
    .SoftSetAX 16, 16
    ; if first health slot is a half or empty red heart,
    ; or player's effective health is at most 2,
    ; then perform a full heal instead.
    lda.w playerData.healthSlots.0
    cmp #HEALTH_REDHEART_HALF
    beq @fullheal
    cmp #HEALTH_REDHEART_EMPTY
    beq @fullheal
    jsl Player.get_effective_health
    .SoftSetAX 8, 8
    cmp #3
    bcc @fullheal
    lda #2
    jsl Player.ForceTakeDamage
    rts
@fullheal:
    .ForceSetAX 16, 16
    lda #_pill_full_heal_text
    sta STK_TEXT,S
    jsl Player.HealFull
    rts

_pill_effect_table:
    .dw _pill_tears_up
    .dw _pill_tears_down
    .dw _pill_speed_up
    .dw _pill_speed_down
    .dw _pill_range_up
    .dw _pill_range_down
    .dw _pill_shotspeed_up
    .dw _pill_shotspeed_down
    .dw _pill_health_up
    .dw _pill_health_down
    .dw _pill_full_heal
    .dw _pill_hurt

_pill_name_table:
    .dw _pill_tears_up_text
    .dw _pill_tears_down_text
    .dw _pill_speed_up_text
    .dw _pill_speed_down_text
    .dw _pill_range_up_text
    .dw _pill_range_down_text
    .dw _pill_shotspeed_up_text
    .dw _pill_shotspeed_down_text
    .dw _pill_health_up_text
    .dw _pill_health_down_text
    .dw _pill_full_heal_text
    .dw _pill_hurt_text

.SoftSetAX 16, 16
_pill_use:
    sec
    sbc #PILLS_FIRST_ID
    asl
    tax
    lda.l _pill_name_table,X
    .pha
    jsr (_pill_effect_table,X)
    .ForceSetAX 16, 16
    .plx
    .PushBank
    phk
    plb
    jsl Overlay.putline
    .PopBank
    rts
.ClearContext

.ENDS