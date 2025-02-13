; HEALTH SLOT TYPES
.ENUMID 0
.ENUMID HEALTH_NULL
.ENUMID HEALTH_REDHEART_EMPTY
.ENUMID HEALTH_REDHEART_HALF
.ENUMID HEALTH_REDHEART_FULL
.ENUMID HEALTH_SOULHEART_HALF
.ENUMID HEALTH_SOULHEART_FULL
.ENUMID HEALTH_ETERNALHEART

; Maximum health slots
.DEFINE HEALTHSLOT_COUNT 16

; PLAYER FLAGS
.DEFINE PLAYER_FLAG_EYE $0001
.DEFINE PLAYER_FLAG_INVALIDATE_ITEM_CACHE $0002

; BASE STATS
.DEFINE PLAYER_STATBASE_ACCEL 24
.DEFINE PLAYER_STATBASE_SPEED (PLAYER_STATBASE_ACCEL * 16)
.DEFINE PLAYER_STATBASE_TEAR_RATE_INDEX 16
.DEFINE PLAYER_STATBASE_TEAR_RATE (($3C00 / 60) * 2.5)
.DEFINE PLAYER_STATBASE_TEAR_SPEED $0100 ; 1px/frame (60px/s)
.DEFINE PLAYER_STATBASE_DAMAGE 8
.DEFINE PLAYER_STATBASE_TEAR_LIFETIME 60

; PLAYER POSITION INFO
.DEFINE PLAYER_HITBOX_LEFT 4
.DEFINE PLAYER_HITBOX_RIGHT 12
.DEFINE PLAYER_HITBOX_TOP 5
.DEFINE PLAYER_HITBOX_BOTTOM 10

; Maximum player item count
.DEFINE PLAYER_MAX_ITEM_COUNT 255

; EXTRA NON-ENTITY PLAYER DATA
.STRUCT playerextdata_t
    flags dw
    invuln_timer dw
    tear_timer dw
    input_buffer dw
    active_body_frame db
    active_head_frame db
    body_flags db
    head_flags db
    walk_frame db
    walk_timer dw
    facingdir_head db
    facingdir_body db
    tearflags dw
    head_offset_y db
    anim_wait_timer db
    bomb_wait_timer db
; stats
    stat_speed dw
    stat_accel dw
    stat_tear_rate dw
    stat_tear_speed dw
    stat_tear_lifetime dw
    stat_damage dw
; pickups
    money dw
    keys dw
    bombs dw
    current_consumable db
; health
    ; extra slot allows small optimizations
    healthSlots INSTANCEOF byte_t HEALTHSLOT_COUNT + 1
; items
    ; Total number of items that the player has
    playerItemCount db
    ; List of all items that the player has, in order of collected
    playerItemList ds PLAYER_MAX_ITEM_COUNT
    ; Number of each individual item that the player owns.
    ; Allows for stat upgrades to stack
    playerItemStackNumber ds 256
.ENDST