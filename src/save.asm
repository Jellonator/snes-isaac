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
    .REPT HEALTHSLOT_COUNT INDEX i
        lda.l playerData.healthSlots+i
        sta.w savestate.0.player_health+i
    .ENDR
    ldx #255
; copy player items
@loop_items:
    lda.l playerData.playerItemStackNumber,X
    sta.w savestate.0.player_itemcounts,X
    dex
    bpl @loop_items
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
    and #$FC00
    .ShiftRight 4
    tsb.b $00
    lda.l roomSlotTiles.1.entityStoreTable.1.posy,X
    and #$FC00
    xba
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
.ENDS