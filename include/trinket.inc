; TRINKET DEFINITION
.STRUCT trinketdef_t
    sprite_index db
    palette_ptr dw
    palette_depth db
    flags db
    on_pickup dw
    name ds 32
    tagline ds 32
.ENDST

; TRINKET VARIANTS
.ENUMID 0
.ENUMID TRINKET_NULL
.ENUMID TRINKET_PENNY_ON_A_STRING
.ENUMID TRINKET_ROLLER_SKATES
.ENUMID TRINKET_FISH_HEAD
.ENUMID TRINKET_COUNT

.MACRO .PlayerHasTrinketEffect ARGS trinket
    ; check bit: playerData.trinketeffects[trinket // 8] &  (1 << (trinket % 8))
    lda.w playerData.trinketeffects + floor(trinket / 8)
    and #(1 << (trinket # 8))
.ENDM