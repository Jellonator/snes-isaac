.STRUCT savestate_room_t
    roomtype db
    rng INSTANCEOF rng_t
    definition dw
    ; map data
    maptile_pos INSTANCEOF maptilepos_t
    maptile_type db
    maptile_flags db
    ; door data
    door_south db
    door_east db
    tiles ds ROOM_TILE_COUNT
.ENDST

.STRUCT savestate_entity_t
    type db
    variant db
    ; Combines a few values into %rrrrXXXX XXYYYYYY
    ; X: x-coordinate (snapped to 4px)
    ; Y: y-coordinate (snapped to 4px)
    ; r: room offset. If 0, then this entity is in the same room as the
    ; previously serialized entity.
    ; if `type` and `r` are both zero, then end deserialization.
    combined_roomoffs_position_term dw
    state db
    timer db
.ENDST

.DEFINE SAVESTATE_STATE_IN_USE 1
.DEFINE SAVESTATE_STATE_EMPTY 0

; 32 rooms 16 entities each
.DEFINE SAVE_ENTITY_LIMIT 512

.STRUCT savestate_t
    state db
    ; RNG
    seed_game INSTANCEOF rng_t
    seed_game_stored INSTANCEOF rng_t
    seed_stage INSTANCEOF rng_t
    ; player data
    player_money db
    player_bombs db
    player_keys db
    player_health ds HEALTHSLOT_COUNT
    player_consumable db
    player_active_item db
    player_active_charge db
    player_item_count db
    player_item_list ds 256
    player_posx db
    player_posy db
    ; devil deal info
    floors_since_devil_deal db
    devil_deal_flags db
    ; active room data
    room_current_slot db
    floor_current_index dw
    ; room data
    num_rooms db
    rooms INSTANCEOF savestate_room_t MAX_MAP_SLOTS
    ; room locations
    roomslot_star db
    roomslot_boss db
    roomslot_start db
    roomslot_shop db
    roomslot_secret1 db
    roomslot_secret2 db
    ; entity data
    entities INSTANCEOF savestate_entity_t SAVE_ENTITY_LIMIT
.ENDST

.DEFINE SAVESLOT_STATE_IN_USE 1
.DEFINE SAVESLOT_STATE_EMPTY 0

.STRUCT saveslot_t
    state db
.ENDST