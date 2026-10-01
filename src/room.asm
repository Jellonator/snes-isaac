.include "base.inc"
.include "rng.inc"
.include "room.inc"
.include "map.inc"

.BANK $01 SLOT "ROM"
.SECTION "RoomCode" FREE

.DEFINE ENTITY_INDEX (coreDP+0)
.DEFINE TEMP (coreDP+2)

; Spawn entities for room
; Args:
;   spawngroup [db] $03
_room_spawn_entities:
; spawn entities
    .ForceSetAX 16, 16
    .PushBank ; +1 = 1
    .ForceSetBank $7E
    lda #ENTITY_CONTEXT_INIT_ROOMLOAD
    sta.b entityExecutionContext
    ldy #roomdefinition_t.numObjects
    lda [currentRoomDefinition],Y
    and #$00FF
    tax ; X = num entities
    beq @end_loop
    ldy #_sizeof_roomdefinition_t ; Y = entity definition pointer
    @loop:
        ; Get and create entity
        phx ; +2 = 3
        phy ; +2 = 5
        lda [currentRoomDefinition],Y ; get object type
        and #$00FF
        tax
        .ForceSetA 8
        lda.l EntityDef_SpawnGroup,X
        cmp $03 + 5,S
        .ForceSetA 16
        bcc @no_spawn
            ply ; -2 = 3
            lda [currentRoomDefinition],Y ; get object type, again
            phy ; -2 = 1
            .call "Entity.Create"
            .ForceSetAX 16, 16
            tyx ; put entity ID into X
            ply ; -2 - put entity definition into Y
            phy ; +2
            ; clear lower byte of X,Y positions
            lda #0
            sta.w entity_posx,X
            sta.w entity_posy,X
            ; set X,Y
            .ForceSetA 8
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
            .ForceSetAX 16, 16
            ; put entity ID back into Y, and init
            txy
            .call "Entity.Init"
            .ForceSetAX 16, 16
        @no_spawn:
        ply ; -2
        plx ; -2
        dex
        beq @end_loop
        iny
        iny
        iny
        iny
        bra @loop
    @end_loop:
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
        bit #$00FF
        beq @end_deserialize
        ; create entity
        phx
        php
        .call "Entity.Create"
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
        .call "Entity.Init"
        plp
        plx
        inc.b ENTITY_INDEX
        jmp @loop_deserialize
@end_deserialize:
    lda #ENTITY_CONTEXT_STANDARD
    sta.b entityExecutionContext
    .PopBank
    rts
.ClearContext

Room_Init:
    .ForceSetAX 8, 8
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
    ; .ForceSetA 8
    pha
    jsr _room_spawn_entities
    .ForceSetAX 8, 8
    stz.w currentRoomDoSpawnReward
    .ForceSetA 16
    lda.w currentRoomEnemyCount
    beq +
        .ForceSetAX 8, 8
        lda #1
        sta.w currentRoomDoSpawnReward
    +:
    .ForceSetAX 8, 8
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
    .ForceSetA 8
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
    .ForceSetAX 8, 8
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
    .ForceSetAX 8, 8
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
    .ForceSetAX 8, 8
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
    .ForceSetAX 16, 16
    ; use seed to get entityvariant
    .PushBank
    .ChangeDataBank bankbyte(PickupTable_RoomReward)
    lda #$00FF
    ldx #PickupTable_RoomReward
    .call "Random.Room.PickFromTable"
    .PopBank
    cmp #0
    beq @no_spawn
    ; change context
        .PushBank
        .ForceSetBank $7E
    ; save entity type for later
        .pha "reward_type"
    ; get entity spawn position
        .SetAX 8, 8
        .pea $7F7F
        .call "Room.GetPositionNear"
    ; create entity
        .SetAX 16, 16
        lda stk(reward_type),S
        .call "Entity.CreateAndInit"
    ; pull context
        .SetAX 16, 16
        .pla
        .pla
        .PopBank
@no_spawn:
    rts

_Room_Spawn_Boss_Reward:
    .ForceSetAX 16, 16
    lda #ENTITY_TYPE_ITEM_PEDASTAL | ($0100 * ENTITY_ITEMPEDASTAL_POOL_BOSS)
    .PushBank
    .ForceSetBank $7E
    .pea $7898
    .call "Entity.CreateAndInit"
    .SetA 16
    .pla
    .PopBank
    rts

_Room_Spawn_Trapdoor:
    .ForceSetAX 16, 16
    lda #ENTITY_TYPE_TRAPDOOR
    .PushBank
    .ForceSetBank $7E
    .pea $7878
    .call "Entity.CreateAndInit"
    .SetA 16
    .pla
    .PopBank
    rts

_room_spawn_devildoor_cancel:
    .SoftSetA 8
    .SoftSetX 8
    lda.l devil_deal_flags
    ora #DEVILFLAG_DEVIL_DEAL_CHECKED
    sta.l devil_deal_flags
    rts
_Room_Spawn_Devildoor:
; check if devil door can spawn
    ; get random number first, and always get random number so that room seed is
    ; always polled.
    .ForceSetAX 16, 16
    jsl Random.Stage.Update8
    .ForceSetAX 8, 8
    sta.b $30
    jsl GetDevilDealChance
    .SoftSetA 8
    .SoftSetX 8
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
    lda #ROOMTYPE_DEVIL
    pha
    jsl MapGen.InitializeRoomX
    pla
    ldx.b $30
    jsl MapGen.SetupRoomX
; update doors
    ldx.b $30
    jsl MapGen.UpdateDoorsForDevilRoom
; number of floors since devil deal = 0
    .ForceSetA 8
    stz.w floors_since_devil_deal
; end
    plb
    lda.l devil_deal_flags
    ora #DEVILFLAG_DEVIL_DEAL_CHECKED
    sta.l devil_deal_flags
    rts

_Room_Complete:
    jsr _Room_Open_Doors
    .ForceSetAX 8, 8
    ldx.b loadedRoomIndex
    lda.w mapTileFlagsTable,X
    ora #MAPTILE_COMPLETED
    sta.w mapTileFlagsTable,X
    ; spawn room reward
    phx
    php
    .ForceSetA 8
    lda.w currentRoomDoSpawnReward
    beq +
        ; add item charge
        .ForceSetA 8
        lda #1
        jsl Item.add_charge_amount
        ; check for boss room
        .ForceSetAX 8, 8
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
    .ForceSetAX 8, 8
    ldx.b loadedRoomIndex
    lda.w mapTileFlagsTable,X
    and #MAPTILE_COMPLETED
    bne @already_completed
        jsr _Room_Complete
@already_completed:
    rts

Room_Tick:
    .ForceSetAX 16, 16
    lda.w currentRoomEnemyCount
    bne +
        ; no enemies
        jsr _Room_No_Enemies
    +:
    rtl

_Room_Serialize_Entities:
    phb
    .ChangeDataBank $7E
    ; jsl Entity.SortExecutionOrder
    .ForceSetAX 16, 16
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
    .ForceSetA 16
    lda.l currentFloorIndex
    bne +
@no_chance:
        .ForceSetAX 8, 8
        lda #0
        rtl
        .SoftSetA 16
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
    .ForceSetAX 8, 8
    rtl

.SetDirect $0000
.SetBank $7E
.SoftSetAX 8, 8
.procimpll "Room.GetPositionNear"
    .procparam "posx", 1
    .procparam "posy", 1
    .DEFINE priority loword(tempData_7E)
    ldy #ROOM_TILE_COUNT
    @loop_init_priority:
        dey
        ; de-prioritize if in a wall/gap (top bit, highest prio)
        lda [currentRoomTileTypeTableAddress],Y
        bpl @init_priority_low ; <$80 => wall/hole, low prio
            lda #$00
            jmp @init_priority_set
        @init_priority_low:
            lda #$80
        @init_priority_set:
        sta.w priority,Y
    ; add distance to center (lower 4 bits, low prio)
        tyx
        lda.l RoomTileToWorldXTable,X
        clc
        adc #7
        sec
        sbc stk(posx),S
        .ABS_A8_POSTSBC
        and #$F0
        sta.b $00
        ; y position now
        lda.l RoomTileToWorldYTable,X
        clc
        adc #7
        sec
        sbc stk(posy),S
        .ABS_A8_POSTSBC
        and #$F0
        clc
        adc.b $00
        .AMINU P_IMM, $F0
        .DivideStatic 16
        ora.w priority,Y
        sta.w priority,Y
    ; loop
        cpy #0
        bne @loop_init_priority
; lower priority for tiles with entities on top of them (middle 3 bits, mid prio)
    ldx.w numEntities
    beq @end_loop_entities
    @loop_entities:
    ; get entity from execution order
        lda.w entityExecutionOrder-1,X
        tay
        .phx "entity_id"
    ; check flags
        ldx.w entity_type,Y
        lda.l EntityDef_Flags,X
        bit #ENTITY_TYPE_FLAG_BLOCKSPAWN | ENTITY_TYPE_FLAG_REDUCESPAWN
        beq @loop_entities_continue
        ; get tile position
        lda.w entity_box_x1,Y
        clc
        adc.w entity_box_x2,Y
        ror
        .DivideStatic 16
        .pha "entitypos"
        lda.w entity_box_y1,Y
        clc
        adc.w entity_box_y2,Y
        ror
        and #$F0
        ora stk(entitypos),S
        .phx
        tax
        lda.l GameTileToRoomTileIndexTable,X
        sta stk(entitypos),S
        .plx
        ; lda.w entity_box_x1,Y
        ; .DivideStatic 16
        ; sta.b $00
        ; sta.b $01
        ; lda.w entity_box_x2,Y
        ; dec A
        ; .DivideStatic 16
        ; cmp.b $00
        ; sta.b $02
        ; sta.b $03
        ; lda.w entity_box_y1,Y
        ; and #$F0
        ; tsb.b $00
        ; tsb.b $02
        ; lda.w entity_box_y2,Y
        ; dec A
        ; and #$F0
        ; tsb.b $01
        ; tsb.b $03
        ; ; convert tile positions to tile indices
        ; ldx.b $00
        ; lda.l GameTileToRoomTileIndexTable,X
        ; sta.b $00
        ; ldx.b $01
        ; lda.l GameTileToRoomTileIndexTable,X
        ; sta.b $01
        ; ldx.b $02
        ; lda.l GameTileToRoomTileIndexTable,X
        ; sta.b $02
        ; ldx.b $03
        ; lda.l GameTileToRoomTileIndexTable,X
        ; sta.b $03
        lda.l EntityDef_Flags,X
        bit #ENTITY_TYPE_FLAG_BLOCKSPAWN
        beq @reduce_spawn
        ; completely de-prioritize this tile
            plx
            lda #$FF
            sta.w priority,X
            jmp @loop_entities_continue
        @reduce_spawn:
        ; reduce priority by $10 for each tile
            .plx
            ; check if middle three bits are $70, and skip if so
            lda.w priority,X
            and #$70
            cmp #$70
            beq @loop_entities_continue
            lda.w priority,X
            clc
            adc #$10
            sta.w priority,X
    ; loop
    @loop_entities_continue:
        .plx
        dex
        bne @loop_entities
@end_loop_entities:
    ; find highest priority tile (smallest value)
    lda #$FF
    ldx #ROOM_TILE_COUNT
    @loop_find_min:
        dex
    ; compare
        cmp.w priority,X
        bleu @loop_find_min_continue
        ; set to current tile
            lda.l RoomTileToWorldXTable,X
            sta stk(posx),S
            lda.l RoomTileToWorldYTable,X
            sta stk(posy),S
            lda.w priority,X
    ; loop
    @loop_find_min_continue:
        cpx #0
        bne @loop_find_min
    ; end
    .UNDEFINE priority
    rtl
.endproc

.ENDS