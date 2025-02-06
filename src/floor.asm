.include "base.inc"

.DEFINE FLOOR_FLAG_NEXT $01
.DEFINE FLOOR_FLAG_FADEIN $02
.DEFINE FLOOR_FLAG_FADEIN2 $04

.BANK hirombankid(FLOOR_DEFINITION_BASE) SLOT "ROM"
.SECTION "Floor Code" FREE

; Generate and enter floor proper
_Floor_Begin:
    jsl BeginMapGeneration
    sep #$30 ; 8 bit AXY
    lda #1
    sta.l needResetEntireGround
    lda #0
    pha
    jsl LoadRoomSlotIntoLevel
    sep #$30 ; 8 bit AXY
    pla
    jsl PlayerEnterFloor
    rts

; Initialize floor data on game load
Floor_Init:
    rep #$30
    lda #0
    sta.w floorFlags
    sta.w currentFloorIndex
    asl
    tax
    lda.l FloorDefinitions,X
    sta.w currentFloorPointer
    jsr _Floor_Begin
    jsr _Floor_Update_Graphics
    rtl

Floor_Next:
    rep #$30
    lda #FLOOR_FLAG_NEXT
    tsb.w floorFlags
    rtl

_Transition_In:
    sep #$30
    wai
    .REPT 16 INDEX  i
    lda #(i * 16) | $0F
    sta.w MOSAIC
    lda #(15-i)
    sta.w roomBrightness
    sta.w INIDISP
    wai
    wai
    wai
    .ENDR
    rts

_Transition_Out:
    sep #$30
    wai
    .REPT 16 INDEX  i
    lda #((15 - i) * 16) | $0F
    sta.w MOSAIC
    lda #i
    sta.w roomBrightness
    sta.w INIDISP
    wai
    wai
    wai
    .ENDR
    rts

Floor_Tick:
    rep #$30
    lda #FLOOR_FLAG_FADEIN2
    trb.w floorFlags
    beq @no_fadein2
        jsr _Transition_Out
@no_fadein2:
    rep #$30
    lda #FLOOR_FLAG_FADEIN
    trb.w floorFlags
    beq @no_fadein
        lda #FLOOR_FLAG_FADEIN2
        tsb.w floorFlags
        jsr _Floor_Update_Graphics
@no_fadein:
    rep #$30
    lda #FLOOR_FLAG_NEXT
    trb.w floorFlags
    beq @no_level_transition
        jsr _Transition_In
        rep #$30
        lda.w currentFloorIndex
        inc A
        sta.w currentFloorIndex
        asl
        tax
        lda.l FloorDefinitions,X
        sta.w currentFloorPointer
        jsr _Floor_Begin
        rep #$30
        lda #FLOOR_FLAG_FADEIN
        tsb.w floorFlags
@no_level_transition:
    rtl

_Floor_Update_Graphics:
    ; f-blank
    sep #$20
    lda #$80
    sta.w INIDISP
    ; get chapter pointer
    rep #$30
    ldx.w currentFloorPointer
    lda.l FLOOR_DEFINITION_BASE + floordefinition_t.chapter,X
    and #$00FF
    asl
    tax
    lda.l ChapterDefinitions,X
    tax
    stx.b $00
    ; upload palettes
    .REPT 4 INDEX i
        lda.l FLOOR_DEFINITION_BASE + chapterdefinition_t.palettes + (i*3) + 2,X
        and #$00FF
        ora #$1000 * i
        pha
        lda.l FLOOR_DEFINITION_BASE + chapterdefinition_t.palettes + (i*3),X
        pha
        jsl CopyPalette
        rep #$30
        pla
        pla
        ldx.b $00
    .ENDR
    ; upload tiles
    pea BG2_CHARACTER_BASE_ADDR
    pea 256
    sep #$20
    lda.l FLOOR_DEFINITION_BASE + chapterdefinition_t.tiledata + 2,X
    pha
    rep #$20
    lda.l FLOOR_DEFINITION_BASE + chapterdefinition_t.tiledata,X
    pha
    jsl CopySprite
    sep #$20
    pla
    rep #$30
    pla
    pla
    pla
    ; Set background color
    sep #$20 ; 8 bit A
    stz CGADDR
    lda #%0
    sta CGDATA
    lda #%0
    sta CGDATA
    ; disable f-blank
    sep #$20
    lda #$00
    sta.w INIDISP
    rts

; DATA

; Basement
.DSTRUCT ChapterDefinition_Basement INSTANCEOF chapterdefinition_t VALUES
    name: .db "The Basement\0"
    palettes:
        .dl palettes.basement_ground1
        .dl 0
        .dl palettes.basement
        .dl palettes.basement2
    tiledata: .dl spritedata.basement
    ground: .dl spritedata.basement_ground_base
    groundPalette: .dw 0 * $0400
.ENDST

; Caves
.DSTRUCT ChapterDefinition_Caves INSTANCEOF chapterdefinition_t VALUES
    name: .db "The Caves\0"
    palettes:
        .dl palettes.stage_caves_ground
        .dl 0
        .dl palettes.stage_caves1
        .dl palettes.stage_caves2
    tiledata: .dl spritedata.stage_caves
    ground: .dl spritedata.stage_caves_ground
    groundPalette: .dw 2 * $0400
.ENDST

ChapterDefinitions:
    .dw ChapterDefinition_Basement
    .dw ChapterDefinition_Caves

; Basement I
.DSTRUCT FloorDefinition_Basement1 INSTANCEOF floordefinition_t VALUES
    chapter: .db 0
    number: .db 1
    size: .db 7
    roomgen: .dw ROOMGEN_DEFAULT
.ENDST

; Basement II
.DSTRUCT FloorDefinition_Basement2 INSTANCEOF floordefinition_t VALUES
    chapter: .db 0
    number: .db 2
    size: .db 8
    roomgen: .dw ROOMGEN_DEFAULT
.ENDST

; Caves I
.DSTRUCT FloorDefinition_Caves1 INSTANCEOF floordefinition_t VALUES
    chapter: .db 1
    number: .db 1
    size: .db 9
    roomgen: .dw ROOMGEN_DEFAULT
.ENDST

; Caves II
.DSTRUCT FloorDefinition_Caves2 INSTANCEOF floordefinition_t VALUES
    chapter: .db 1
    number: .db 2
    size: .db 10
    roomgen: .dw ROOMGEN_DEFAULT
.ENDST

FloorDefinitions:
    .dw FloorDefinition_Basement1
    .dw FloorDefinition_Basement2
    .dw FloorDefinition_Caves1
    .dw FloorDefinition_Caves2

.ENDS