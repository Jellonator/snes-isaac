.include "base.inc"

.DEFINE _zombie_gfxptr.1 loword(entity_char_custom.1)
.DEFINE _zombie_gfxptr.2 loword(entity_char_custom.2)

.BANK $02 SLOT "ROM"
.SECTION "Entity Enemy Zombie Extra" SUPERFREE

; DEFAULT

_entity_zombie_default_init:
    .ACCU 16
    .INDEX 16
    rtl

_entity_zombie_default_tick:
    .ACCU 16
    .INDEX 16
; move
    jsl Entity.Enemy.PathfindTargetPlayer
    sep #$30
    lda.b entityTargetFound
    beq @no_target
        ldx.b entityTargetAngle
        lda.l SinTable8,X
        .Convert8To16_SIGNED 0, 0
        .ShiftRight_SIGN 1, 0
        clc
        adc.w entity_posy,Y
        sta.w entity_posy,Y
        sep #$20
        lda.l CosTable8,X
        .Convert8To16_SIGNED 0, 0
        .ShiftRight_SIGN 1, 0
        clc
        adc.w entity_posx,Y
        sta.w entity_posx,Y
    @no_target:
    rep #$20
; load & set gfx
    lda #0
    sep #$20
    ; determine palette
    ldx #%00100001
    lda.w loword(entity_damageflash),Y
    beq +
        dec A
        sta.w loword(entity_damageflash),Y
        ldx #%00101111
    +:
    stx.b $02
    ; get tile IDs
    ldx.w _zombie_gfxptr.1,Y
    lda.l SpriteSlotIndexTable,X
    sta.b $00
    ldx.w _zombie_gfxptr.2,Y
    lda.l SpriteSlotIndexTable,X
    sta.b $01
    ; write data
    ldx.w objectIndex
    lda.b $01
    sta.w objectData.2.tileid,X
    lda.w entity_posx + 1,Y
    sta.w objectData.1.pos_x,X
    sta.w objectData.2.pos_x,X
    lda.w entity_posy + 1,Y
    sta.w objectData.2.pos_y,X
    sec
    sbc #10
    sta.w objectData.1.pos_y,X
    lda.b $02
    sta.w objectData.1.flags,X
    sta.w objectData.2.flags,X
    lda.b $00
    sta.w objectData.1.tileid,X
    ; inc object index
    rep #$30
    phy
    .SetCurrentObjectS_Inc
    .SetCurrentObjectS_Inc
    ply
    rtl

_entity_zombie_default_free:
    .ACCU 16
    .INDEX 16
    rtl

; HEADLESS

_entity_zombie_headless_init:
    .ACCU 16
    .INDEX 16
    rtl

_entity_zombie_headless_tick:
    .ACCU 16
    .INDEX 16
; load & set gfx
    lda #0
    sep #$20
    ; determine palette
    ldx #%00100001
    lda.w loword(entity_damageflash),Y
    beq +
        dec A
        sta.w loword(entity_damageflash),Y
        ldx #%00101111
    +:
    stx.b $02
    ; get tile IDs
    ldx.w _zombie_gfxptr.1,Y
    lda.l SpriteSlotIndexTable,X
    sta.b $00
    ldx.w _zombie_gfxptr.2,Y
    lda.l SpriteSlotIndexTable,X
    sta.b $01
    ; write data
    ldx.w objectIndex
    lda.b $00
    sta.w objectData.1.tileid,X
    lda.w entity_posx + 1,Y
    sta.w objectData.1.pos_x,X
    lda.w entity_posy + 1,Y
    sta.w objectData.1.pos_y,X
    lda.b $02
    sta.w objectData.1.flags,X
    ; inc object index
    rep #$30
    phy
    .SetCurrentObjectS_Inc
    ply
    rtl

_entity_zombie_headless_free:
    .ACCU 16
    .INDEX 16
    rtl

; TABLES

EntityZombie.HealthTable:
    .dw 20 ; base
    .dw 12 ; headless

EntityZombie.NextVariantTable:
    .db ENTITY_ZOMBIE_HEADLESS
    .db $FF

EntityZombie.InitTable:
    .dw _entity_zombie_default_init
    .dw _entity_zombie_headless_init

EntityZombie.TickTable:
    .dw _entity_zombie_default_tick
    .dw _entity_zombie_headless_tick

EntityZombie.FreeTable:
    .dw _entity_zombie_default_free
    .dw _entity_zombie_headless_free

; variant dispatch functions

EntityZombie.init:
    .ACCU 16
    .INDEX 16
    lda.w entity_variant,Y
    and #$00FF
    asl
    tax
    jmp (EntityZombie.InitTable,X)

EntityZombie.tick:
    .ACCU 16
    .INDEX 16
    lda.w entity_variant,Y
    and #$00FF
    asl
    tax
    jmp (EntityZombie.TickTable,X)

EntityZombie.free:
    .ACCU 16
    .INDEX 16
    lda.w entity_variant,Y
    and #$00FF
    asl
    tax
    jmp (EntityZombie.FreeTable,X)

.ENDS

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "Entity Enemy Zombie" FREE

.DEFINE BASE_HEALTH_MAIN 20
.DEFINE BASE_HEALTH_BODY 12

entity_zombie_init:
    .ACCU 16
    .INDEX 16
    inc.w currentRoomEnemyCount
    ; default info
    lda.w entity_variant,Y
    and #$00FF
    asl
    tax
    lda.l EntityZombie.HealthTable
    sta.w entity_health,Y
    ; call init function
    jsl EntityZombie.init
    ; get raw slots
    sep #$30
    .spriteman_get_raw_slot_lite
    sta.w _zombie_gfxptr.1,Y
    .spriteman_get_raw_slot_lite
    sta.w _zombie_gfxptr.2,Y
    ; ; load frame 1
    ; lda #sprite.enemy.zombie.0
    ; phy
    ; jsl spriteman_new_sprite_ref
    ; rep #$30
    ; ply
    ; txa
    ; sta.w _zombie_gfxptr.1,Y
    ; ; load frame 2
    ; lda #sprite.enemy.zombie.1
    ; phy
    ; jsl spriteman_new_sprite_ref
    ; rep #$30
    ; ply
    ; txa
    ; sta.w _zombie_gfxptr.2,Y
    ; end
    rts

.DefinePathSpeedTable "_e_zombie_speedtable", 128, 1
.DEFINE ZOMBIE_ACCEL 4

entity_zombie_tick:
    .ACCU 16
    .INDEX 16
; call tick function
    jsl EntityZombie.tick
; check signal
    sep #$30 ; 8B AXY
    lda #ENTITY_SIGNAL_KILL
    and.w entity_signal,Y
    beq @not_kill
        ; put blood splatter
        phy
        jsl EntityPutSplatter
        sep #$30
        ply
        ; check variant ($FF indicates true kill)
        ldx.w entity_variant,Y
        lda.l EntityZombie.NextVariantTable,X
        cmp #$FF
        bne @not_headless
            ; We have perished
            jsl entity_free
            rts
        @not_headless:
        ; replace with new variant
        xba
        lda #ENTITY_TYPE_ENEMY_ZOMBIE
        rep #$30
        jsl entity_replace
    @not_kill:
; move
;     sep #$30
;     lda.w entity_posx+1,Y
;     adc #8
;     lsr
;     lsr
;     lsr
;     lsr
;     sta.b $00
;     lda.w entity_posy+1,Y
;     adc #8
;     and #$F0
;     ora.b $00
;     tax
;     lda.w pathfind_player_data,X
;     rep #$30
;     and #$00FF
;     asl
;     tax
;     ; X
;     lda.w entity_velocx,Y
;     .CMPS_BEGIN P_LONG_X, _e_zombie_speedtable_X
;         ; velocx < target
;         lda.w entity_velocx,Y
;         clc
;         adc #ZOMBIE_ACCEL
;         .AMIN P_LONG_X, _e_zombie_speedtable_X
;         .AMAX P_IMM, -$0040
;     .CMPS_GREATER
;         ; velocx > target
;         lda.w entity_velocx,Y
;         sec
;         sbc #ZOMBIE_ACCEL
;         .AMAX P_LONG_X, _e_zombie_speedtable_X
;         .AMIN P_IMM, $0040
;     .CMPS_EQUAL
;         .AMAX P_IMM, -$0100
;         .AMIN P_IMM, $0100
;     .CMPS_END
;     sta.w entity_velocx,Y
;     clc
;     adc.w entity_posx,Y
;     sta.w entity_posx,Y
;     ; Y
;     lda.w entity_velocy,Y
;     .CMPS_BEGIN P_LONG_X, _e_zombie_speedtable_Y
;         ; velocx < target
;         lda.w entity_velocy,Y
;         clc
;         adc #ZOMBIE_ACCEL
;         .AMIN P_LONG_X, _e_zombie_speedtable_Y
;         .AMAX P_IMM, -$0040
;     .CMPS_GREATER
;         ; velocx > target
;         lda.w entity_velocy,Y
;         sec
;         sbc #ZOMBIE_ACCEL
;         .AMAX P_LONG_X, _e_zombie_speedtable_Y
;         .AMIN P_IMM, $0040
;     .CMPS_EQUAL
;         .AMAX P_IMM, -$0100
;         .AMIN P_IMM, $0100
;     .CMPS_END
;     sta.w entity_velocy,Y
;     clc
;     adc.w entity_posy,Y
;     sta.w entity_posy,Y
; ; load & set gfx
;     rep #$30
;     lda #0
;     sep #$20

;     ldx #%00100001
;     lda.w loword(entity_damageflash),Y
;     beq +
;         dec A
;         sta.w loword(entity_damageflash),Y
;         ldx #%00101111
;     +:
;     stx.b $02

;     ldx.w _zombie_gfxptr.1,Y
;     lda.w loword(spriteTableValue + spritetab_t.spritemem),X
;     tax
;     lda.l SpriteSlotIndexTable,X
;     sta.b $00

;     ldx.w _zombie_gfxptr.2,Y
;     lda.w loword(spriteTableValue + spritetab_t.spritemem),X
;     tax
;     lda.l SpriteSlotIndexTable,X
;     sta.b $01
    
;     lda.w entity_variant,Y
;     beq @headless
;         ldx.w objectIndex
;         lda.b $01
;         sta.w objectData.2.tileid,X
;         lda.w entity_posx + 1,Y
;         sta.w objectData.1.pos_x,X
;         sta.w objectData.2.pos_x,X
;         lda.w entity_posy + 1,Y
;         sta.w objectData.2.pos_y,X
;         sec
;         sbc #10
;         sta.w objectData.1.pos_y,X
;         lda.b $02
;         sta.w objectData.1.flags,X
;         sta.w objectData.2.flags,X
;         lda.b $00
;         sta.w objectData.1.tileid,X
;         bra +
;     @headless:
;         ldx.w objectIndex
;         lda.b $01
;         sta.w objectData.1.tileid,X
;         lda.w entity_posx + 1,Y
;         sta.w objectData.1.pos_x,X
;         lda.w entity_posy + 1,Y
;         sta.w objectData.1.pos_y,X
;         lda.b $02
;         sta.w objectData.1.flags,X
;     +
    ; add to partition
    sep #$30
    lda.w entity_box_x1,Y
    clc
    adc #16
    sta.w entity_box_x2,Y
    lda.w entity_box_y1,Y
    clc
    adc #8
    sta.w loword(entity_ysort),Y
    adc #8
    sta.w entity_box_y2,Y
    ; set some flags
    lda #ENTITY_MASKSET_ENEMY
    sta.w entity_mask,Y
    lda #0
    sta.w entity_signal,Y
    ; put shadow
    sep #$20
    rep #$10
    ldx.w objectIndex
    inx
    inx
    inx
    inx
    stx.w objectIndex
    pea $0405
    jsl EntityPutShadow
    plx
    ; Check collision with player
    jsl Entity.Enemy.TickContactDamage
    ; end
    rts

entity_zombie_free:
    .ACCU 16
    .INDEX 16
    dec.w currentRoomEnemyCount
    ; call free function
    jsl EntityZombie.free
    ; free sprites
    sep #$30
    lda.w _zombie_gfxptr.1,Y
    .spriteman_get_raw_slot_lite
    lda.w _zombie_gfxptr.2,Y
    .spriteman_get_raw_slot_lite
    rts

.ENDS