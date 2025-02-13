.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "Pathing" FREE

.FUNCTION tarot_sprite(i) spritedata.tarot_cards_big + spriteoffs(4, 16, i)

.DSTRUCT Consumable.definitions.null INSTANCEOF consumable_t VALUES
    name: .db "null", 0
    tagline: .db "May you find a real consumable", 0
    sprite_ptr: .dl 0
    sprite_palette: .dw 0
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_fool INSTANCEOF consumable_t VALUES
    name: .db "The Fool", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(0)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_magician INSTANCEOF consumable_t VALUES
    name: .db "The Magician", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(1)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_high_priestess INSTANCEOF consumable_t VALUES
    name: .db "The High priestess", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(2)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_empress INSTANCEOF consumable_t VALUES
    name: .db "The Empress", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(3)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_emporer INSTANCEOF consumable_t VALUES
    name: .db "The Emporer", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(4)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_hierophant INSTANCEOF consumable_t VALUES
    name: .db "The Hierophant", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(5)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_lovers INSTANCEOF consumable_t VALUES
    name: .db "The Lovers", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(6)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_chariot INSTANCEOF consumable_t VALUES
    name: .db "The Chariot", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(7)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_strength INSTANCEOF consumable_t VALUES
    name: .db "Strength", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(8)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_hermit INSTANCEOF consumable_t VALUES
    name: .db "The Hermit", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(0)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_wheel_of_fortune INSTANCEOF consumable_t VALUES
    name: .db "Wheel of Fortune", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(10)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_justice INSTANCEOF consumable_t VALUES
    name: .db "Justice", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(11)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_hanged_man INSTANCEOF consumable_t VALUES
    name: .db "The Hanged Man", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(12)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_death INSTANCEOF consumable_t VALUES
    name: .db "Death", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(13)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_temperance INSTANCEOF consumable_t VALUES
    name: .db "Temperance", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(14)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_devil INSTANCEOF consumable_t VALUES
    name: .db "The Devil", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(15)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_tower INSTANCEOF consumable_t VALUES
    name: .db "The Tower", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(16)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_star INSTANCEOF consumable_t VALUES
    name: .db "The Star", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(17)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_moon INSTANCEOF consumable_t VALUES
    name: .db "The Moon", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(18)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_sun INSTANCEOF consumable_t VALUES
    name: .db "The Sun", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(19)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_judgement INSTANCEOF consumable_t VALUES
    name: .db "Judgement", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(20)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

.DSTRUCT Consumable.definitions.tarot_world INSTANCEOF consumable_t VALUES
    name: .db "The World", 0
    tagline: .db "TODO", 0
    sprite_ptr: .dl tarot_sprite(21)
    sprite_palette: .dw loword(palettes.tarot_cards1)
    on_use: .dl _empty_use
.ENDST

Consumable.consumables:
    .dw Consumable.definitions.null
    .dw Consumable.definitions.tarot_fool
    .dw Consumable.definitions.tarot_magician
    .dw Consumable.definitions.tarot_high_priestess
    .dw Consumable.definitions.tarot_empress
    .dw Consumable.definitions.tarot_emporer
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
    rtl

Consumable.pickup:
    sep #$30
    pha
    ; drop current consumable, if applicable
    lda.w playerData.current_consumable
    beq @skip_drop
        rep #$30
        lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_CONSUMABLE)
        jsl entity_create
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
    rtl

.ENDS