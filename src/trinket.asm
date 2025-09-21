.include "base.inc"

.BANK $02 SLOT "ROM"
.SECTION "Entity Trinket" SUPERFREE

.DSTRUCT Trinket.definitions.null INSTANCEOF trinketdef_t VALUES
    sprite_index: .db 0
    palette_ptr: .dw loword(palettes.ui_light)
    palette_depth: .db 4
    flags: .db 0
    on_pickup: .dw _pickup_empty
    name: .ASCSTR "null", 0
    tagline: .ASCSTR "", 0
.ENDST

.DSTRUCT Trinket.definitions.penny_on_a_string INSTANCEOF trinketdef_t VALUES
    sprite_index: .db 1
    palette_ptr: .dw loword(palettes.trinket.penny_on_a_string)
    palette_depth: .db 8
    flags: .db 0
    on_pickup: .dw _pickup_empty
    name: .ASCSTR "Penny on a String", 0
    tagline: .ASCSTR "Money back guarantee", 0
.ENDST

Trinket.trinkets:
    .dw Trinket.definitions.null
    .dw Trinket.definitions.penny_on_a_string

_pickup_empty:
    rts

; Clear trinket data
Trinket.Init:
    rep #$20
    lda #0
    sta.w playerData.trinketslot
    .REPT 16 INDEX i
        sta.w playerData.trinketeffects+i*2
    .ENDR
    rtl

; Add effect 'A' to trinket effect list
Trinket.AddEffect:
    sep #$30
    pha
    ; Y = A // 8
    lsr
    lsr
    lsr
    tay
    ; X = A % 8
    pla
    and #$07
    tax
    ; A = 1 << X
    lda.l ShiftLeftTable8,X
    ; trinketeffects[A // 8] |= (1 << (A % 8))
    ora.w playerData.trinketeffects,Y
    sta.w playerData.trinketeffects,Y
    ; set flags
    rep #$20
    lda #PLAYER_FLAG_INVALIDATE_ITEM_CACHE
    tsb.w playerData.flags
    rtl

; Remove effect 'A' form trinket effect list
Trinket.RemoveEffect:
    sep #$30
    pha
    ; Y = A // 8
    lsr
    lsr
    lsr
    tay
    ; X = A % 8
    pla
    and #$07
    tax
    ; A = 1 << X
    lda.l ShiftLeftTable8,X
    ; trinketeffects[A // 8] &= ~(1 << (A % 8))
    eor #$FF
    and.w playerData.trinketeffects,Y
    sta.w playerData.trinketeffects,Y
    ; set flags
    rep #$20
    lda #PLAYER_FLAG_INVALIDATE_ITEM_CACHE
    tsb.w playerData.flags
    rtl

; Check if trinket 'A' exists in trinket effect list.
; If player has the trinket effect, returns a number greater than 0.
Trinket.Contains:
    sep #$30
    pha
    ; Y = A // 8
    lsr
    lsr
    lsr
    tay
    ; X = A % 8
    pla
    and #$07
    tax
    ; A = 1 << X
    lda.l ShiftLeftTable8,X
    ; A = trinketeffects[A // 8] & (1 << (A % 8))
    and.w playerData.trinketeffects,Y
    rtl

; Pick up a trinket of type 'A'
Trinket.Pickup:
    ; for now, only one trinket slot. We'll worry about purse later.
    sep #$30
    pha
    ; If player already has trinket, then do nothing. This prevents
    ; confusion from the player holding multiple trinkets.
    jsl Trinket.Contains
    cmp #0
    beq +
        pla
        rtl
    +:
    ; drop current trinket, if applicable
    lda.w playerData.trinketslot+0
    beq @skip_drop
        ; remove trinket from effect table
        jsl Trinket.RemoveEffect
        ; spawn pickup
        rep #$30
        lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_VARIANT_TRINKET)
        jsl entity_create_and_init
        sep #$30
        lda.w playerData.trinketslot+0
        sta.w entity_timer,Y
        rep #$30
        lda.w player_posx
        sta.w entity_posx,Y
        lda.w player_posy
        sta.w entity_posy,Y
@skip_drop:
    ; set current trinket
    sep #$30
    pla
    sta.w playerData.trinketslot+0
    ; Add trinket to effect table
    jsl Trinket.AddEffect
Trinket.update_display:
; there are two trinket display slots - just do first for now
    rep #$30
    ; get address of trinket definition
    lda.w playerData.trinketslot+0
    and #$00FF
    asl
    tax
    lda.l Trinket.trinkets,X
    tax
    ; get sprite address
    lda.l bankaddr(Trinket.trinkets) | trinketdef_t.sprite_index,X
    and #$00FF
    clc
    adc #sprite.trinkets_small.1 - 1
    sta.b $02
    asl
    asl
    clc
    adc.b $02
    tax
    lda.l SpriteDefs + entityspriteinfo_t.sprite_addr,X
    sta.b $02
    lda.l SpriteDefs + entityspriteinfo_t.sprite_addr + 2,X
    sta.b $04
    ; decompress sprite
    ldx.b $02
    lda.w vqueueBinOffset
    sec
    sbc #$80
    sta.w vqueueBinOffset
    tay ; decompress into vqueueBin
    lda.b $04
    and #$00FF
    ora #$7F00
    jsl Decompress.Lz4FromROM
    ; queue sprite upload
    pea BG1_CHARACTER_BASE_ADDR + $0C40
    pea 2
    sep #$20
    lda #$7F
    pha
    rep #$20
    lda.w vqueueBinOffset
    pha
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
; now do second trinket slot
    rep #$30
    ; get address of trinket definition
    lda.w playerData.trinketslot+1
    and #$00FF
    asl
    tax
    lda.l Trinket.trinkets,X
    tax
    ; get sprite address
    lda.l bankaddr(Trinket.trinkets) | trinketdef_t.sprite_index,X
    and #$00FF
    clc
    adc #sprite.trinkets_small.1 - 1
    sta.b $02
    asl
    asl
    clc
    adc.b $02
    tax
    lda.l SpriteDefs + entityspriteinfo_t.sprite_addr,X
    sta.b $02
    lda.l SpriteDefs + entityspriteinfo_t.sprite_addr + 2,X
    sta.b $04
    ; decompress sprite
    ldx.b $02
    lda.w vqueueBinOffset
    sec
    sbc #$80
    sta.w vqueueBinOffset
    tay ; decompress into vqueueBin
    lda.b $04
    and #$00FF
    ora #$7F00
    jsl Decompress.Lz4FromROM
    ; queue sprite upload
    pea BG1_CHARACTER_BASE_ADDR + $0C60
    pea 2
    sep #$20
    lda #$7F
    pha
    rep #$20
    lda.w vqueueBinOffset
    pha
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
; copy palettes into hdma buffers
    ; trinket 1
    rep #$30
    lda.w playerData.trinketslot+0
    and #$00FF
    asl
    tax
    lda.l Trinket.trinkets,X
    tax
    lda.l bankaddr(Trinket.trinkets) | trinketdef_t.palette_ptr,X
    tax
    .REPT 16 INDEX i
        lda.l bankaddr(palettes.default) + i*2,X
        sta.l hdmaPaletteBuffer_trinket1.l + i*5 + hdmapalettebufferentry_t.color
    .ENDR
    ; trinket 2
    lda.w playerData.trinketslot+1
    and #$00FF
    asl
    tax
    lda.l Trinket.trinkets,X
    tax
    lda.l bankaddr(Trinket.trinkets) | trinketdef_t.palette_ptr,X
    tax
    .REPT 16 INDEX i
        lda.l bankaddr(palettes.default) + i*2,X
        sta.l hdmaPaletteBuffer_trinket2.l + i*5 + hdmapalettebufferentry_t.color
    .ENDR
    rtl

.ENDS