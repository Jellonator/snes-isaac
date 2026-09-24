.include "base.inc"

.BANK $02 SLOT "ROM"
.SECTION "Entity Trapdoor" SUPERFREE

true_entity_trapdoor_tick:
    ; rtl
    .ForceSetAX 16, 16
    lda #0
    ; tile ID
    lda #$20A4
    .OX_Get
    sta.w objectData.1.tileid,X
    ; X position
    .ForceSetA 8
    lda.w entity_posx + 1,Y
    sta.w objectData.1.pos_x,X
    ; Y position
    lda.w entity_posy + 1,Y
    sta.w objectData.1.pos_y,X
    sta.w loword(entity_ysort),Y
    .OX_Next_S
    .SetAX 8, 16
    lda.w entity_timer,Y
    beq +
        dec A
        sta.w entity_timer,Y
        rtl
    +:
    ; collision detection
    .EntityEasySetBox 16 16
    .EntityEasyCheckNoPlayerCollision_Center @no_player_col, 8, 10
        ; TODO: handle next floor
        jsl Floor.Next
    @no_player_col:
    rtl

.ENDS

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Trapdoor Hooks" FREE

entity_trapdoor_init:
    .SoftSetA 16
    .SoftSetX 16
    .ForceSetA 8
    lda #60
    sta.w entity_timer,Y
    .ForceSetA 16
    rts

entity_trapdoor_free:
    .SoftSetA 16
    .SoftSetX 16
    rts

entity_trapdoor_tick:
    .SoftSetA 16
    .SoftSetX 16
    pla
    phk
    pha
    jml true_entity_trapdoor_tick

.ENDS
