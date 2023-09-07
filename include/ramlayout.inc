.FUNCTION MAP_DOOR_MEM_LOC(i) (mapDoorNorth + (i * 3))

.REPT 4 INDEX i
    .define entity_custom.{i+1} private_entity_custom.{i+1}-2
.ENDR

.REPT 16 INDEX i
    .define entity_char_custom.{i+1} private_entity_char_custom.{i+1} - 2
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
.define entity_ysort (private_entity_ysort_order - 2)

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
.define projectile_size private_entity_custom.1 - 2
.define projectile_type entity_variant ; repurposed variant
.define projectile_lifetime entity_health ; repurposed health
.define projectile_flags private_entity_custom.2 - 2
.define projectile_height private_entity_custom.3 - 2
.define projectile_velocz private_entity_custom.4 - 2

.DEFINE tempData $7EFF00
