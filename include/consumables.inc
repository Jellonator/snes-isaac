.ENUMID 0
.ENUMID CONSUMABLE_NULL
.ENUMID CONSUMABLE_TAROT_FOOL
.ENUMID CONSUMABLE_TAROT_MAGICIAN
.ENUMID CONSUMABLE_TAROT_HIGH_PRIESTESS
.ENUMID CONSUMABLE_TAROT_EMPRESS
.ENUMID CONSUMABLE_TAROT_EMPEROR
.ENUMID CONSUMABLE_TAROT_HIEROPHANT
.ENUMID CONSUMABLE_TAROT_LOVERS
.ENUMID CONSUMABLE_TAROT_CHARIOT
.ENUMID CONSUMABLE_TAROT_STRENGTH
.ENUMID CONSUMABLE_TAROT_HERMIT
.ENUMID CONSUMABLE_TAROT_WHEEL_OF_FORTUNE
.ENUMID CONSUMABLE_TAROT_JUSTICE
.ENUMID CONSUMABLE_TAROT_HANGED_MAN
.ENUMID CONSUMABLE_TAROT_DEATH
.ENUMID CONSUMABLE_TAROT_TEMPERANCE
.ENUMID CONSUMABLE_TAROT_DEVIL
.ENUMID CONSUMABLE_TAROT_TOWER
.ENUMID CONSUMABLE_TAROT_STAR
.ENUMID CONSUMABLE_TAROT_MOON
.ENUMID CONSUMABLE_TAROT_SUN
.ENUMID CONSUMABLE_TAROT_JUDGEMENT
.ENUMID CONSUMABLE_TAROT_WORLD
.ENUMID CONSUMABLE_COUNT

.DEFINE CONSUMABLEID_TAROT_FIRST CONSUMABLE_TAROT_FOOL
.DEFINE CONSUMABLEID_TAROT_LAST CONSUMABLE_TAROT_WORLD

.STRUCT consumable_t
    ; 28 chars + null
    name ds 29
    tagline ds 29
    sprite_ptr dl
    sprite_palette dw
    on_use dl
.ENDST