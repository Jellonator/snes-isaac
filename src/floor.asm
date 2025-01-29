.include "base.inc"

.DEFINE FLOOR_FLAG_NEXT $01
.DEFINE FLOOR_FLAG_FADEIN $02
.DEFINE FLOOR_FLAG_FADEIN2 $04

.BANK $01 SLOT "ROM"
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
    rts

; Initialize floor data on game load
Floor_Init:
    rep #$30
    lda #0
    sta.w floorFlags
    sta.w currentFloorIndex
    tax
    lda.l FloorDefinitions,X
    sta.w currentFloorPointer
    jsr _Floor_Begin
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
        tax
        lda.l FloorDefinitions,X
        sta.w currentFloorPointer
        jsr _Floor_Begin
        rep #$30
        lda #FLOOR_FLAG_FADEIN
        tsb.w floorFlags
@no_level_transition:
    rtl

; DATA

.DSTRUCT ChapterDefinition_Basement INSTANCEOF chapterdefinition_t VALUES
    name: .db "The Basement\0"
.ENDST

ChapterDefinitions:
    .dw ChapterDefinition_Basement ; 0

.DSTRUCT FloorDefinition_Basement1 INSTANCEOF floordefinition_t VALUES
    chapter: .db 0
    number: .db 1
    size: .db 7
    roomgen: .dw ROOMGEN_DEFAULT
.ENDST

.DSTRUCT FloorDefinition_Basement2 INSTANCEOF floordefinition_t VALUES
    chapter: .db 0
    number: .db 2
    size: .db 8
    roomgen: .dw ROOMGEN_DEFAULT
.ENDST

FloorDefinitions:
    .dw FloorDefinition_Basement1
    .dw FloorDefinition_Basement2

.ENDS