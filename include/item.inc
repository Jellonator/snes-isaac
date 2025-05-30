; ITEMS
.DEFINE ITEMID_NULL 0
.DEFINE ITEMID_SAD_ONION 1
.DEFINE ITEMID_SPOON_BENDER 2
.DEFINE ITEMID_GROWTH_HORMONES 3
.DEFINE ITEMID_BROTHER_BOBBY 4
.DEFINE ITEMID_WIRE_COAT_HANGER 5
.DEFINE ITEMID_DINNER 6
.DEFINE ITEMID_CHOCOLATE_MILK 7
.DEFINE ITEMID_POLYPHEMUS 8
.DEFINE ITEMID_MAP 9
.DEFINE ITEMID_COMPASS 10
.DEFINE ITEMID_DECK_OF_CARDS 11
.DEFINE ITEMID_BRIMSTONE 12
.DEFINE ITEM_COUNT 13

; ITEM FLAGS

; Indicates that an item is an active item
.DEFINE ITEMFLAG_ACTIVE $01
; Indicates that an item has double the heart cost in a devil deal
.DEFINE ITEMFLAG_COST_TWO_HEARTS $02

; ITEM DEFINITION
.STRUCT itemdef_t
    sprite_index db
    palette_ptr dw
    palette_depth db
    flags db
    on_pickup dw
    on_use dw
    shop_price db
    charge_max db
    charge_use db
    charge_init db
    name ds 32
    tagline ds 32
.ENDST