.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "RoomCode" FREE

; Spawn entities for room
; Args:
;   spawngroup [db] $03
_room_spawn_entities:
; spawn entities
    rep #$30 ; 16B AXY
    lda currentRoomDefinition
    tax
    lda.l $020000 + roomdefinition_t.numObjects,X
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
    lda $020000 + objectdef_t.objectType,X
    .MultiplyStatic 8
    tax
    sep #$20
    lda.l EntityDefinitions + entitytypeinfo_t.spawngroup,X
    cmp $03 + 4,S
    rep #$20
    bcc @no_spawn
        plx ; <2
        lda $020000 + objectdef_t.objectType,X
        phx ; >2
        jsl entity_create
        rep #$30
        plx ; <2
        ; clear some base info
        lda #0
        sta.w entity_posx,Y
        sta.w entity_posy,Y
        sta.w entity_velocx,Y
        sta.w entity_velocy,Y
        ; set X,Y
        sep #$20 ; 8B A
        lda $020000 + objectdef_t.x,X ; X coord
        clc
        adc #ROOM_LEFT
        sta.w entity_posx+1,Y
        lda $020000 + objectdef_t.y,X ; Y coord
        clc
        adc #ROOM_TOP
        sta.w entity_posy+1,Y
        rep #$20 ; 16B A
        phx ; >2
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
    plp
; Rest of initialization
    rep #$20
    stz.w projectile_count_2x
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

_Room_Complete:
    jsr _Room_Open_Doors
    jsl updateAllDoorsInRoom
    sep #$30
    ldx.b loadedRoomIndex
    lda.w mapTileFlagsTable,X
    ora #MAPTILE_COMPLETED
    sta.w mapTileFlagsTable,X
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

.ENDS