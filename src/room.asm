.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "RoomCode" FREE

.DEFINE ENTITY_INDEX (coreDP+0)
.DEFINE TEMP (coreDP+2)

; Spawn entities for room
; Args:
;   spawngroup [db] $03
_room_spawn_entities:
; spawn entities
    rep #$30 ; 16B AXY
    lda #ENTITY_CONTEXT_INIT_ROOMLOAD
    sta.b entityExecutionContext
    ldy #roomdefinition_t.numObjects
    lda [currentRoomDefinition],Y
    and #$00FF
    tax ; X = num entities
    beq @end
    ldy #_sizeof_roomdefinition_t ; Y = entity definition pointer
@loop:
    ; Get and create entity
    phx ; >2
    phy ; >2
    lda [currentRoomDefinition],Y ; get object type
    and #$00FF
    tax
    sep #$20
    lda.l EntityDef_SpawnGroup,X
    cmp $03 + 4,S
    rep #$20
    bcc @no_spawn
        ply ; <2
        lda [currentRoomDefinition],Y ; get object type, again
        phy ; >2
        jsl entity_create
        rep #$30
        tyx ; put entity ID into X
        ply ; <2 - put entity definition into Y
        phy ; >2
        ; clear lower byte of X,Y positions
        lda #0
        sta.w entity_posx,X
        sta.w entity_posy,X
        ; set X,Y
        sep #$20 ; 8B A
        iny
        iny
        lda [currentRoomDefinition],Y ; X coord
        clc
        adc #ROOM_LEFT
        sta.w entity_posx+1,X
        iny
        lda [currentRoomDefinition],Y ; Y coord
        clc
        adc #ROOM_TOP
        sta.w entity_posy+1,X
        rep #$30
        ; put entity ID back into Y, and init
        txy
        jsl entity_init
        rep #$30
    @no_spawn:
    ply ; <2
    plx ; <2
    dex
    beq @end
    iny
    iny
    iny
    iny
    bra @loop
@end:
; deserialize entities
    lda #ENTITY_CONTEXT_INIT_DESERIALIZE
    sta.b entityExecutionContext
    stz.b ENTITY_INDEX
    @loop_deserialize:
        lda.b ENTITY_INDEX
        cmp #ENTITY_STORE_COUNT
        beq @end_deserialize
        asl
        sta.b TEMP
        asl
        clc
        adc.b TEMP
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
        inc.b ENTITY_INDEX
        jmp @loop_deserialize
@end_deserialize:
    lda #ENTITY_CONTEXT_STANDARD
    sta.b entityExecutionContext
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
; if this is a boss room, then close devil room doors
    ldx.b loadedRoomIndex
    lda.w mapTileTypeTable,X
    cmp #ROOMTYPE_BOSS
    bne +
        jsr _Room_Close_Devil_Doors
    +:
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
; spawn player familiars
    jsl Familiars.RefreshFamiliars
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

_Room_Close_Devil_Doors:
    sep #$30
    .REPT 4 INDEX i
        lda.b [MAP_DOOR_MEM_LOC(i)]
        cmp #(DOOR_TYPE_NORMAL | DOOR_METHOD_DEVIL | DOOR_OPEN)
        bne +
            lda #0
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

_room_spawn_devildoor_cancel:
    .ACCU 8
    .INDEX 8
    lda.l devil_deal_flags
    ora #DEVILFLAG_DEVIL_DEAL_CHECKED
    sta.l devil_deal_flags
    rts
_Room_Spawn_Devildoor:
; check if devil door can spawn
    ; get random number first, and always get random number so that room seed is
    ; always polled.
    jsl StageRand_Update8
    sep #$30
    sta.b $30
    jsl GetDevilDealChance
    .ACCU 8
    .INDEX 8
    cmp #0
    beq _room_spawn_devildoor_cancel ; CHANCE == 0: cancel
    cmp.b $30
    bcc _room_spawn_devildoor_cancel ; CHANCE >= RAND: spawn devil room
; step one: determine where devil room should spawn.
; we can just check adjacent room tiles to see which are empty.
    lda.b loadedRoomIndex
    sec
    sbc #16
    tax
    lda.w mapTileTypeTable,X
    beq @found_tile
    lda.b loadedRoomIndex
    clc
    adc #16
    tax
    lda.w mapTileTypeTable,X
    beq @found_tile
    ; considering boss rooms can only have one adjacent tile normally,
    ; if we get here, something is probably amiss. oh well.
    ldx.b loadedRoomIndex
    dex
    lda.w mapTileTypeTable,X
    beq @found_tile
    inx
    inx
    lda.w mapTileTypeTable,X
    beq @found_tile
    jmp _room_spawn_devildoor_cancel
@found_tile:
    stx.b $30
; set up bank
    phb
    .ChangeDataBank $7E
; initialize room slot
    lda #MAPSLOT_DEVIL
    pha
    lda #ROOMTYPE_DEVIL
    pha
    jsl MapGen.InitializeRoomXIntoSlot
    pla
    pla
    ldx.b $30
    jsl MapGen.SetupRoomX
; update doors
    ldx.b $30
    jsl MapGen.UpdateDoorsForDevilRoom
; number of floors since devil deal = 0
    sep #$20
    stz.w floors_since_devil_deal
; end
    plb
    lda.l devil_deal_flags
    ora #DEVILFLAG_DEVIL_DEAL_CHECKED
    sta.l devil_deal_flags
    rts

_Room_Complete:
    jsr _Room_Open_Doors
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
        jsr _Room_Spawn_Devildoor
    +:
    jsl updateAllDoorsInRoom
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
    sta.b ENTITY_INDEX
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
            lda.b ENTITY_INDEX
            ; skip serialization if full
            cmp #24
            beq +
            ; serialization step
            asl
            sta.b TEMP
            asl
            clc
            adc.b TEMP
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
            inc.b ENTITY_INDEX
        +:
        ; plp
        plx
        dex
        bne @loop
@end:
    ; clear rest
@loop2:
    lda.b ENTITY_INDEX
    cmp #24
    beq @end2
    asl
    sta.b TEMP
    asl
    clc
    adc.b TEMP
    clc
    adc.b currentRoomInfoAddress
    tax
    stz.w roominfo_t.entityStoreTable + entitystore_t.type,X
    inc.b ENTITY_INDEX
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
        sep #$30
        lda #0
        rtl
        .ACCU 16
    +:
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
    bne +
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
    sep #$30
    rtl

.ENDS