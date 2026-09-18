.include "base.inc"
.include "palettes.inc"

.BANK hirombankid(FLOOR_DEFINITION_BASE) SLOT "ROM"
.SECTION "Floor Code" FREE

; Generate and enter floor proper
; Args:
; $03,S room load context
_Floor_Begin:
    jsl MapGen.GenerateMap
    .ForceSetAX 8, 8
    ; reset ground
    lda #1
    sta.l needResetEntireGround
    ; reset devil deal flags
    lda.l floors_since_devil_deal
    inc A
    sta.l floors_since_devil_deal
    lda #0
    sta.l devil_deal_flags
    ; load room slot 0
    lda $03,S
    pha
    lda #0
    pha
    jsl LoadAndInitRoomSlotIntoLevel
    .ForceSetA 16
    pla
    ; init player
    jsl PlayerEnterFloor
    ; put overlay
    jsl Overlay.clear
    .ForceSetAX 16, 16
    lda.l currentFloorIndex
    asl
    tax
    lda.l FloorDefinitions,X
    clc
    adc #floordefinition_t.name
    tax
    phb
    .ChangeDataBank bankbyte(FloorDefinitions)
    jsl Overlay.putline
    plb
    rts

; Initialize floor data when beginning a new game
Floor.Init:
    .ForceSetA 8
    ; clear devil deal flags (base devil chance should be 100%)
    lda #3
    sta.l floors_since_devil_deal
    lda #0
    sta.l devil_deal_flags
    ; clear floor information
    .ForceSetAX 16, 16
    lda #0
    sta.w floorFlags
    sta.w currentFloorIndex
    asl
    tax
    lda.l FloorDefinitions,X
    sta.w currentFloorPointer
    ; initialize
    .ForceSetA 8
    lda #ROOM_LOAD_CONTEXT_GAMELOAD
    pha
    jsr _Floor_Begin
    .ForceSetA 8
    pla
    jsr _Floor_Update_Graphics
    rtl

; Initialize floor data when loading from a save file
Floor.InitPostLoad:
    .ForceSetAX 16, 16
    lda #0
    sta.w floorFlags
    jsr _Floor_Update_Graphics
    .ForceSetAX 8, 8
    lda #1
    sta.l needResetEntireGround
    jsl PlayerInitPostLoad
    rtl

Floor.Next:
    .ForceSetAX 16, 16
    lda #FLOOR_FLAG_NEXT
    tsb.w floorFlags
    rtl

Floor.Transition.In:
    .ForceSetAX 8, 8
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
    rtl

Floor.Transition.Out:
    .ForceSetAX 8, 8
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
    rtl

Floor.Tick:
    .ForceSetAX 16, 16
    lda #FLOOR_FLAG_FADEIN2
    trb.w floorFlags
    beq @no_fadein2
        jsl Floor.Transition.Out
@no_fadein2:
    .ForceSetAX 16, 16
    lda #FLOOR_FLAG_FADEIN
    trb.w floorFlags
    beq @no_fadein
        lda #FLOOR_FLAG_FADEIN2
        tsb.w floorFlags
        jsr _Floor_Update_Graphics
@no_fadein:
    .ForceSetAX 16, 16
    lda #FLOOR_FLAG_NEXT
    trb.w floorFlags
    beq @no_level_transition
        jsl Floor.Transition.In
        .ForceSetAX 16, 16
        lda.w currentFloorIndex
        inc A
        sta.w currentFloorIndex
        asl
        tax
        lda.l FloorDefinitions,X
        sta.w currentFloorPointer
        .ForceSetA 8
        lda #ROOM_LOAD_CONTEXT_FLOORBEGIN
        pha
        jsr _Floor_Begin
        .ForceSetA 8
        pla
        .ForceSetAX 16, 16
        lda #FLOOR_FLAG_FADEIN
        tsb.w floorFlags
@no_level_transition:
    rtl

_Floor_Update_Graphics:
    ; f-blank
    .ForceSetA 8
    lda #$80
    sta.w INIDISP
    ; get chapter pointer
    .ForceSetAX 16, 16
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
        pea 32
        lda.l FLOOR_DEFINITION_BASE + chapterdefinition_t.palettes + (i*3) + 2,X
        and #$00FF
        ora #PALETTE_TILESET.{i}
        pha
        lda.l FLOOR_DEFINITION_BASE + chapterdefinition_t.palettes + (i*3),X
        pha
        jsl CopyPalette
        .ForceSetAX 16, 16
        pla
        pla
        pla
        ldx.b $00
    .ENDR
    ; don't need to upload tiles here, this is performed by room
    ; set clear color
    .ForceSetA 8
    stz CGADDR
    lda #lobyte(CLEAR_COLOR)
    sta CGDATA
    lda #hibyte(CLEAR_COLOR)
    sta CGDATA
    ; disable f-blank
    .ForceSetA 8
    lda #$00
    sta.w INIDISP
    rts

; DATA

; TRUE 'CHAPTER' DEFINITIONS

; Basement
.DSTRUCT ChapterDefinition_Basement INSTANCEOF chapterdefinition_t VALUES
    name: .ASCSTR "The Basement\0"
    palettes:
        .dl palettes.basement_ground1
        .dl 0
        .dl palettes.basement
        .dl palettes.basement2
    tiledata: .dl spritedata.stage.basement
    ground: .dl spritedata.stage.basement_ground_base
    groundPalette: .dw 2 * $0400
    roompoolMain: .dw RoomPoolDefinitions@floor_basement
    roompoolBoss: .dw RoomPoolDefinitions@boss_basement
.ENDST

; Caves
.DSTRUCT ChapterDefinition_Caves INSTANCEOF chapterdefinition_t VALUES
    name: .ASCSTR "The Caves\0"
    palettes:
        .dl palettes.stage_caves_ground
        .dl 0
        .dl palettes.stage_caves1
        .dl palettes.stage_caves2
    tiledata: .dl spritedata.stage.caves
    ground: .dl spritedata.stage.caves_ground
    groundPalette: .dw 2 * $0400
    roompoolMain: .dw RoomPoolDefinitions@floor_basement
    roompoolBoss: .dw RoomPoolDefinitions@boss_basement
.ENDST

; PER-ROOM CHAPTERS (only used to define gfx for specific rooms)

.DSTRUCT ChapterDefinition_SecretRoom INSTANCEOF chapterdefinition_t VALUES
    name: .ASCSTR "Secret Room\0"
    palettes:
        .dl palettes.stage_secret_room_ground
        .dl 0
        .dl palettes.stage_secret_room1
        .dl palettes.stage_secret_room2
    tiledata: .dl spritedata.stage.secret_room
    ground: .dl spritedata.stage.basement_ground_base
    groundPalette: .dw 2 * $0400
.ENDST

.DSTRUCT ChapterDefinition_DevilRoom INSTANCEOF chapterdefinition_t VALUES
    name: .ASCSTR "Devil Room\0"
    palettes:
        .dl palettes.stage_devil_room_ground
        .dl 0
        .dl palettes.stage_devil_room1
        .dl palettes.stage_devil_room2
    tiledata: .dl spritedata.stage.secret_room
    ground: .dl spritedata.stage.basement_ground_base
    groundPalette: .dw 2 * $0400
.ENDST

ChapterDefinitions:
    .dw ChapterDefinition_Basement ; null chapter
    ; true chapters
    .dw ChapterDefinition_Basement
    .dw ChapterDefinition_Caves
    ; fake chapters
    .dw ChapterDefinition_SecretRoom
    .dw ChapterDefinition_DevilRoom

; FLOOR DEFINITIONS

; Basement I
.DSTRUCT FloorDefinition_Basement1 INSTANCEOF floordefinition_t VALUES
    name: .ASCSTR "The Basement \x80\0"
    chapter: .db CHAPTER_BASEMENT
    size: .db 9
    roomgen: .dw ROOMGEN_DEFAULT
.ENDST

; Basement II
.DSTRUCT FloorDefinition_Basement2 INSTANCEOF floordefinition_t VALUES
    name: .ASCSTR "The Basement \x80\x80\0"
    chapter: .db CHAPTER_BASEMENT
    size: .db 10
    roomgen: .dw ROOMGEN_DEFAULT
.ENDST

; Caves I
.DSTRUCT FloorDefinition_Caves1 INSTANCEOF floordefinition_t VALUES
    name: .ASCSTR "The Caves \x80\0"
    chapter: .db CHAPTER_CAVES
    size: .db 11
    roomgen: .dw ROOMGEN_DEFAULT
.ENDST

; Caves II
.DSTRUCT FloorDefinition_Caves2 INSTANCEOF floordefinition_t VALUES
    name: .ASCSTR "The Caves \x80\x80\0"
    chapter: .db CHAPTER_CAVES
    size: .db 12
    roomgen: .dw ROOMGEN_DEFAULT
.ENDST

FloorDefinitions:
    .dw FloorDefinition_Basement1
    .dw FloorDefinition_Basement2
    .dw FloorDefinition_Caves1
    .dw FloorDefinition_Caves2

.ENDS