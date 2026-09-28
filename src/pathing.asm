.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "Pathing" FREE

Pathing.Initialize:
; clear player
    .ForceSetAX 16, 16
    phd
    pea $4300
    pld
    lda #256
    sta.b <DMA0_SIZE
    lda #loword(InitialPathfindingData)
    sta.b <DMA0_SRCL
    lda #loword(pathfind_player_data)
    sta.w WMADDL
    .ForceSetA 8
    lda #0
    sta.b <DMA0_SRCH ; InitialPathfindingData is in bank 0
    sta.w WMADDH ; only bottom bit matters, so just store 0
    ; Absolute address, increment, 1 byte at a time
    sta.b <DMA0_CTL
    ; Write to WRAM
    lda #$80
    sta.b <DMA0_DEST
    lda #$01
    sta.w MDMAEN
; clear enemy
    .ForceSetAX 16, 16
    lda #256
    sta.b <DMA0_SIZE
    lda #loword(InitialPathfindingData)
    sta.b <DMA0_SRCL
    lda #loword(pathfind_enemy_data)
    sta.w WMADDL
    .ForceSetA 8
    lda #0
    sta.b <DMA0_SRCH ; InitialPathfindingData is in bank 0
    sta.w WMADDH ; only bottom bit matters, so just store 0
    ; Absolute address, increment, 1 byte at a time
    sta.b <DMA0_CTL
    ; Write to WRAM
    lda #$80
    sta.b <DMA0_DEST
    lda #$01
    sta.w MDMAEN
; clear nearest enemy ID
    .ForceSetAX 16, 16
    lda #256
    sta.b <DMA0_SIZE
    lda #loword(EmptyData)
    sta.b <DMA0_SRCL
    lda #loword(pathfind_nearest_enemy_id)
    sta.w WMADDL
    .ForceSetA 8
    lda #0
    sta.b <DMA0_SRCH ; EmptyData is in bank 0
    sta.w WMADDH ; only bottom bit matters, so just store 0
    ; Absolute address, no increment, 1 byte at a time
    lda #%00001000
    sta.b <DMA0_CTL
    ; Write to WRAM
    lda #$80
    sta.b <DMA0_DEST
    lda #$01
    sta.w MDMAEN
    pld
    rtl

_clear_player:
    .ForceSetAX 16, 16
    phd
    pea $4300
    pld
    lda #128-4
    sta.b <DMA0_SIZE
    lda #loword(16 * 4 + InitialPathfindingData + 2)
    sta.b <DMA0_SRCL
    lda #loword(16 * 4 + pathfind_player_data + 2)
    sta.w WMADDL
    .ForceSetA 8
    lda #0
    sta.b <DMA0_SRCH ; InitialPathfindingData is in bank 0
    sta.w WMADDH ; only bottom bit matters, so just store 0
    ; Absolute address, increment, 1 byte at a time
    sta.b <DMA0_CTL
    ; Write to WRAM
    lda #$80
    sta.b <DMA0_DEST
    lda #$01
    sta.w MDMAEN
    pld
    rts

_clear_enemy:
    .ForceSetAX 16, 16
    phd
    pea $4300
    pld
    lda #128-4
    sta.b <DMA0_SIZE
    lda #loword(16 * 4 + InitialPathfindingData + 2)
    sta.b <DMA0_SRCL
    lda #loword(16 * 4 + pathfind_enemy_data + 2)
    sta.w WMADDL
    .ForceSetA 8
    lda #0
    sta.b <DMA0_SRCH ; InitialPathfindingData is in bank 0
    sta.w WMADDH ; only bottom bit matters, so just store 0
    ; Absolute address, increment, 1 byte at a time
    sta.b <DMA0_CTL
    ; Write to WRAM
    lda #$80
    sta.b <DMA0_DEST
    lda #$01
    sta.w MDMAEN
    pld
    rts

_clear_enemy_nearest:
    .ForceSetAX 16, 16
    phd
    pea $4300
    pld
    lda #256
    sta.b <DMA0_SIZE
    lda #loword(EmptyData)
    sta.b <DMA0_SRCL
    lda #loword(pathfind_nearest_enemy_id)
    sta.w WMADDL
    .ForceSetA 8
    lda #0
    sta.b <DMA0_SRCH ; EmptyData is in bank 0
    sta.w WMADDH ; only bottom bit matters, so just store 0
    ; Absolute address, no increment, 1 byte at a time
    lda #%00001000
    sta.b <DMA0_CTL
    ; Write to WRAM
    lda #$80
    sta.b <DMA0_DEST
    lda #$01
    sta.w MDMAEN
    pld
    rts

.DEFINE tile $20
.DEFINE tile_left $22
.DEFINE tile_right $24
.DEFINE tile_up $26
.DEFINE tile_down $28
.DEFINE q_start $2A
.DEFINE q_end $2C
.DEFINE q_count $2E
.DEFINE stack_store $2E ; q_count is not used once we store stack

Pathing.UpdatePlayer:
    jsr _clear_player
; set bank and direct page
    ; DB = $7E
    phb
    .ChangeDataBank $7E
    .ForceSetAX 16, 16
    ; set direct page to refer to pathfinding data
    phd
    pea pathfind_player_data - $20
    pld
; setup queue
    ldx #loword(tempData_shared | $FF)
    stx.b q_start
    stx.b q_end
    .ForceSetAX 8, 8
; begin
    ; push player's tile to queue
    lda.w player_posx+1
    adc #8
    .DivideStatic 16
    sta.b q_count ; q_count used as temp variable
    lda.w player_posy+1
    adc #8
    and #$F0
    ora.b q_count
    sta.b (q_end)
    dec.b q_end
    ; indicate player's central tile
    tax
    lda #PATH_DIR_NONE
    sta.b $20,X
    lda #1
    sta.b q_count
; Main pathfinding routine
_pathfind_main:
    .ForceSetAX 16, 16
; store stack address
    tsc
    sta.b stack_store
; setup tile addresses
    lda.l currentRoomTileTypeTableAddress
    sta.b tile
    dec A
    sta.b tile_left
    inc A
    inc A
    sta.b tile_right
    clc
    adc #12-1
    sta.b tile_down
    sec
    sbc #24
    sta.b tile_up
; set stack address to q_end
    lda.b q_end
    tcs
; begin loop
    .ForceSetAX 8, 8
    lda #0
    sta $00,S
    jmp @loop
; end is placed here, to be closer to start of loop
    @end:
        .PushContext
        .SetA 16
        lda.b stack_store
        tcs
        pld
        plb
        rtl
        .PopContextSoft
; nexttile is placed here, to be closer to start of loop
    @nexttile:
        .SoftSetAX 8, 8
        dec.b q_start
    @loop:
        .SoftSetAX 8, 8
        lda.b (q_start)
        beq @end ; value is 0, end
        tax ; X = tile position
        lda.l GameTileToRoomTileIndexTable,X ; A = tile index
        tay
        lda (tile),Y
        bpl @nexttile ; Skip if this tile is solid (can not be entered)
        .REPT 8 INDEX i
            .IF i == 0
                .DEFINE i_offs -1
                .DEFINE i_dir PATH_DIR_RIGHT
            .ELIF i == 1
                .DEFINE i_offs 1
                .DEFINE i_dir PATH_DIR_LEFT
            .ELIF i == 2
                .DEFINE i_offs 16
                .DEFINE i_dir PATH_DIR_UP
            .ELIF i == 3
                .DEFINE i_offs -16
                .DEFINE i_dir PATH_DIR_DOWN
            .ELIF i == 4
                .DEFINE i_offs -16-1
                .DEFINE i_dir PATH_DIR_DOWNRIGHT
            .ELIF i == 5
                .DEFINE i_offs -16+1
                .DEFINE i_dir PATH_DIR_DOWNLEFT
            .ELIF i == 6
                .DEFINE i_offs 16-1
                .DEFINE i_dir PATH_DIR_UPRIGHT
            .ELIF i == 7
                .DEFINE i_offs 16+1
                .DEFINE i_dir PATH_DIR_UPLEFT
            .ENDIF
            lda.b $20+i_offs,X
            bne + ; If path is already calculated, then pass
            ; if diagonal tile, then check if adjacent tiles had path calculated
            .IF i == 4
                lda (tile_up),Y
                and (tile_left),Y
                bpl +
            .ELIF i == 5
                lda (tile_up),Y
                and (tile_right),Y
                bpl +
            .ELIF i == 6
                lda (tile_down),Y
                and (tile_left),Y
                bpl +
            .ELIF i == 7
                lda (tile_down),Y
                and (tile_right),Y
                bpl +
            .ENDIF
                lda #i_dir
                sta.b $20+i_offs,X
                lda.l OffsetTable+i_offs,X
                pha
                lda #0
                sta $00,S
            +:
            .UNDEFINE i_dir
            .UNDEFINE i_offs
        .ENDR
    ; loop iterate
        jmp @nexttile

Pathing.UpdateEnemy:
    jsr _clear_enemy
; set bank and direct page
    phb
    .ChangeDataBank $7E
    .ForceSetAX 16, 16
    phd
    pea pathfind_enemy_data - $20
    pld
; setup queue
    ldx #loword(tempData_shared | $FF)
    stx.b q_start
    stx.b q_end
    .ForceSetAX 8, 8
    lda #0
    sta.b q_count
; set entity positions
    lda.w numEntities
    beq @end_entities
    sta.b tile ; use `tile` as entity index
@loop_entities:
        ldx.b tile
        ldy.w entityExecutionOrder-1,X
        lda.w loword(entity_flags),Y
        and #ENTITY_FLAGS_NEAREST_ENEMY_TARGET
        beq @skip_entity
        ; get index
        lda.w entity_box_x1,Y
        clc
        adc.w entity_box_x2,Y
        ror
        .DivideStatic 16
        sta.b tile_left
        lda.w entity_box_y1,Y
        clc
        adc.w entity_box_y2,Y
        ror
        and #$F0
        ora.b tile_left
        ; put in queue
        sta.b (q_end)
        tax
        ; skip if entity is OOB
        lda.l GameTileBoundaryCheck,X
        bmi @skip_entity
        ; finish putting into queue
        lda #PATH_DIR_NONE
        sta.b $20,X
        inc.b q_count
        dec.b q_end
    @skip_entity:
        dec.b tile
        bne @loop_entities
@end_entities:
; main
    .ForceSetAX 8, 8
    lda.b q_count
    bne +
        pld
        plb
        rtl
    +:
    jmp _pathfind_main

; Set nearest entity ID for every tile in `pathfind_nearest_enemy_id`
; For now, this is just Manhattan distance, so don't expect accuracy
Pathing.UpdateEnemyNearest:
    jsr _clear_enemy_nearest
; set bank and direct page
    phb
    .ChangeDataBank $7E
    .ForceSetAX 16, 16
    phd
    pea pathfind_nearest_enemy_id - $20
    pld
; setup queue
    ldx #loword(tempData_7E | $FF)
    stx.b q_start
    stx.b q_end
    .ForceSetAX 8, 8
    lda #0
    sta.b q_count
; set entity positions
    lda.w numEntities
    beq @end_entities
    sta.b tile ; use `tile` as entity index
@loop_entities:
        ldx.b tile
        ldy.w entityExecutionOrder-1,X
        lda.w loword(entity_flags),Y
        and #ENTITY_FLAGS_NEAREST_ENEMY_TARGET
        beq @skip_entity
        ; get index
        lda.w entity_box_x1,Y
        clc
        adc.w entity_box_x2,Y
        ror
        .DivideStatic 16
        sta.b tile_left
        lda.w entity_box_y1,Y
        clc
        adc.w entity_box_y2,Y
        ror
        and #$F0
        ora.b tile_left
        ; put in queue
        sta.b (q_end)
        tax
        ; skip if out of bounds
        lda.l GameTileBoundaryCheck,X
        bmi @skip_entity
        ; finish putting into queue
        tya
        sta.b $20,X
        inc.b q_count
        dec.b q_end
    @skip_entity:
        dec.b tile
        bne @loop_entities
@end_entities:
    ; check entity count
    .ForceSetAX 8, 8
    lda.b q_count
    bne +
        pld
        plb
        rtl
    +:
    ; main
    @loop:
        lda.b (q_start)
        tax
        lda.l InitialPathfindingData,X
        bne @skiptile ; skip tile if outside of room
        ; conveniently, InitialPathFindingData has null values for valid tile locations
        .REPT 4 INDEX i
            .IF i == 0
                .DEFINE i_offs -1
            .ELIF i == 1
                .DEFINE i_offs 1
            .ELIF i == 2
                .DEFINE i_offs 16
            .ELIF i == 3
                .DEFINE i_offs -16
            .ENDIF
            lda.b $20+i_offs,X
            bne + ; If found tile is non-zero, skip it
                lda.b $20,X
                sta.b $20+i_offs,X
                lda.l OffsetTable+i_offs,X
                sta.b (q_end)
                dec.b q_end
                inc.b q_count
            +:
            .UNDEFINE i_offs
        .ENDR
    @skiptile:
        dec.b q_start
        dec.b q_count
        bnel @loop
; end
    pld
    plb
    rtl

.ENDS