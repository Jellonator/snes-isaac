.include "base.inc"

; This bank is entirely relegated to entity functionality
.BANK $02 SLOT "ROM"
.SECTION "Entity" FREE

; For each of the following:
; * execution bank will be $02
; * Data bank will be $7E
; * Y will be entity index (16B)
; * A,X,Y will be 16B

; .REPT ACTIVE_ENTITY_MAX INDEX i

; .ENDR

_e_null:
    rts

_e_basic_fly_init:
    .ACCU 16
    .INDEX 16
    lda #sprite.enemy.attack_fly
    jsl spriteman_new_sprite_ref
    rep #$30
    lda $01,S
    .MultiplyStatic 2
    tay ; Y = 2*ptr
    txa
    sta.w entity_gfxptr,Y
    rts

_e_basic_fly_tick:
    .ACCU 16
    .INDEX 16
    tya
    .MultiplyStatic 2
    tay
    ldx.w entity_gfxptr,Y
    sep #$20 ; 8B A
    lda.w loword(spriteTableValue + spritetab_t.spritemem),X
    ldx.w objectIndex
    sta.w objectData.1.tileid,X
    lda.w entity_posx+1,Y
    sta.w objectData.1.pos_x,X
    lda.w entity_posy+1,Y
    sta.w objectData.1.pos_y,X
    lda #%00101001
    sta.w objectData.1.flags,X
    ; inc object index
    .SetCurrentObjectS
    .IncrementObjectIndex
    ; end
    rep #$30 ; 16B AXY
    rts

_e_basic_fly_free:
    .ACCU 16
    .INDEX 16
    tya
    asl
    tay
    lda.w entity_gfxptr,Y
    tax
    jsl spriteman_unref
    rts

; Create an entity of type A
; Returns reference as Y
entity_create:
    rep #$30 ; 16B XY
    sep #$20 ; 8B A
    ; first: find next free slot
    pha
    ldy #0
    lda.w entity_type,Y
    beq @end
@loop:
    iny
    lda.w entity_type,Y
    bne @loop
@end:
    ; init entity
    pla
    sta.w entity_type,Y
    rep #$20 ; 16B A
    .MultiplyStatic 8
    tax
    phy
    jsr (EntityDefinitions + entitytypeinfo_t.init_func,X)
    ply
    ; return
    rtl

; Free the given entity in reference Y
entity_free:
    phb
    .ChangeDataBank $7E
    lda.w entity_type,Y
    and.w #$00FF
    .MultiplyStatic 8
    tax
    phy
    jsr (EntityDefinitions + entitytypeinfo_t.free_func,X)
    ply
    ; set type to 0
    sep #$20
    lda #0
    sta.w entity_type,Y
    rep #$20
    ; return
    plb
    rtl

; Free all entities
entity_free_all:
    rep #$30 ; 16B AXY
    phb
    .ChangeDataBank $7E
    ldy.w #0
@loop:
    lda.w entity_type,Y
    and.w #$00FF
    beq @skip_ent ; skip if type == 0
    .MultiplyStatic 8
    tax
    phy
    jsr (EntityDefinitions + entitytypeinfo_t.free_func,X)
    ply
    ; set type to 0
    sep #$20
    lda #0
    sta.w entity_type,Y
    rep #$20
@skip_ent:
    iny
    cpy #ACTIVE_ENTITY_MAX
    bne @loop
@end:
    plb
    rtl

; Tick all entities
entity_tick_all:
    rep #$30 ; 16B AXY
    phb
    .ChangeDataBank $7E
    ldy.w #0
@loop:
    lda.w entity_type,Y
    and.w #$00FF
    beq @skip_ent ; skip if type == 0
    .MultiplyStatic 8
    tax
    phy
    jsr (EntityDefinitions + entitytypeinfo_t.tick_func,X)
    ply
@skip_ent:
    iny
    cpy #ACTIVE_ENTITY_MAX
    bne @loop
@end:
    plb
    rtl

EntityDefinitions:
    ; 0: Null
    .DSTRUCT @null INSTANCEOF entitytypeinfo_t VALUES
        init_func: .dw _e_null
        tick_func: .dw _e_null
        free_func: .dw _e_null
    .ENDST
    ; 1 : Attack fly
    .DSTRUCT @attack_fly INSTANCEOF entitytypeinfo_t VALUES
        init_func: .dw _e_basic_fly_init
        tick_func: .dw _e_basic_fly_tick
        free_func: .dw _e_basic_fly_free
    .ENDST
.ENDS
