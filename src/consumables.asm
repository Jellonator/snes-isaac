.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "Pathing" FREE

.DSTRUCT Consumable.definitions.null INSTANCEOF consumable_t VALUES
    name: .ASCSTR "null", 0
    tagline: .ASCSTR "May you find a real card", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.22
    sprite_palette: .dw 0
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_fool INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Fool", 0
    tagline: .ASCSTR "Where journey begins", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.0
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _tarot_fool
.ENDST

.DSTRUCT Consumable.definitions.tarot_magician INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Magician", 0
    tagline: .ASCSTR "May you never miss your goal", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.1
    sprite_palette: .dw loword(palettes.tarot_cards_magician)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_high_priestess INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The High priestess", 0
    tagline: .ASCSTR "Mother is watching you", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.2
    sprite_palette: .dw loword(palettes.tarot_cards_high_priestess)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_empress INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Empress", 0
    tagline: .ASCSTR "May your rage bring power", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.3
    sprite_palette: .dw loword(palettes.tarot_cards_empress)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_emperor INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Emperor", 0
    tagline: .ASCSTR "Challenge me!", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.4
    sprite_palette: .dw loword(palettes.tarot_cards_emperor)
    on_use: .dl _tarot_emperor
.ENDST

.DSTRUCT Consumable.definitions.tarot_hierophant INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Hierophant", 0
    tagline: .ASCSTR "Two prayers for the lost", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.5
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_lovers INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Lovers", 0
    tagline: .ASCSTR "May you prosper", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.6
    sprite_palette: .dw loword(palettes.tarot_cards_lovers)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_chariot INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Chariot", 0
    tagline: .ASCSTR "May nothing stand before you", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.7
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_strength INSTANCEOF consumable_t VALUES
    name: .ASCSTR "Strength", 0
    tagline: .ASCSTR "May your power bring rage", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.8
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_hermit INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Hermit", 0
    tagline: .ASCSTR "May you find solace", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.9
    sprite_palette: .dw loword(palettes.tarot_cards_hermit)
    on_use: .dl _tarot_hermit
.ENDST

.DSTRUCT Consumable.definitions.tarot_wheel_of_fortune INSTANCEOF consumable_t VALUES
    name: .ASCSTR "Wheel of Fortune", 0
    tagline: .ASCSTR "Spin the wheel of destiny", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.10
    sprite_palette: .dw loword(palettes.tarot_cards_wheel_of_fortune)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_justice INSTANCEOF consumable_t VALUES
    name: .ASCSTR "Justice", 0
    tagline: .ASCSTR "May your future be balanced", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.11
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_hanged_man INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Hanged Man", 0
    tagline: .ASCSTR "May you find enlightenment", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.12
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_death INSTANCEOF consumable_t VALUES
    name: .ASCSTR "Death", 0
    tagline: .ASCSTR "Lay waste to your opponents", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.13
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_temperance INSTANCEOF consumable_t VALUES
    name: .ASCSTR "Temperance", 0
    tagline: .ASCSTR "May you be pure in heart", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.14
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_devil INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Devil", 0
    tagline: .ASCSTR "Revel in dark power", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.15
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_tower INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Tower", 0
    tagline: .ASCSTR "Destruction brings creation", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.16
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_star INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Stars", 0
    tagline: .ASCSTR "May you find what you desire", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.17
    sprite_palette: .dw loword(palettes.tarot_cards_star)
    on_use: .dl _tarot_star
.ENDST

.DSTRUCT Consumable.definitions.tarot_moon INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Moon", 0
    tagline: .ASCSTR "May you find what you lost", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.18
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _tarot_moon
.ENDST

.DSTRUCT Consumable.definitions.tarot_sun INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The Sun", 0
    tagline: .ASCSTR "Bask in the healing light", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.19
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_judgement INSTANCEOF consumable_t VALUES
    name: .ASCSTR "Judgement", 0
    tagline: .ASCSTR "Judge lest ye be judged", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.20
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_world INSTANCEOF consumable_t VALUES
    name: .ASCSTR "The World", 0
    tagline: .ASCSTR "May you find your way", 0
    sprite_ptr: .dl spritedata.tarot_cards_big.21
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

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
    .REPT 256-23
        .dw Consumable.definitions.null
    .ENDR

_empty_use:
    rts

; Teleport to room at location A
TeleportToRoom:
; TODO: better transition
    .INDEX 8
    .ACCU 8
    pha
    ; unload current room
    jsl Room_Unload
    jsl PlayerMinimapExitCurrentRoom
    sep #$30
    pla
    sta.b loadedRoomIndex
    tax
    lda #ROOM_LOAD_CONTEXT_TELEPORT
    pha
    lda.l mapTileSlotTable,X
    pha
    jsl LoadAndInitRoomSlotIntoLevel
    rep #$30
    pla
    jsl PlayerDiscoverNearbyRooms
    ; Find safe spot for player
    sep #$30
    lda.b [mapDoorSouth]
    beq +
        rep #$20
        lda #PLAYER_START_SOUTH_Y
        sta.w player_posy
        lda #PLAYER_START_SOUTH_X
        sta.w player_posx
        jmp @finish
        rtl
    +:
    lda.b [mapDoorNorth]
    beq +
        rep #$20
        lda #PLAYER_START_NORTH_Y
        sta.w player_posy
        lda #PLAYER_START_NORTH_X
        sta.w player_posx
        jmp @finish
        rtl
    +:
    lda.b [mapDoorEast]
    beq +
        rep #$20
        lda #PLAYER_START_EAST_X
        sta.w player_posx
        lda #PLAYER_START_EAST_Y
        sta.w player_posy
        jmp @finish
        rtl
    +:
    lda.b [mapDoorWest]
    beq +
        rep #$20
        lda #PLAYER_START_WEST_X
        sta.w player_posx
        lda #PLAYER_START_WEST_Y
        sta.w player_posy
        jmp @finish
        rtl
    +:
    ; failsafe: spawn at south
    rep #$20
    lda #PLAYER_START_SOUTH_Y
    sta.w player_posy
    lda #PLAYER_START_SOUTH_X
    sta.w player_posx
@finish:
    ; update x2,y2
    sep #$20
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

_tarot_fool:
    sep #$30
    lda.l roomslot_start
    jsl TeleportToRoom
    rts

_tarot_star:
    sep #$30
    lda.l roomslot_star
    jsl TeleportToRoom
    rts

_tarot_moon:
    sep #$30
    lda.l roomslot_secret1
    jsl TeleportToRoom
    rts

_tarot_hermit:
    sep #$30
    lda.l roomslot_shop
    jsl TeleportToRoom
    rts

_tarot_emperor:
    sep #$30
    lda.l roomslot_boss
    jsl TeleportToRoom
    rts

; Set current consumable to 'A'
; May spawn a pickup if the player currently has a card in their inventory
Consumable.pickup:
    sep #$30
    pha
    ; drop current consumable, if applicable
    lda.w playerData.current_consumable
    beq @skip_drop
        rep #$30
        lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_CONSUMABLE)
        jsl entity_create_and_init
        sep #$30
        lda.w playerData.current_consumable
        sta.w entity_timer,Y
        rep #$30
        lda.w player_posx
        sta.w entity_posx,Y
        lda.w player_posy
        sta.w entity_posy,Y
@skip_drop:
    ; set current consumable
    sep #$30
    pla
    sta.w playerData.current_consumable
Consumable.update_display:
    ; Get pointer to consumable
    rep #$30
    lda.w playerData.current_consumable
    and #$00FF
    asl
    tax
    lda.l Consumable.consumables,X
    tax
    phx
    ; decompress sprite
    ldy #tempTileData ; decompress into tempTileData; sprite is $200B/$800B
    lda.l bankaddr(Consumable.consumables) | consumable_t.sprite_ptr,X
    pha
    lda.l bankaddr(Consumable.consumables) | consumable_t.sprite_ptr+2,X
    and #$00FF
    ora #$7F00
    plx
    jsl Decompress.Lz4FromROM
    ; set up vqueue to upload sprite
    pea BG1_CHARACTER_BASE_ADDR + $0C00
    pea 4
    sep #$20
    lda #bankbyte(tempTileData)
    pha
    rep #$20
    pea loword(tempTileData)
    .REPT 4 INDEX i
        jsl CopySpriteVQueue
        .IF i < 3
            rep #$20
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
    rep #$20
    pla
    pla
    pla
    sep #$20
    pla
    ; upload palette
    rep #$30
    plx
    phx
    pea 32
    pea $7000 | bankbyte(palettes.palette0.w)
    lda.l bankaddr(Consumable.consumables) | consumable_t.sprite_palette,X
    pha
    jsl CopyPaletteVQueue
    rep #$30
    pla
    pla
    pla
    ; put text line
    lda.w playerData.current_consumable
    and #$00FF
    beq @no_put_text
        phb
        .ChangeDataBank bankbyte(Consumable.consumables)
        lda $02,S
        clc
        adc #consumable_t.name
        tax
        jsl Overlay.putline
        rep #$30
        lda $02,S
        clc
        adc #consumable_t.tagline
        tax
        jsl Overlay.putline
        plb
@no_put_text:
    rep #$30
    plx
    rtl

; Update the consumable display without displaying an overlay message
Consumable.update_display_no_overlay:
    ; Get pointer to consumable
    rep #$30
    lda.w playerData.current_consumable
    and #$00FF
    asl
    tax
    lda.l Consumable.consumables,X
    tax
    phx
    ; decompress sprite
    ldy #tempTileData ; decompress into tempTileData; sprite is $200B/$800B
    lda.l bankaddr(Consumable.consumables) | consumable_t.sprite_ptr,X
    pha
    lda.l bankaddr(Consumable.consumables) | consumable_t.sprite_ptr+2,X
    and #$00FF
    ora #$7F00
    plx
    jsl Decompress.Lz4FromROM
    ; set up vqueue to upload sprite
    pea BG1_CHARACTER_BASE_ADDR + $0C00
    pea 4
    sep #$20
    lda #bankbyte(tempTileData)
    pha
    rep #$20
    pea loword(tempTileData)
    .REPT 4 INDEX i
        jsl CopySpriteVQueue
        .IF i < 3
            rep #$20
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
    rep #$20
    pla
    pla
    pla
    sep #$20
    pla
    ; upload palette
    rep #$30
    plx
    phx
    pea 32
    pea $7000 | bankbyte(palettes.palette0.w)
    lda.l bankaddr(Consumable.consumables) | consumable_t.sprite_palette,X
    pha
    jsl CopyPaletteVQueue
    rep #$30
    pla
    pla
    pla
@no_put_text:
    rep #$30
    plx
    rtl

Consumable.use:
    ; run
    rep #$30
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
    jmp ($0000)
@next:
    ; set consumable to 0
    sep #$20
    lda #0
    sta.w playerData.current_consumable
    ; update display
    jml Consumable.update_display_no_overlay
@skip:
    rtl

.ENDS