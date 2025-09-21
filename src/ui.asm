.include "base.inc"

.BANK $01 SLOT "ROM"
.SECTION "UI" FREE

UI.update_money_display:
    rep #$30 ; 16B AXY
    ; inc vqueue
    lda.w vqueueNumMiniOps
    asl
    asl
    tax
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    ; first, determine offset
    lda #BG1_TILE_BASE_ADDR + $46
    sta.l vqueueMiniOps.1.vramAddr,X
    lda #BG1_TILE_BASE_ADDR + $47
    sta.l vqueueMiniOps.2.vramAddr,X
    ; now, determine character
    lda.w playerData.money
    and #$00F0
    lsr
    lsr
    lsr
    lsr
    clc
    adc #deft(TILE_TEXT_UINUMBER_BASE,5) | T_HIGHP
    sta.l vqueueMiniOps.1.data,X
    lda.w playerData.money
    and #$000F
    clc
    adc #deft(TILE_TEXT_UINUMBER_BASE,5) | T_HIGHP
    sta.l vqueueMiniOps.2.data,X
    rtl

UI.update_bomb_display:
    rep #$30 ; 16B AXY
    ; inc vqueue
    lda.w vqueueNumMiniOps
    asl
    asl
    tax
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    ; first, determine offset
    lda #BG1_TILE_BASE_ADDR + $66
    sta.l vqueueMiniOps.1.vramAddr,X
    lda #BG1_TILE_BASE_ADDR + $67
    sta.l vqueueMiniOps.2.vramAddr,X
    ; now, determine character
    lda.w playerData.bombs
    and #$00F0
    lsr
    lsr
    lsr
    lsr
    clc
    adc #deft(TILE_TEXT_UINUMBER_BASE,5) | T_HIGHP
    sta.l vqueueMiniOps.1.data,X
    lda.w playerData.bombs
    and #$000F
    clc
    adc #deft(TILE_TEXT_UINUMBER_BASE,5) | T_HIGHP
    sta.l vqueueMiniOps.2.data,X
    rtl

UI.update_key_display:
    rep #$30 ; 16B AXY
    ; inc vqueue
    lda.w vqueueNumMiniOps
    asl
    asl
    tax
    inc.w vqueueNumMiniOps
    inc.w vqueueNumMiniOps
    ; first, determine offset
    lda #BG1_TILE_BASE_ADDR + $86
    sta.l vqueueMiniOps.1.vramAddr,X
    lda #BG1_TILE_BASE_ADDR + $87
    sta.l vqueueMiniOps.2.vramAddr,X
    ; now, determine character
    lda.w playerData.keys
    and #$00F0
    lsr
    lsr
    lsr
    lsr
    clc
    adc #deft(TILE_TEXT_UINUMBER_BASE,5) | T_HIGHP
    sta.l vqueueMiniOps.1.data,X
    lda.w playerData.keys
    and #$000F
    clc
    adc #deft(TILE_TEXT_UINUMBER_BASE,5) | T_HIGHP
    sta.l vqueueMiniOps.2.data,X
    rtl

_PlayerHealthTileValueTable:
    .dw deft($00, 0) | T_HIGHP ; null
    .dw deft($32, 5) | T_HIGHP ; red empty
    .dw deft($33, 5) | T_HIGHP ; red half
    .dw deft($30, 5) | T_HIGHP ; red full
    .dw deft($31, 6) | T_HIGHP ; spirit half
    .dw deft($30, 6) | T_HIGHP ; spirit full
    .dw deft($00, 5) | T_HIGHP ; eternal

; Render heart at slot Y
UI.update_single_heart:
    rep #$30 ; 16B AXY
    ; Init vqueue
    lda.w vqueueNumMiniOps
    asl
    asl
    tax
    inc.w vqueueNumMiniOps
    ; first, determine offset
    tya
    and #$0007 ; 8 per line
    sta.b $00
    tya
    and #$00F8 ; x8
    asl      ; x16
    asl      ; x32
    ora.b $00 ; X|Y
    sta.b $00
    clc
    adc #BG1_TILE_BASE_ADDR + 8 + 64
    sta.l vqueueMiniOps.1.vramAddr,X
    ; now, determine character
    lda.w playerData.healthSlots,Y
    and #$00FF
    asl
    phx
    tax
    lda.l _PlayerHealthTileValueTable,X
    plx
    sta.l vqueueMiniOps.1.data,X
    rtl

UI.update_all_hearts:
    sep #$30
    ldy #HEALTHSLOT_COUNT-1
    @loop:
        phy
        php
        jsl UI.update_single_heart
        plp
        ply
    dey
    bpl @loop
    rtl

; Update the entire minimap
; NOTE: this requires blank to be enabled
; We assume that this will be performed during stage load.
; Just set numTilesToUpdate to $FF instead.
UpdateEntireMinimap:
    rep #$30 ; 16 bit AXY
    lda #$80
    sta.w VMAIN ; single increment, no mapping
    .REPT 5 INDEX i
        lda #BG1_TILE_BASE_ADDR + (i+2)*32 + 25
        sta.w VMADDR
        lda.b loadedRoomIndex
        and #$00FF
        .IF i == 0
            cmp #$20
            bcs +
                jsr _ClearMinimapLine
                jmp @skip_{i}
            +:
        .ELIF i == 1
            cmp #$10
            bcs +
                jsr _ClearMinimapLine
                jmp @skip_{i}
            +:
        .ELIF i == 3
            cmp #$E0
            bcc +
                jsr _ClearMinimapLine
                jmp @skip_{i}
            +:
        .ELIF i == 4
            cmp #$F0
            bcc +
                jsr _ClearMinimapLine
                jmp @skip_{i}
            +:
        .ENDIF
        clc
        adc #(i - 2) * MAP_MAX_WIDTH - 2
        tay
        jsr _UpdateMinimapLine
        @skip_{i}:
    .ENDR
    rts

_ClearMinimapLine:
    .ACCU 16
    .INDEX 16
    lda #deft($53, 6)
    .REPT 5 INDEX i
        sta.w VMDATA
        iny
    .ENDR
    rts

_UpdateMinimapLine:
    .ACCU 16
    .INDEX 16
    .REPT 5 INDEX i
        .IF i != 2
            lda.b loadedRoomIndex
            and #$0F
            .IF i == 0
                cmp #2
                bcs +
            .ELIF i == 1
                cmp #1
                bcs +
            .ELIF i == 3
                cmp #$0E
                bcc +
            .ELIF i == 4
                cmp #$0F
                bcc +
            .ENDIF
                lda #0
                jmp @store_{i}
            +:
        .ENDIF
        jsl Map.GetTileValue
        cmp #0
        bne +
            lda #deft($53, 6)
        +:
    @store_{i}:
        ora #T_HIGHP
        sta.w VMDATA
        iny
    .ENDR
    rts

; Get tile value for tile Y
Map.GetTileValue:
    .INDEX 16
    .ACCU 16
    lda.w mapTileTypeTable,Y
    and #$00FF
    asl
    tax
    lda.l MapTiles,X
    sta.b $00
    beq @empty_tile
; modify value by flags
    lda.w mapTileFlagsTable,Y
    bit #MAPTILE_COMPLETED
    beq +
        lda #$0010
        ora.b $00
        sta.b $00
    +:
    lda.w mapTileFlagsTable,Y
    bit #MAPTILE_HAS_PLAYER
    beq +
        lda #$0020
        ora.b $00
        sta.b $00
    +:
    ; hide undiscovered rooms
    lda.w mapTileFlagsTable,Y
    bit #MAPTILE_DISCOVERED
    bne @tile_discovered
        ; always hide secret rooms
        lda.w mapTileTypeTable,Y
        and #$00FF
        cmp #ROOMTYPE_SECRET
        beq @no_map_no_compass
            lda.w playerData.playerItemStackNumber + ITEMID_MAP
            and #$00FF
            beq @no_map
                ; has map
                lda.w playerData.playerItemStackNumber + ITEMID_COMPASS
                and #$00FF
                bne @tile_discovered ; has map has compass - discover all rooms
                    ; has map no compass - all undiscovered rooms appear as normal rooms
                    lda #deft($08, 6) | T_HIGHP
                    sta.b $00
                    jmp @tile_discovered
            @no_map:
                ; no map
                lda.w playerData.playerItemStackNumber + ITEMID_COMPASS
                and #$00FF
                beq @no_map_no_compass ; no map no compass - don't discover any rooms
                    ; no map has compass - discover non-normal rooms
                    lda.w mapTileTypeTable,Y
                    and #$00FF
                    cmp #ROOMTYPE_NORMAL+1
                    bcs @tile_discovered
        @no_map_no_compass:
        lda #$0000
        and.b $00
        sta.b $00
    @tile_discovered:
@empty_tile:
; set value
    lda.b $00
    rtl

; Update minimap slot
; Args:
;    slot dw $04,S
UpdateMinimapSlot:
    ; screw it, just update the whole minimap now
    sep #$20
    lda #$FF
    sta.w numTilesToUpdate
    rtl

UI.update_charge_display:
    .DEFINE ITEMPTR $00
    .DEFINE MAX_CHARGE $02
    .DEFINE USAGE_CHARGE $04
    .DEFINE PLAYER_CHARGE $06
    .DEFINE TILE $08
    .DEFINE SLOTS $0A
    .DEFINE TILEI_LAST $0C
    .DEFINE IS_FULL $0E
    .DEFINE TMP_CHARGE $10
    .DEFINE TMP_PLAYER_CHARGE $12
    ; get item info
    rep #$30
    lda.w playerData.current_active_item
    and #$00FF
    asl
    tax
    lda.l Item.items,X
    tax
    stx.b ITEMPTR
    lda.l bankaddr(Item.items) | itemdef_t.charge_max,X
    and #$00FF
    sta.b MAX_CHARGE
    lda.l bankaddr(Item.items) | itemdef_t.charge_use,X
    and #$00FF
    sta.b USAGE_CHARGE
    ; get and increment miniop address
    lda.w vqueueNumMiniOps
    pha
    clc
    adc #32
    sta.w vqueueNumMiniOps
    pla
    asl
    asl
    tax
    ; clear and set addresses
    .REPT 8 INDEX iy
        .REPT 4 INDEX ix
            lda #BG1_TILE_BASE_ADDR + ix+2 + (iy+5)*32
            sta.l vqueueMiniOps.{iy*4 + ix + 1}.vramAddr,X
            lda #0
            sta.l vqueueMiniOps.{iy*4 + ix + 1}.data,X
        .ENDR
    .ENDR
    ; get player charge
    lda.w playerData.current_active_charge
    and #$00FF
    sta.b PLAYER_CHARGE
    ; iterate charges
    .REPT 4 INDEX ix
        ; determine charge amounts for this specific battery slot
        lda.b MAX_CHARGE
        beql @end_write
        bmil @end_write
        lda.b PLAYER_CHARGE
        .AMINU P_DIR USAGE_CHARGE
        sta.b TMP_PLAYER_CHARGE
        lda.b MAX_CHARGE
        .AMINU P_DIR USAGE_CHARGE
        sta.b TMP_CHARGE
        inc A
        lsr
        dec A
        sta.b TILEI_LAST
        lda.b TMP_PLAYER_CHARGE
        ldy #0
        cmp.b USAGE_CHARGE
        bcc +
            ldy #1
        +:
        sty.b IS_FULL
        .REPT 8 INDEX iy
            .IF iy == 0
                lda #%00000100
            .ELSE
                lda #%00000000
            .ENDIF
            sta.b TILE
            ; check if last tile
            lda.b TILEI_LAST
            cmp #iy
            blsul @end_slot_{ix}
            bne @not_last_slot_{ix}_{iy}
                lda #%00000010
                tsb.b TILE
            @not_last_slot_{ix}_{iy}:
            ; check FULL flag
            lda.b IS_FULL
            beq @not_full_{ix}_{iy}
                lda #%00011000
                tsb.b TILE
                jmp @was_full_{ix}_{iy}
            @not_full_{ix}_{iy}:
                ; determine C if not full
                lda.b TMP_PLAYER_CHARGE
                .AMINU P_IMM 2
                asl
                asl
                asl
                tsb.b TILE
            @was_full_{ix}_{iy}:
            ; determine M
            lda.b TMP_CHARGE
            .AMINU P_IMM 2
            asl
            asl
            asl
            asl
            asl
            tsb.b TILE
            phx
            ldx.b TILE
            lda.l BatteryTileMap,X
            plx
            sta.l vqueueMiniOps.{iy*4 + ix + 1}.data,X
            ; subtract
            dec.b TMP_PLAYER_CHARGE
            dec.b TMP_PLAYER_CHARGE
            bpl +
                stz.b TMP_PLAYER_CHARGE
            +:
            dec.b TMP_CHARGE
            dec.b TMP_CHARGE
            bpl +
                stz.b TMP_CHARGE
            +:
        .ENDR
        @end_slot_{ix}:
        lda.b MAX_CHARGE
        sec
        sbc.b USAGE_CHARGE
        bpl +
            lda #0
        +:
        sta.b MAX_CHARGE
        lda.b PLAYER_CHARGE
        sec
        sbc.b USAGE_CHARGE
        bpl +
            lda #0
        +:
        sta.b PLAYER_CHARGE
    .ENDR
@end_write:
; and now, upload item sprite depending on if we have enough charge
    rep #$30
    ldx.b ITEMPTR
    pea BG1_CHARACTER_BASE_ADDR + $0EE0
    pea 2
    stz.b IS_FULL
    sep #$20
    lda.w playerData.current_active_charge
    cmp.b USAGE_CHARGE
    bcc +
        inc.b IS_FULL
    +:
    lda #$7F
    pha
    rep #$20
    lda.l bankaddr(Item.items) | itemdef_t.sprite_index,X
    and #$00FF
    ldy.b IS_FULL
    beq @not_charge
    @has_charge:
        clc
        adc #sprite.item_active.1 - 1
        sta.b $02
        asl
        asl
        adc.b $02
        tax
        lda.l SpriteDefs + entityspriteinfo_t.sprite_addr,X
        sta.b $02
        lda.l SpriteDefs + entityspriteinfo_t.sprite_addr + 2,X
        sta.b $04
        jmp @end_charge
    @not_charge:
        clc
        adc #sprite.item.1 - 1
        sta.b $02
        asl
        asl
        adc.b $02
        tax
        lda.l SpriteDefs + entityspriteinfo_t.sprite_addr,X
        sta.b $02
        lda.l SpriteDefs + entityspriteinfo_t.sprite_addr + 2,X
        sta.b $04
    @end_charge:
    ; decompress sprite into vqueueBin
    ldx.b $02
    lda.w vqueueBinOffset
    sec
    sbc #$80
    sta.w vqueueBinOffset
    tay
    lda.b $04
    and #$00FF
    ora #$7F00
    jsl Decompress.Lz4FromROM
    ; queue sprite upload
    ldx.w vqueueBinOffset
    phx
    ldy #4
    lda #3
    jsl SpritePaletteOpaqueify_7F
    .REPT 2 INDEX i
        jsl CopySpriteVQueue
        .IF i == 0
            rep #$20
            lda $01,S
            clc
            adc #spritesize(4, 2)
            sta $01,S
            lda $06,S
            clc
            adc #$0100
            sta $06,S
        .ENDIF
    .ENDR
    rep #$20
    pla
    pla
    pla
    sep #$20
    pla
    rtl

; Battery tile map.
; Indexed by: 0MMCCFL0
; MM - max (for this tile) (0, 1, 2)
; CC - charge (0, 1, 2, FULL)
; F  - first
; L  - last
; invalid tiles are shown as coins for easy debugging
BatteryTileMap:
    ; 0 / 0
    .dw $11, $11, $11, $11
    ; 1 / 0 (invalid)
    .dw 1, 1, 1, 1
    ; 2 / 0 (invalid)
    .dw 1, 1, 1, 1
    ; FULL / 0
    .dw 1, 1, 1, 1
    ; 0 / 1
    .dw 1
    .dw deft($54, 6) ; last
    .dw 1
    .dw deft($44, 6) ; single
    ; 1 / 1
    .dw 1
    .dw deft($56, 6) ; last
    .dw 1
    .dw deft($46, 6) ; single
    ; 2 / 1 (invalid)
    .dw 1, 1, 1, 1
    ; FULL / 1
    .dw 1
    .dw deft($57, 6) ; last
    .dw 1
    .dw deft($47, 6) ; single
    ; 0 / 2
    .dw deft($24, 6) ; mid
    .dw deft($34, 6) ; last
    .dw deft($14, 6) ; first
    .dw deft($04, 6) ; single
    ; 1 / 2
    .dw deft($25, 6) ; mid
    .dw deft($35, 6) ; last
    .dw deft($15, 6) ; first
    .dw deft($05, 6) ; single
    ; 2 / 2
    .dw deft($26, 6) ; mid
    .dw deft($36, 6) ; last
    .dw deft($16, 6) ; first
    .dw deft($06, 6) ; single
    ; FULL / 2
    .dw deft($27, 6) ; mid
    .dw deft($37, 6) ; last
    .dw deft($17, 6) ; first
    .dw deft($07, 6) ; single

.ENDS