.FUNCTION MAP_DOOR_MEM_LOC(i) (mapDoorNorth + (i * 3))

.REPT 4 INDEX i
    .define entity_custom.{i+1} ($7E0000 | (private_entity_custom.{i+1}-2))
.ENDR

.REPT 16 INDEX i
    .define entity_char_custom.{i+1} ($7E0000 | (private_entity_char_custom.{i+1}-2))
.ENDR

.define entity_type (private_base_entity_combined_type_variant - 2)
.define entity_variant (private_base_entity_combined_type_variant - 1)
.define entity_state (private_base_entity_combined_state_timer - 2)
.define entity_timer (private_base_entity_combined_state_timer - 1)
.define entity_health (private_base_entity_health - 2)
.define entity_posx (private_base_entity_posx - 2)
.define entity_posy (private_base_entity_posy - 2)
.define entity_velocx (private_base_entity_velocx - 2)
.define entity_velocy (private_base_entity_velocy - 2)
.define entity_box_x1 (entity_posx + 1)
.define entity_box_y1 (entity_posy + 1)
.define entity_box_x2 (private_base_entity_combined_box_x2y2 - 2)
.define entity_box_y2 (private_base_entity_combined_box_x2y2 - 1)
.define entity_mask (private_base_entity_combined_mask_signal - 2)
.define entity_signal (private_base_entity_combined_mask_signal - 1)
.define entity_ysort ($7E0000 | (private_base_entity_combined_ysort_flash - 2))
.define entity_damageflash ($7E0000 | (private_base_entity_combined_ysort_flash - 1))

.define player_posx (ENTITY_INDEX_PLAYER + entity_posx)
.define player_posy (ENTITY_INDEX_PLAYER + entity_posy)
.define player_velocx (ENTITY_INDEX_PLAYER + entity_velocx)
.define player_velocy (ENTITY_INDEX_PLAYER + entity_velocy)
.define player_box_x1 (ENTITY_INDEX_PLAYER + entity_box_x1)
.define player_box_x2 (ENTITY_INDEX_PLAYER + entity_box_x2)
.define player_box_y1 (ENTITY_INDEX_PLAYER + entity_box_y1)
.define player_box_y2 (ENTITY_INDEX_PLAYER + entity_box_y2)
.define player_mask (ENTITY_INDEX_PLAYER + entity_mask)
.define player_signal (ENTITY_INDEX_PLAYER + entity_signal)
.define player_type (ENTITY_INDEX_PLAYER + entity_type)
.define player_damageflag (ENTITY_INDEX_PLAYER + entity_health)

; projectile data
.define projectile_size entity_custom.1
.define projectile_type entity_variant ; repurposed variant
.define projectile_lifetime entity_health ; repurposed health
.define projectile_flags entity_custom.2
.define projectile_height entity_custom.3
.define projectile_velocz entity_custom.4
.define projectile_damage (private_base_entity_combined_state_timer - 2)

; pathfinding data
; we offset by $10 to prevent extra cycles from page wraps in pathfinding code
.DEFINE pathfind_player_data $001B20
.DEFINE pathfind_enemy_data $001C20

; data buffers
.DEFINE tempData_7E $7EFF00

.DEFINE currentRoomInfoAddress currentRoomTileTypeTableAddress