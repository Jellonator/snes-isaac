.include "base.inc"

.DEFINE _zombie_gfxptr.1 loword(entity_char_custom.1)
.DEFINE _zombie_gfxptr.2 loword(entity_char_custom.2)
.DEFINE _zombie_body_frame loword(entity_char_custom.16)
.DEFINE _zombie_body_flags loword(entity_char_custom.16+1)
.DEFINE _zombie_walk_frame loword(entity_char_custom.15)
.DEFINE _zombie_walk_timer loword(entity_char_custom.14)

.DEFINE ZOMBIE_ACCEL 4
.DEFINE WALK_TIMER_FRAME_DELAY $0400

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
; get movement target
    jsl Entity.Enemy.PathfindTargetPlayer
    sep #$30
    lda.b entityTargetFound
    beq @no_target
        ldx.b entityTargetAngle
        lda.l SinTable8,X
        .Convert8To16_SIGNED 0, 0
        ; .ShiftRight_SIGN 1, 0
        sta.b $02
        sep #$20
        lda.l CosTable8,X
        .Convert8To16_SIGNED 0, 0
        ; .ShiftRight_SIGN 1, 0
        sta.b $00
        jmp @end_target
    @no_target:
        rep #$20
        stz.b $00
        stz.b $02
    @end_target:
; adjust and apply velocity
    ; X
    lda.w entity_velocx,Y
    .CMPS_BEGIN P_DIR, $00
        ; velocx < target
        lda.w entity_velocx,Y
        clc
        adc #ZOMBIE_ACCEL
        .AMIN P_DIR, $00
        .AMAX P_IMM, -$0040
    .CMPS_GREATER
        ; velocx > target
        lda.w entity_velocx,Y
        sec
        sbc #ZOMBIE_ACCEL
        .AMAX P_DIR, $00
        .AMIN P_IMM, $0040
    .CMPS_EQUAL
        lda.b $00
    .CMPS_END
    sta.w entity_velocx,Y
    clc
    adc.w entity_posx,Y
    sta.w entity_posx,Y
    ; Y
    lda.w entity_velocy,Y
    .CMPS_BEGIN P_DIR, $02
        ; velocx < target
        lda.w entity_velocy,Y
        clc
        adc #ZOMBIE_ACCEL
        .AMIN P_DIR, $02
        .AMAX P_IMM, -$0040
    .CMPS_GREATER
        ; velocx > target
        lda.w entity_velocy,Y
        sec
        sbc #ZOMBIE_ACCEL
        .AMAX P_DIR, $02
        .AMIN P_IMM, $0040
    .CMPS_EQUAL
        lda.b $02
    .CMPS_END
    sta.w entity_velocy,Y
    clc
    adc.w entity_posy,Y
    sta.w entity_posy,Y
; update animation
    jsr _zombie_update_walk_animation
; load & set gfx
    rep #$20
    lda #0
    sep #$30
    ; determine palette
    ldx #%00100001
    lda.w loword(entity_damageflash),Y
    beq +
        dec A
        sta.w loword(entity_damageflash),Y
        ldx #%00101111
    +:
    txa
    ora.w _zombie_body_flags,Y
    sta.b $02
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

; animation functions

_zombie_update_walk_animation:
    rep #$20
    lda.w entity_velocy,Y
    .ABS_A16_POSTLOAD
    sta.b $00
    lda.w entity_velocx,Y
    .ABS_A16_POSTLOAD
    asl
    cmp.b $00
    bcsl @horizontal
;vertical:
    lda.w entity_velocy,Y
    beq @not_moving
    bpl @vertical_down
;vertical_up:
    .NEG_A16
    clc
    adc.w _zombie_walk_timer,Y
    cmp #WALK_TIMER_FRAME_DELAY
    bcs @vertical_up_next_frame
    sta.w _zombie_walk_timer,Y
    lda #%00100001
    sta.w _zombie_body_flags,Y
    sep #$20
    lda.w _zombie_walk_frame,Y
    jmp _zombie_set_walk_frame
@vertical_up_next_frame:
    .ACCU 16
    lda #0
    sta.w _zombie_walk_timer,Y
    sep #$20
    lda.w _zombie_walk_frame,Y
    dec A
    bpl +
        lda #5
    +:
    sta.w _zombie_walk_frame,Y
    lda #%00100001
    sta.w _zombie_body_flags,Y
    lda.w _zombie_walk_frame,Y
    jmp _zombie_set_walk_frame
@vertical_down:
    .ACCU 16
    clc
    adc.w _zombie_walk_timer,Y
    cmp #WALK_TIMER_FRAME_DELAY
    bcs @vertical_down_next_frame
    sta.w _zombie_walk_timer,Y
    sep #$20
    lda #%00100001
    sta.w _zombie_body_flags,Y
    lda.w _zombie_walk_frame,Y
    jmp _zombie_set_walk_frame
@vertical_down_next_frame:
    .ACCU 16
    lda #0
    sta.w _zombie_walk_timer,Y
    sep #$20
    lda.w _zombie_walk_frame,Y
    inc A
    cmp #6
    bcc +
        lda #0
    +:
    sta.w _zombie_walk_frame,Y
    lda #%00100001
    sta.w _zombie_body_flags,Y
    lda.w _zombie_walk_frame,Y
    jmp _zombie_set_walk_frame
@not_moving:
    .ACCU 16
    lda #0
    sta.w _zombie_walk_timer,Y
    sep #$20
    sta.w _zombie_walk_frame,Y
    lda #%00100001
    sta.w _zombie_body_flags,Y
    lda # 0
    jmp _zombie_set_walk_frame
@horizontal:
    .ACCU 16
    lda.w entity_velocx,Y
    beq @not_moving
    .ABS_A16_POSTLOAD
    clc
    adc.w _zombie_walk_timer,Y
    cmp #WALK_TIMER_FRAME_DELAY
    bcs @horizontal_next_frame
    sta.w _zombie_walk_timer,Y
    jmp @horizontal_update_frame
@horizontal_next_frame:
    .ACCU 16
    lda #0
    sta.w _zombie_walk_timer,Y
    sep #$20
    lda.w _zombie_walk_frame,Y
    inc A
    cmp #6
    bcc +
        lda #0
    +:
    sta.w _zombie_walk_frame,Y
@horizontal_update_frame:
    sep #$20
    lda #%00100001
    xba
    lda.w entity_velocx+1,Y
    bpl +
        lda #%01100001
        xba
    +:
    xba
    sta.w _zombie_body_flags,Y
    lda.w _zombie_walk_frame,Y
    clc
    adc #8
    jmp _zombie_set_walk_frame
    rts

_zombie_set_walk_frame:
    .ACCU 8
    ; don't upload frame if it is active
    cmp.w _zombie_body_frame,Y
    bne +
        rts
    +:
    sta.w _zombie_body_frame,Y
    ; upload frame
    phy
    php
    pea bankbyte(spritedata.enemy_zombie) * $0101
    rep #$20
    and #$00FF
    xba
    lsr
    clc
    adc #loword(spritedata.enemy_zombie)
    pha
    clc
    adc #64
    pha
    lda.w _zombie_gfxptr.2,Y
    and #$00FF
    tax
    jsl spriteman_write_sprite_to_raw_slot
    rep #$20
    pla
    pla
    pla
    plp
    ply
    rts

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
    lda #0
    sta.w _zombie_walk_timer,Y
    sep #$20
    sta.w _zombie_walk_frame,Y
    sta.w _zombie_body_flags,Y
    lda #$FF
    sta.w _zombie_body_frame,Y
    ; call init function
    rep #$30
    jsl EntityZombie.init
    ; get raw slots
    sep #$30
    .spriteman_get_raw_slot_lite
    sta.w _zombie_gfxptr.1,Y
    .spriteman_get_raw_slot_lite
    sta.w _zombie_gfxptr.2,Y
    rts

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
    ; set box
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