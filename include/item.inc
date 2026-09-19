; ITEM IDS
.ENUMID 0
.ENUMID ITEMID_NULL
.ENUMID ITEMID_SAD_ONION
.ENUMID ITEMID_SPOON_BENDER
.ENUMID ITEMID_GROWTH_HORMONES
.ENUMID ITEMID_BROTHER_BOBBY
.ENUMID ITEMID_WIRE_COAT_HANGER
.ENUMID ITEMID_DINNER
.ENUMID ITEMID_CHOCOLATE_MILK
.ENUMID ITEMID_POLYPHEMUS
.ENUMID ITEMID_MAP
.ENUMID ITEMID_COMPASS
.ENUMID ITEMID_DECK_OF_CARDS
.ENUMID ITEMID_BRIMSTONE
.ENUMID ITEMID_PURSE
.ENUMID ITEM_COUNT

; ITEM FLAGS

; Indicates that an item is an active item
.DEFINE ITEMFLAG_ACTIVE $01
; Indicates that an item has double the heart cost in a devil deal
.DEFINE ITEMFLAG_COST_TWO_HEARTS $02
; Indicates that this item should not appear if the player already has it
.DEFINE ITEMFLAG_NONSTACKING $04

; ITEM DEFINITION
.STRUCT itemdef_t
    ; which item sprite to use
    sprite_index db
    ; which palette to use
    palette_ptr dw
    ; how many colors the palette uses
    palette_depth db
    ; item flags
    flags db
    ; subroutine to call when this item is picked up
    on_pickup dw
    ; subroutine to call when this (active) item is used
    on_use dw
    ; how much this item costs (decimal)
    shop_price db
    ; how much charge this (active) item can store
    charge_max db
    ; how much charge this (active) item requires to use
    charge_use db
    ; how much charge this (active) item starts out with
    charge_init db
    ; the name of this item
    name ds 32
    ; the tagline for this item
    tagline ds 32
.ENDST
