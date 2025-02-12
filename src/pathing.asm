.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "Pathing" FREE

Pathing.Initialize:
; clear player
    rep #$30
    phd
    pea $4300
    pld
    lda #256
    sta.b <DMA0_SIZE
    lda #loword(InitialPathfindingData)
    sta.b <DMA0_SRCL
    lda #loword(pathfind_player_data)
    sta.w WMADDL
    sep #$20 ; 8 bit A
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
    rep #$30
    lda #256
    sta.b <DMA0_SIZE
    lda #loword(InitialPathfindingData)
    sta.b <DMA0_SRCL
    lda #loword(pathfind_enemy_data)
    sta.w WMADDL
    sep #$20 ; 8 bit A
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
    rep #$30
    lda #256
    sta.b <DMA0_SIZE
    lda #loword(EmptyData)
    sta.b <DMA0_SRCL
    lda #loword(pathfind_nearest_enemy_id)
    sta.w WMADDL
    sep #$20 ; 8 bit A
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
    rep #$30
    phd
    pea $4300
    pld
    lda #128-4
    sta.b <DMA0_SIZE
    lda #loword(16 * 4 + InitialPathfindingData + 2)
    sta.b <DMA0_SRCL
    lda #loword(16 * 4 + pathfind_player_data + 2)
    sta.w WMADDL
    sep #$20 ; 8 bit A
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
    rep #$30
    phd
    pea $4300
    pld
    lda #128-4
    sta.b <DMA0_SIZE
    lda #loword(16 * 4 + InitialPathfindingData + 2)
    sta.b <DMA0_SRCL
    lda #loword(16 * 4 + pathfind_enemy_data + 2)
    sta.w WMADDL
    sep #$20 ; 8 bit A
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
    rep #$30
    phd
    pea $4300
    pld
    lda #256
    sta.b <DMA0_SIZE
    lda #loword(EmptyData)
    sta.b <DMA0_SRCL
    lda #loword(pathfind_nearest_enemy_id)
    sta.w WMADDL
    sep #$20 ; 8 bit A
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

Pathing.UpdatePlayer:
    jsr _clear_player
; set bank and direct page
    phb
    .ChangeDataBank $7E
    rep #$30
    phd
    pea pathfind_player_data - $20
    pld
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
; setup queue
    ldx #loword(tempData_7E | $FF)
    stx.b q_start
    stx.b q_end
    sep #$30
; begin
    lda.w player_posx+1
    adc #8
    .DivideStatic 16
    sta.b q_count
    lda.w player_posy+1
    adc #8
    and #$F0
    ora.b q_count
    sta.b (q_end)
    dec.b q_end
    tax
    lda #PATH_DIR_NONE
    sta.b $20,X
    lda #1
    sta.b q_count
; Main pathfinding routine
_pathfind_main:
    .ACCU 8
    .INDEX 8
    @loop:
        lda.b (q_start)
        tax
        lda.l GameTileToRoomTileIndexTable,X
        tay
        lda (tile),Y
        bmil @skiptile ; Skip if this tile is solid (can not be entered)
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
            bne + ; If found tile is non-zero, skip it
            ; if diagonal tile, then check adjacent tiles for clearance
            .IF i == 4
                lda (tile_up),Y
                ora (tile_left),Y
                bmi +
            .ELIF i == 5
                lda (tile_up),Y
                ora (tile_right),Y
                bmi +
            .ELIF i == 6
                lda (tile_down),Y
                ora (tile_left),Y
                bmi +
            .ELIF i == 7
                lda (tile_down),Y
                ora (tile_right),Y
                bmi +
            .ENDIF
                ; A is already 0
                .IF i_dir == 1
                    inc A
                .ELIF i_dir > 1
                    lda #i_dir
                .ENDIF
                sta.b $20+i_offs,X
                lda.l OffsetTable+i_offs,X
                sta.b (q_end)
                dec.b q_end
                inc.b q_count
            +:
            .UNDEFINE i_dir
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

Pathing.UpdateEnemy:
    jsr _clear_enemy
; set bank and direct page
    phb
    .ChangeDataBank $7E
    rep #$30
    phd
    pea pathfind_enemy_data - $20
    pld
; setup queue
    ldx #loword(tempData_7E | $FF)
    stx.b q_start
    stx.b q_end
    sep #$30
    lda #0
    sta.b q_count
; set entity positions
    lda.w numEntities
    beq @end_entities
    sta.b tile ; use `tile` as entity index
@loop_entities:
        ldx.b tile
        ldy.w entityExecutionOrder-1,X
        lda.w entity_mask,Y
        and #ENTITY_MASK_TEAR
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
        lda #PATH_DIR_NONE
        sta.b $20,X
        inc.b q_count
        dec.b q_end
    @skip_entity:
        dec.b tile
        bne @loop_entities
@end_entities:
; setup tile addresses
    rep #$30
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
; main
    sep #$30
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
    rep #$30
    phd
    pea pathfind_nearest_enemy_id - $20
    pld
; setup queue
    ldx #loword(tempData_7E | $FF)
    stx.b q_start
    stx.b q_end
    sep #$30
    lda #0
    sta.b q_count
; set entity positions
    lda.w numEntities
    beq @end_entities
    sta.b tile ; use `tile` as entity index
@loop_entities:
        ldx.b tile
        ldy.w entityExecutionOrder-1,X
        lda.w entity_mask,Y
        and #ENTITY_MASK_TEAR
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
        tya
        sta.b $20,X
        inc.b q_count
        dec.b q_end
    @skip_entity:
        dec.b tile
        bne @loop_entities
@end_entities:
    ; check entity count
    sep #$30
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