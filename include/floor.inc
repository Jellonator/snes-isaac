; CHAPTERS
.ENUMID 0
.ENUMID CHAPTER_BASEMENT

; FLOORS
.ENUMID 0
.ENUMID FLOOR_BASEMENT_I
.ENUMID FLOOR_BASEMENT_II

.DEFINE FLOOR_DEFINITION_BASE $C10000

; ROOMGEN CHAPTER DEFINITION
; defines a 'chapter' - includes palette, tileset, room pools, etc.
.STRUCT chapterdefinition_t
    name ds 32
    palettes dsl 4
    tiledata dl
    ground dl
    groundPalette dw
.ENDST

; ROOMGEN FLOOR

; Roomgen endroom inclusions
.DEFINE ROOMGEN_ITEM $01   ; Floor includes an item room
.DEFINE ROOMGEN_SHOP $02   ; Floor includes a shop
.DEFINE ROOMGEN_BOSS $04   ; Floor includes a boss
.DEFINE ROOMGEN_SECRET $08 ; Floor includes a secret room

; Default roomgen
.DEFINE ROOMGEN_DEFAULT (ROOMGEN_ITEM | ROOMGEN_SHOP | ROOMGEN_BOSS | ROOMGEN_SECRET)

; ROOMGEN FLOOR DEFINITION
; defines a 'floor'
.STRUCT floordefinition_t
    name ds 32
    chapter db
    size db
    roomgen dw
.ENDST

; FLOOR FLAGS (runtime)

.DEFINE FLOOR_FLAG_NEXT $01
.DEFINE FLOOR_FLAG_FADEIN $02
.DEFINE FLOOR_FLAG_FADEIN2 $04