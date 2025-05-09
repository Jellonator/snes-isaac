.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "RoomCode" FREE

; Spawn entities for room
; Args:
;   spawngroup [db] $03
_room_spawn_entities:
; spawn entities
    rep #$30 ; 16B AXY
    lda #ENTITY_SPAWN_CONTEXT_ROOMSPAWN
    sta.b entitySpawnContext
    lda.b currentRoomDefinition
    tax
    lda.l $C20000 + roomdefinition_t.numObjects,X
    and #$00FF
    tay ; Y = num entities
    beq @end
    txa
    clc
    adc #_sizeof_roomdefinition_t
    tax
@loop:
    ; Get and create entity
    phy ; >2
    phx ; >2
    lda $C20000 + objectdef_t.objectType,X
    and #$00FF
    ; .MultiplyStatic 2
    tax
    sep #$20
    lda.l EntityDef_SpawnGroup,X
    cmp $03 + 4,S
    rep #$20
    bcc @no_spawn
        plx ; <2
        lda.l $C20000 + objectdef_t.objectType,X
        phx ; >2
        jsl entity_create
        rep #$30
        plx ; <2
        ; clear some base info
        lda #0
        sta.w entity_posx,Y
        sta.w entity_posy,Y
        ; set X,Y
        sep #$20 ; 8B A
        lda $C20000 + objectdef_t.x,X ; X coord
        clc
        adc #ROOM_LEFT
        sta.w entity_posx+1,Y
        lda $C20000 + objectdef_t.y,X ; Y coord
        clc
        adc #ROOM_TOP
        sta.w entity_posy+1,Y
        rep #$30
        phx ; >2
        jsl entity_init
        rep #$30
    @no_spawn:
    plx ; <2
    ply ; <2
    dey
    beq @end
    inx
    inx
    inx
    inx
    bra @loop
@end:
; deserialize entities
    lda #ENTITY_SPAWN_CONTEXT_DESERIALIZE
    sta.b entitySpawnContext
    stz.b $30
    @loop_deserialize:
        lda.b $30
        cmp #ENTITY_STORE_COUNT
        beq @end_deserialize
        asl
        sta.b $32
        asl
        clc
        adc.b $32
        clc
        adc currentRoomInfoAddress
        tax
        lda.l $7E0000 + roominfo_t.entityStoreTable + entitystore_t.type,X
        and #$00FF
        beq @end_deserialize
        lda.l $7E0000 + roominfo_t.entityStoreTable + entitystore_t.type,X
        ; create entity
        phx
        php
        jsl entity_create
        plp
        plx
        lda.l $7E0000 + roominfo_t.entityStoreTable + entitystore_t.posx-1,X
        sta.w entity_posx,Y
        lda.l $7E0000 + roominfo_t.entityStoreTable + entitystore_t.posy-1,X
        sta.w entity_posy,Y
        lda.l $7E0000 + roominfo_t.entityStoreTable + entitystore_t.state,X
        sta.w entity_state,Y ; entity_state and entity_timer are combined
        phx
        php
        jsl entity_init
        plp
        plx
        inc.b $30
        jmp @loop_deserialize
@end_deserialize:
    lda #ENTITY_SPAWN_CONTEXT_STANDARD
    sta.b entitySpawnContext
    rts

Room_Init:
    sep #$30
    stz.w currentRoomEnemyCount
; create entities
    ldx.b loadedRoomIndex
    lda.w mapTileFlagsTable,X
    bit #MAPTILE_EXPLORED
    bne @room_is_explored
        ; not explored:
        ; (also: set explored flag)
        ora #MAPTILE_EXPLORED
        sta.w mapTileFlagsTable,X
        lda #ENTITY_SPAWNGROUP_ONCE
        bra @spawn_ents
    @room_is_explored:
    bit #MAPTILE_COMPLETED
    bne @room_is_completed
        ; not completed:
        lda #ENTITY_SPAWNGROUP_ENEMY
        bra @spawn_ents
    @room_is_completed:
        ; completed
        lda #ENTITY_SPAWNGROUP_ALWAYS
    @spawn_ents:
    ; sep #$20
    pha
    jsr _room_spawn_entities
    sep #$30
    stz.w currentRoomDoSpawnReward
    rep #$20
    lda.w currentRoomEnemyCount
    beq +
        sep #$30
        lda #1
        sta.w currentRoomDoSpawnReward
    +:
    sep #$30
    pla
; close doors if there are enemies in the room, and the room isn't marked as completed
; otherwise, mark room as completed
    ldx.b loadedRoomIndex
    lda.w mapTileFlagsTable,X
    bit #MAPTILE_COMPLETED
    bne @skip_close_doors
    lda.w currentRoomEnemyCount
    beq @skip_close_doors
        ; close opened doors
        jsr _Room_Close_Doors
        bra @finish_close_doors
@skip_close_doors:
        ; open doors, and mark as completed
        ldx.b loadedRoomIndex
        lda.w mapTileFlagsTable,X
        ora #MAPTILE_COMPLETED
        jsr _Room_Open_Doors
@finish_close_doors:
    php
    jsl updateAllDoorsInRoom
    ; pee splat if player is on low health
    jsl Player.get_effective_health
    sep #$20
    cmp #1
    bne +
        lda.w player_box_x1
        sec
        sbc #3
        sta.b $07
        lda.w player_box_y1
        sta.b $06
        jsl Splat.peesplat
        lda.w player_box_x1
        clc
        adc #3
        sta.b $07
        lda.w player_box_y1
        inc A
        sta.b $06
        jsl Splat.peesplat
    +:
    plp
    rtl

_Room_Open_Doors:
    sep #$30
    .REPT 4 INDEX i
        lda.b [MAP_DOOR_MEM_LOC(i)]
        and #DOOR_MASK_OPEN_METHOD
        cmp #DOOR_METHOD_FINISH_ROOM
        bne +
            lda.b [MAP_DOOR_MEM_LOC(i)]
            ora #DOOR_OPEN
            sta.b [MAP_DOOR_MEM_LOC(i)]
        +:
    .ENDR
    rts

_Room_Close_Doors:
    sep #$30
    .REPT 4 INDEX i
        lda.b [MAP_DOOR_MEM_LOC(i)]
        and #DOOR_MASK_IS_CLOSED
        cmp #DOOR_OPEN
        bne +
            lda.b [MAP_DOOR_MEM_LOC(i)]
            and #DOOR_MASK_TYPE
            ora #DOOR_CLOSED | DOOR_METHOD_FINISH_ROOM
            sta.b [MAP_DOOR_MEM_LOC(i)]
        +:
    .ENDR
    rts

_Room_Spawn_Reward:
    rep #$30
    jsl RoomRand_Update8
    and #$00FF
    asl
    tax
    lda.l PickupTable_RoomReward,X
    beq @no_spawn
    php
    jsl entity_create_and_init
    plp
    lda #120 * $0100
    sta.w entity_posx,Y
    sta.w entity_posy,Y
@no_spawn:
    rts

_Room_Spawn_Boss_Reward:
    rep #$30
    lda #ENTITY_TYPE_ITEM_PEDASTAL | ($0100 * ENTITY_ITEMPEDASTAL_POOL_BOSS)
    php
    jsl entity_create_and_init
    plp
    lda #120 * $0100
    sta.w entity_posx,Y
    lda #(120 + 32) * $0100
    sta.w entity_posy,Y
    rts

_Room_Spawn_Trapdoor:
    rep #$30
    lda #ENTITY_TYPE_TRAPDOOR
    php
    jsl entity_create_and_init
    plp
    lda #120 * $0100
    sta.w entity_posx,Y
    lda #(120) * $0100
    sta.w entity_posy,Y
    rts

_Room_Complete:
    jsr _Room_Open_Doors
    jsl updateAllDoorsInRoom
    sep #$30
    ldx.b loadedRoomIndex
    lda.w mapTileFlagsTable,X
    ora #MAPTILE_COMPLETED
    sta.w mapTileFlagsTable,X
    ; spawn room reward
    phx
    php
    sep #$20
    lda.w currentRoomDoSpawnReward
    beq +
        ; add item charge
        sep #$20
        lda #1
        jsl Item.add_charge_amount
        ; check for boss room
        sep #$30
        ldx.b loadedRoomIndex
        lda.w mapTileTypeTable,X
        cmp #ROOMTYPE_BOSS
        beq @spawnBossReward
        ; spawn reward
        jsr _Room_Spawn_Reward
        jmp +
    @spawnBossReward:
        jsr _Room_Spawn_Boss_Reward
        jsr _Room_Spawn_Trapdoor
    +:
    plp
    plx
    ;
    rts

_Room_No_Enemies:
    sep #$30
    ldx.b loadedRoomIndex
    lda.w mapTileFlagsTable,X
    and #MAPTILE_COMPLETED
    bne @already_completed
        jsr _Room_Complete
@already_completed:
    rts

Room_Tick:
    rep #$30
    lda.w currentRoomEnemyCount
    bne +
        ; no enemies
        jsr _Room_No_Enemies
    +:
    rtl

_Room_Serialize_Entities:
    phb
    .ChangeDataBank $7E
    ; jsl SortEntityExecutionOrder
    rep #$30 ; 16B AXY
    lda #0
    sta.b $00
    ldx.w numEntities
    beq @end
    @loop:
        phx
        lda.w entityExecutionOrder-1,X
        and #$00FF
        tay
        lda.w entity_type,Y
        and #$00FF
        tax
        lda.l EntityDef_Flags,X
        and #ENTITY_TYPE_FLAG_SERIALIZE
        beq +
        lda.w loword(entity_flags),Y ; skip serialization if entity forbids it
        and #ENTITY_FLAGS_DONT_SERIALIZE
        bne +
            lda.b $00
            ; skip serialization if full
            cmp #24
            beq +
            ; serialization step
            asl
            sta.b $32
            asl
            clc
            adc.b $32
            clc
            adc.b currentRoomInfoAddress
            tax
            lda.w entity_posy,Y
            sta.w roominfo_t.entityStoreTable + entitystore_t.posy-1,X
            lda.w entity_posx,Y
            sta.w roominfo_t.entityStoreTable + entitystore_t.posx-1,X
            lda.w entity_type,Y
            sta.w roominfo_t.entityStoreTable + entitystore_t.type,X
            lda.w entity_state,Y  ; entity_state and entity_timer are combined
            sta.w roominfo_t.entityStoreTable + entitystore_t.state,X
            inc.b $00
        +:
        ; plp
        plx
        dex
        bne @loop
@end:
    ; clear rest
@loop2:
    lda.b $00
    cmp #24
    beq @end2
    asl
    sta.b $32
    asl
    clc
    adc.b $32
    clc
    adc.b currentRoomInfoAddress
    tax
    stz.w roominfo_t.entityStoreTable + entitystore_t.type,X
    inc.b $00
    jmp @loop2
@end2:
    plb
    rts

; Call when the current room is to be unloaded
Room_Unload:
    ; serialize entities
    jsr _Room_Serialize_Entities
    rtl

; get devil deal chance, between 0 and 255 (inclusive)
; To check if devil deal is achieved: (rand()%256) <= GetDevilDealChance() && GetDevilDealChance() != 0
GetDevilDealChance:
    rep #$20
    lda.l currentFloorIndex
    bne +
@no_chance:
        sep #$20
        lda #0
        rtl
        .ACCU 16
    +:
    ; sep #$20
    ; if flags indicates devil deal has been checked, then return 0%
    lda.l devil_deal_flags
    bit #DEVILFLAG_DEVIL_DEAL_CHECKED
    bne @no_chance
    stz.b $00
; check modifier flags
    lda.l devil_deal_flags
    bit #DEVILFLAG_BOMBED_BEGGAR
    beq +
        lda.b $00
        clc
        adc #75
        sta.b $00
        lda.l devil_deal_flags
    +:
    bit #DEVILFLAG_BOMBED_SHOPKEEPER
    beq +
        lda.b $00
        clc
        adc #25
        sta.b $00
        lda.l devil_deal_flags
    +:
    bit #DEVILFLAG_PLAYER_TAKEN_DAMAGE
    bne +
        lda.b $00
        clc
        adc #250
        sta.b $00
        lda.l devil_deal_flags
    +:
    bit #DEVILFLAG_PLAYER_TAKEN_DAMAGE_IN_BOSS
    beq +
        lda.b $00
        clc
        adc #90
        sta.b $00
    +:
    lda.b $00
; check number of floors since devil deal
    ; 0 - got devil deal this floor: chance ×= 0%
    ; 1 - gotten devil deal last floor: chance ×= 25%
    ; 2 - gotten devil deal two floors ago: chance ×= 50%
    ; 3+: chance ×= 100%
    lda.l floors_since_devil_deal
    beq @no_chance
    cmp #2
    beq @mid_chance
    bcs @end_get_base_chance
        inc.b $00
        lsr.b $00
@mid_chance:
        inc.b $00
        lsr.b $00
@end_get_base_chance:
; end
    lda.b $00
    cmp #255
    bcc +
        lda #255
    +:
    sep #$20
    rtl

.ENDS