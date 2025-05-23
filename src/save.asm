.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "MENU" FREE

; boring, I know
_save_key:
    .db "ISAAC SAVE $0001"
        ;----------------; 16B

; Return A==1 if save key does not match
_Save.CheckKey:
    sep #$20
    .REPT 16 INDEX i
        lda.l _save_key+i
        cmp.l saveCheck+i
        bnel @fail
    .ENDR
    lda #0
    rtl
@fail:
    lda #1
    rtl

Save.Init:
    jsl _Save.CheckKey
    .ACCU 8
    cmp #0
    beq +
        jsl _Save.ClearAll
    +:
    rep #$30
    lda #0
    sta.l currentSaveSlot
    rtl

_Save.ClearAll:
    ; init seed timers with random noise from RAM
    rep #$30
    ldx #0
    lda #0
@loop_seed_low:
    adc.l $7E0000,X
    inx
    inx
    bne @loop_seed_low
    sta.l seed_timer_low
    ldx #0
    lda #0
@loop_seed_high:
    adc.l $7F0000,X
    inx
    inx
    bne @loop_seed_high
    sta.l seed_timer_high
    ; clear each save slot
    rep #$20
    lda #0
    jsl Save.EraseSlot
    rep #$20
    lda #1
    jsl Save.EraseSlot
    rep #$20
    lda #2
    jsl Save.EraseSlot
    ; clear each save state
    sep #$20
    lda #0
    jsl Save.EraseSaveState
    sep #$20
    lda #1
    jsl Save.EraseSaveState
    sep #$20
    lda #2
    jsl Save.EraseSaveState
    ; finally, copy save key:
    sep #$20
    .REPT 16 INDEX i
        lda.l _save_key+i
        sta.l saveCheck+i
    .ENDR
    rtl

; Get State of given save state
Save.IsSavestateInUse:
    ; set up bank
    sep #$20
    clc
    adc #$21
    phb
    pha
    plb
    ; write save state
    lda.w loword(savestate.0.state)
    ; end
    plb
    rtl

; erase slot A
Save.EraseSlot:
    rep #$30
    and #$00FF
    .MultiplyStatic $0800
    tax
    lda #SAVESLOT_STATE_EMPTY
    sta.l saveslot.0.state,X
    rtl

; erase save state A
Save.EraseSaveState:
    ; set up bank
    sep #$20
    clc
    adc #$21
    phb
    pha
    plb
    ; write save state
    lda #SAVESTATE_STATE_EMPTY
    sta.w loword(savestate.0.state)
    ; end
    plb
    rtl

; write into save state A
Save.WriteSaveState:
; set up bank
    sep #$20
    clc
    adc #$21
    phb
    pha
    plb
; copy seed
    rep #$30
    lda.l gameSeed.low
    sta.w savestate.0.seed_game.low
    lda.l gameSeed.high
    sta.w savestate.0.seed_game.high
    lda.l gameSeedStored.low
    sta.w savestate.0.seed_game_stored.low
    lda.l gameSeedStored.high
    sta.w savestate.0.seed_game_stored.high
    lda.l stageSeed.low
    sta.w savestate.0.seed_stage.low
    lda.l stageSeed.high
    sta.w savestate.0.seed_stage.high
; copy player data
    sep #$20
    lda.l playerData.money
    sta.w savestate.0.player_money
    lda.l playerData.keys
    sta.w savestate.0.player_keys
    lda.l playerData.bombs
    sta.w savestate.0.player_bombs
    lda.l playerData.current_consumable
    sta.w savestate.0.player_consumable
    lda.l playerData.current_active_item
    sta.w savestate.0.player_active_item
    lda.l playerData.current_active_charge
    sta.w savestate.0.player_active_charge
    lda.l floors_since_devil_deal
    sta.w savestate.0.floors_since_devil_deal
    lda.l devil_deal_flags
    sta.w savestate.0.devil_deal_flags
    .REPT HEALTHSLOT_COUNT INDEX i
        lda.l playerData.healthSlots+i
        sta.w savestate.0.player_health+i
    .ENDR
    lda.l player_posx+1
    sta.w savestate.0.player_posx
    lda.l player_posy+1
    sta.w savestate.0.player_posy
; copy player item list
    lda #0
    xba
    lda.l playerData.playerItemCount
    sta.w savestate.0.player_item_count
    tax
    beq @end_loop_items
    dex
@loop_items:
        lda.l playerData.playerItemList,X
        sta.w savestate.0.player_item_list,X
        dex
        bpl @loop_items
@end_loop_items:
; copy current room slot
    lda.l currentRoomSlot
    sta.w savestate.0.room_current_slot
    rep #$20
    lda.l currentFloorIndex
    sta.w savestate.0.floor_current_index
    sep #$20
; copy rooms
    lda.l numUsedMapSlots
    sta.w savestate.0.num_rooms
    sta.b $10
    rep #$30
    stz.b $11
    lda #0
    sta.b $12
    sta.b $14
    sta.b $00
@loop_copy_room:
        ldx.b $12
        ldy.b $14
        jsl Save.WriteRoom
        ; inc
        rep #$30
        lda.b $12
        clc
        adc #_sizeof_roominfo_t
        sta.b $12
        lda.b $14
        clc
        adc #_sizeof_savestate_room_t
        sta.b $14
        inc.b $00
        dec.b $10
        bne @loop_copy_room
; copy entities
    ldy #savestate.0.entities
    lda.l numUsedMapSlots
    and #$00FF
    sta.b $10
    lda #0
    sta.b $12
    sta.b $14
    sta.b $16
    lda #SAVE_ENTITY_LIMIT
    sta.b $04
@loop_copy_entities:
        ldx.b $12
        jsl Save.WriteRoomEntities
        ; inc
        rep #$30
        lda.b $12
        clc
        adc #_sizeof_roominfo_t
        sta.b $12
        inc.b $14
        dec.b $10
        bne @loop_copy_entities
    lda #0
    ; write entity terminator
    sta.w $0000,Y
    sta.w $0002,Y
    sta.w $0004,Y
; copy roomslots
    sep #$20
    lda.l roomslot_star
    sta.w savestate.0.roomslot_star
    lda.l roomslot_boss
    sta.w savestate.0.roomslot_boss
    lda.l roomslot_start
    sta.w savestate.0.roomslot_start
    lda.l roomslot_shop
    sta.w savestate.0.roomslot_shop
    lda.l roomslot_secret1
    sta.w savestate.0.roomslot_secret1
    lda.l roomslot_secret2
    sta.w savestate.0.roomslot_secret2
; end
    sep #$20
    lda #SAVESTATE_STATE_IN_USE
    sta.w savestate.0.state
    plb
    rtl

; Copy room data from RAM in X to SRAM in Y
; $00 should also contain the room's index
; This serializes most of a room's data into the save slot.
; This function does NOT serialize entities, however.
Save.WriteRoom:
    rep #$30
; room def
    lda.l roomSlotTiles.1.roomDefinition,X
    sta.w savestate.0.rooms.1.definition,Y
; RNG
    lda.l roomSlotTiles.1.rng.low,X
    sta.w savestate.0.rooms.1.rng.low,Y
    lda.l roomSlotTiles.1.rng.high,X
    sta.w savestate.0.rooms.1.rng.high,Y
; tiles
    ; ignore variants, for now
    .REPT (ROOM_TILE_COUNT/2) INDEX i
        lda.l roomSlotTiles.1.tileTypeTable + i*2,X
        sta.w savestate.0.rooms.1.tiles + i*2,Y
    .ENDR
; room type
    ldx.b $00
    sep #$20
    lda.l roomSlotRoomType,X
    sta.w savestate.0.rooms.1.roomtype,Y
; room location
    lda #0
    xba
    lda.l roomSlotMapPos,X
    sta.w savestate.0.rooms.1.maptile_pos,Y
    tax
; map values
    lda.l mapTileTypeTable,X
    sta.w savestate.0.rooms.1.maptile_type,Y
    lda.l mapTileFlagsTable,X
    sta.w savestate.0.rooms.1.maptile_flags,Y
; door values
    lda.l mapDoorHorizontal,X
    sta.w savestate.0.rooms.1.door_east,Y
    lda.l mapDoorVertical,X
    sta.w savestate.0.rooms.1.door_south,Y
    rtl

_end_write_entities:
    rtl
; Save entities for room at X into SRAM at Y
; $14 is CURRENT ROOM INDEX
; $16 is LAST STORED ENTITY'S ROOM INDEX
Save.WriteRoomEntities:
    rep #$20
    lda #ENTITY_STORE_COUNT
    sta.b $02
@loop:
    ; check not at end of table
    dec.b $02
    bmi _end_write_entities
    ; check type is non-zero
    lda.l roomSlotTiles.1.entityStoreTable.1.type,X
    bit #$00FF
    beq _end_write_entities
    ; write null entities, if needed
@try_null_ent:
    lda.b $14
    sec
    sbc.b $16
    cmp #16
    bcc @no_null_ent
        lda #0
        sta.w $0000,Y
        sta.w $0004,Y
        lda #$F000
        sta.w $0002,Y
        iny
        iny
        iny
        iny
        iny
        iny
        lda.b $16
        clc
        adc $15
        sta.b $16
        jmp @try_null_ent
@no_null_ent:
    ; type+variant
    lda.l roomSlotTiles.1.entityStoreTable.1.type,X
    sta.w $0000,Y
    iny
    iny
    ; X,Y,room
    stz.b $00
    lda.l roomSlotTiles.1.entityStoreTable.1.posx,X
    and #$00FC
    .ShiftLeft 4
    tsb.b $00
    lda.l roomSlotTiles.1.entityStoreTable.1.posy,X
    and #$00FC
    .ShiftRight 2
    tsb.b $00
    lda.b $14
    sec
    sbc.b $16
    xba
    .ShiftLeft 4
    ora.b $00
    sta.w $0000,Y
    iny
    iny
    lda.b $14
    sta.b $16
    ; state,timer 
    lda.l roomSlotTiles.1.entityStoreTable.1.state,X
    sta.w $0000,Y
    ; next entity
    iny
    iny
    inx
    inx
    inx
    inx
    inx
    inx
    jmp @loop

; Read data from save state
Save.ReadSaveState:
; set up bank
    sep #$20
    clc
    adc #$21
    phb
    pha
    plb
; copy seed
    rep #$30
    lda.w savestate.0.seed_game.low
    sta.l gameSeed.low
    lda.w savestate.0.seed_game.high
    sta.l gameSeed.high
    lda.w savestate.0.seed_game_stored.low
    sta.l gameSeedStored.low
    lda.w savestate.0.seed_game_stored.high
    sta.l gameSeedStored.high
    lda.w savestate.0.seed_stage.low
    sta.l stageSeed.low
    lda.w savestate.0.seed_stage.high
    sta.l stageSeed.high
; copy player data
    sep #$20
    lda.w savestate.0.player_money
    sta.l playerData.money
    lda.w savestate.0.player_keys
    sta.l playerData.keys
    lda.w savestate.0.player_bombs
    sta.l playerData.bombs
    lda.w savestate.0.player_consumable
    sta.l playerData.current_consumable
    lda.w savestate.0.player_active_item
    sta.l playerData.current_active_item
    lda.w savestate.0.player_active_charge
    sta.l playerData.current_active_charge
    lda.w savestate.0.floors_since_devil_deal
    sta.l floors_since_devil_deal
    lda.w savestate.0.devil_deal_flags
    sta.l devil_deal_flags
    .REPT HEALTHSLOT_COUNT INDEX i
        lda.w savestate.0.player_health+i
        sta.l playerData.healthSlots+i
    .ENDR
    lda.w savestate.0.player_posx
    sta.l player_posx+1
    lda.w savestate.0.player_posy
    sta.l player_posy+1
    lda #0
    sta.l player_posx
    sta.l player_posy
; copy player items into list
    lda #0
    xba
    lda.w savestate.0.player_item_count
    sta.l playerData.playerItemCount
    tay
    beq @end_copy_item_list
    dey
@loop_copy_item_list:
    ; copy into list
    tyx
    lda.w savestate.0.player_item_list,Y
    sta.l playerData.playerItemList,X
    ; increment stack count
    tax
    lda.l playerData.playerItemStackNumber,X
    inc A
    sta.l playerData.playerItemStackNumber,X
    ; --y
    dey
    bpl @loop_copy_item_list
@end_copy_item_list:
; copy current room slot
    lda.w savestate.0.room_current_slot
    sta.l currentRoomSlot
    rep #$30
    lda.w savestate.0.floor_current_index
    sta.l currentFloorIndex
    asl
    tax
    lda.l FloorDefinitions,X
    sta.l currentFloorPointer
    sep #$20
; copy rooms
    lda.w savestate.0.num_rooms
    sta.l numUsedMapSlots
    sta.b $10
    rep #$30
    stz.b $11
    lda #0
    sta.b $12
    sta.b $14
    sta.b $00
@loop_copy_room:
        ldx.b $12
        ldy.b $14
        jsl Save.ReadRoom
        ; inc
        rep #$30
        lda.b $12
        clc
        adc #_sizeof_roominfo_t
        sta.b $12
        lda.b $14
        clc
        adc #_sizeof_savestate_room_t
        sta.b $14
        inc.b $00
        dec.b $10
        bne @loop_copy_room
; copy entities
    ldy #savestate.0.entities
    ldx #roomSlotTiles.1.entityStoreTable
    lda #0
    sta.b $10
    @loop_copy_entities:
        lda.w $0000,Y
        bit #$00FF
        beq @ent_null
        ; not null entity, deserialize as normal
        lda.w $0002,Y
        and #$F000
        beq @skip_inc_room
            xba
            .ShiftRight 4
            clc
            adc.b $10
            sta.b $10
            ; figure out new X
            .MultiplyIndexByRoomSizeA P_DIR, $10
            clc
            adc #roomSlotTiles.1.entityStoreTable
            tax
        @skip_inc_room:
        ; type+variant
        lda.w $0000,Y
        sta.l $7E0000,X
        ; X
        lda.w $0002,Y
        and #$0FC0
        .ShiftRight 4
        sta.l $7E0002,X
        ; Y
        lda.w $0002,Y
        and #$003F
        .ShiftLeft 2
        sta.l $7E0003,X
        ; state+timer
        lda.w $0004,Y
        sta.l $7E0004,X
        ; inc
        inx
        inx
        inx
        inx
        inx
        inx
        iny
        iny
        iny
        iny
        iny
        iny
        jmp @loop_copy_entities
    @ent_null:
        ; null entity; don't deserialize, just increment room index
        lda.w $0002,Y
        bit #$F000
        beq @end_copy_entities
        xba
        .ShiftRight 4
        clc
        adc.b $10
        sta.b $10
        ; figure out new X
        .MultiplyIndexByRoomSizeA P_DIR, $10
        clc
        adc #roomSlotTiles.1.entityStoreTable
        tax
        iny
        iny
        iny
        iny
        iny
        iny
        jmp @loop_copy_entities
@end_copy_entities:
; copy roomslots
    sep #$20
    lda.w savestate.0.roomslot_star
    sta.l roomslot_star
    lda.w savestate.0.roomslot_boss
    sta.l roomslot_boss
    lda.w savestate.0.roomslot_start
    sta.l roomslot_start
    lda.w savestate.0.roomslot_shop
    sta.l roomslot_shop
    lda.w savestate.0.roomslot_secret1
    sta.l roomslot_secret1
    lda.w savestate.0.roomslot_secret2
    sta.l roomslot_secret2
; end
    sep #$20
    lda #SAVESTATE_STATE_EMPTY
    sta.w savestate.0.state
    plb
    rtl

; Copy room data from SRAM in Y to RAM in X
; $00 should also contain the room's index
; This deserializes most of a room's data into the save slot.
; This function does NOT deserialize entities, however.
Save.ReadRoom:
    rep #$30
; room def
    lda.w savestate.0.rooms.1.definition,Y
    sta.l roomSlotTiles.1.roomDefinition,X
; RNG
    lda.w savestate.0.rooms.1.rng.low,Y
    sta.l roomSlotTiles.1.rng.low,X
    lda.w savestate.0.rooms.1.rng.high,Y
    sta.l roomSlotTiles.1.rng.high,X
; tiles
    .REPT (ROOM_TILE_COUNT/2) INDEX i
        lda.w savestate.0.rooms.1.tiles + i*2,Y
        sta.l roomSlotTiles.1.tileTypeTable + i*2,X
    .ENDR
    lda #0
    .REPT (ROOM_TILE_COUNT/2) INDEX i
        sta.l roomSlotTiles.1.tileVariantTable + i*2,X
    .ENDR
; clear entities
    lda #0
    .REPT ENTITY_STORE_COUNT INDEX i
        sta.l roomSlotTiles.1.entityStoreTable.{i+1}.type,X
    .ENDR
; room type
    ldx.b $00
    sep #$20
    lda.w savestate.0.rooms.1.roomtype,Y
    sta.l roomSlotRoomType,X
; room location
    lda #0
    xba
    lda.w savestate.0.rooms.1.maptile_pos,Y
    sta.l roomSlotMapPos,X
    tax
    lda.b $00
    sta.l mapTileSlotTable,X
; map values
    lda.w savestate.0.rooms.1.maptile_type,Y
    sta.l mapTileTypeTable,X
    lda.w savestate.0.rooms.1.maptile_flags,Y
    sta.l mapTileFlagsTable,X
; door values
    lda.w savestate.0.rooms.1.door_east,Y
    sta.l mapDoorHorizontal,X
    lda.w savestate.0.rooms.1.door_south,Y
    sta.l mapDoorVertical,X
    rtl

.ENDS