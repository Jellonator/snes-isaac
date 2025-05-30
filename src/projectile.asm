.include "base.inc"

.MACRO .PositionToIndex_A
    xba
    and #$00F0
    lsr
    lsr
    lsr
    lsr
.ENDM

.MACRO .IndexToPosition_A
    asl
    asl
    asl
    asl
    xba
.ENDM

.BANK ROMBANK_ENTITYCODE SLOT "ROM"
.SECTION "ProjectileHooks" FREE

projectile_entity_init:
    ; creator is responsible for setting position, velocity
    rep #$20
    lda #0
    sta.w entity_mask,Y
    ; sta.w entity_signal,Y; implicit by 16b store
    sta.w entity_state,Y
    ; sta.w entity_timer,Y; implicit by 16b store
    sta.w loword(projectile_flags),Y
    sta.w loword(projectile_velocz),Y
    lda #$0800
    sta.w loword(projectile_height),Y
    rts

projectile_entity_tick:
    jsl projectile_tick__
    rts

projectile_entity_free:
    rts

.ENDS

.BANK $01 SLOT "ROM"
.SECTION "Projectilecode" FREE

_big_projectile_update_sprite:
    .INDEX 16
    .ACCU 8
    asl
    clc
    adc #$30 - 16
    sta.w objectData.1.tileid,Y
    lda.w entity_posx+1,X
    sbc #3 ; we know that carry should always be clear, so just substract 3
    sta.w objectData.1.pos_x,Y
    lda.w entity_posy+1,X
    ; sec
    sbc.w loword(projectile_height)+1,X
    sbc #4
    sta.w objectData.1.pos_y,Y
    lda #%00100000
    sta.w objectData.1.flags,Y
    ; lda.w projectile_type,X
    ; bpl +
    ;     ; different gfx for enemy projectile
    ;     lda #%00101110
    ;     sta.w objectData.1.flags,Y
    ; +:
    phx
    php
    rep #$30
    .SetCurrentObjectS
    plp
    .INDEX 16
    .ACCU 8
    plx
    ldy.w objectIndex
    iny
    iny
    iny
    iny
    ; special handling for projectile shadows
    sty.w objectIndex
    cpy.w objectIndexShadow
    bcs @skipShadow
        ldy.w objectIndexShadow
        dey
        dey
        dey
        dey
        sty.w objectIndexShadow
        lda.w entity_posy+1,X
        sta.w objectData.1.pos_y,Y
        lda.w entity_posx+1,X
        sta.w objectData.1.pos_x,Y
        lda #$A1
        sta.w objectData.1.tileid,Y
        lda #%00011000
        sta.w objectData.1.flags,Y
    @skipShadow:
    rts

_projectile_update_sprite:
    ; send to OAM
    sep #$20 ; 8A, 16XY
    rep #$10
    tyx
    ldy.w objectIndex
    lda.w loword(projectile_size),X
    cmp #8
    bcc +
        jmp _big_projectile_update_sprite
    +:
    clc
    adc #$20
    sta.w objectData.1.tileid,Y
    lda.w entity_posx+1,X
    sta.w objectData.1.pos_x,Y
    lda.w entity_posy+1,X
    sec
    sbc.w loword(projectile_height)+1,X
    sta.w objectData.1.pos_y,Y
    lda #%00100000
    sta.w objectData.1.flags,Y
    ; lda.w projectile_type,X
    ; bpl +
    ;     ; different gfx for enemy projectile
    ;     lda #%00101110
    ;     sta.w objectData.1.flags,Y
    ; +:
    iny
    iny
    iny
    iny
    ; special handling for projectile shadows
    sty.w objectIndex
    cpy.w objectIndexShadow
    bcs @skipShadow
        ldy.w objectIndexShadow
        dey
        dey
        dey
        dey
        sty.w objectIndexShadow
        lda.w entity_posy+1,X
        sta.w objectData.1.pos_y,Y
        lda.w entity_posx+1,X
        sta.w objectData.1.pos_x,Y
        lda #$A1
        sta.w objectData.1.tileid,Y
        lda #%00011000
        sta.w objectData.1.flags,Y
    @skipShadow:
    rts

_projectile_tile_do_nothing:
    .INDEX 16
    .ACCU 16
    rts

_projectile_tile_poop:
    .INDEX 16
    .ACCU 16
    sep #$20 ; 8 bit A
    lda [currentRoomTileVariantTableAddress],Y
    cmp #2
    beq @removeTile
    inc A
    sta [currentRoomTileVariantTableAddress],Y
    rep #$20 ; 16 bit A
    jsl HandleTileChanged
    rts
@removeTile:
    sep #$20 ; 8 bit A
    lda #0
    sta [currentRoomTileVariantTableAddress],Y
    lda #BLOCK_REGULAR
    sta [currentRoomTileTypeTableAddress],Y
    rep #$20 ; 16 bit A
    jsl HandleTileChanged
    ; put splotch
    sep #$20 ; 8 bit A
    tyx
    lda.l RoomTileToXTable,X
    asl
    asl
    asl
    asl
    clc
    adc #32
    sta.b $07
    lda.l RoomTileToYTable,X
    asl
    asl
    asl
    asl
    clc
    adc #64
    sta.b $06
    phy
    php
    jsl Splat.poop1
    ; maybe spawn a pickup
    jsl RoomRand_Update8
    sep #$30
    cmp #26
    bcs @no_spawn
    cmp #7
    bcc @spawn_heart
    ;spawn_coin:
        rep #$30
        lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_COIN)
        jsl entity_create ; Y = entity ID
        sep #$30
        lda $02,S
        tax
        lda.l RoomTileToXTable,X
        .MultiplyStatic 16
        clc
        adc #ROOM_LEFT
        sta.w entity_box_x1,Y
        lda.l RoomTileToYTable,X
        .MultiplyStatic 16
        clc
        adc #ROOM_TOP
        sta.w entity_box_y1,Y
        jsl entity_init
        jmp @no_spawn
    @spawn_heart:
        rep #$30
        lda #entityvariant(ENTITY_TYPE_PICKUP, ENTITY_PICKUP_RANDOM_HEART)
        jsl entity_create ; Y = entity ID
        sep #$30
        lda $02,S
        tax
        lda.l RoomTileToXTable,X
        .MultiplyStatic 16
        clc
        adc #ROOM_LEFT
        sta.w entity_box_x1,Y
        lda.l RoomTileToYTable,X
        .MultiplyStatic 16
        clc
        adc #ROOM_TOP
        sta.w entity_box_y1,Y
        jsl entity_init
@no_spawn:
    plp
    ply
    rts

ProjectileTileHandlerTable:
.REPT 256 INDEX i
    .IF i == BLOCK_POOP
        .dw _projectile_tile_poop
    .ELSE
        .dw _projectile_tile_do_nothing
    .ENDIF
.ENDR

ProjectileTileHandleTrampoline:
    jsr (ProjectileTileHandlerTable,X)
    rtl

.define PROJECTILE_TMP_IDX $20
.define PROJECTILE_TMP_POSX $01
.define PROJECTILE_TMP_POSY $02
.define PROJECTILE_TMP_VAL $12
_projectile_delete:
    rep #$30
    ldy.b PROJECTILE_TMP_IDX
    jml entity_free ; tail call optimization

.MACRO ._tear_size_damage_macro ARGS size, damage
    .ACCU 16
    cmp #damage + 1
    bcs +
        sep #$20
        lda #size
        sta.l projectile_size,X
        rtl
    +:
    .ACCU 16
.ENDM

Projectile.SetSizeFromDamage:
    rep #$30
    lda.w projectile_damage,X
    ._tear_size_damage_macro  0,  1 ;   2x2
    ._tear_size_damage_macro  1,  2 ;   3x3
    ._tear_size_damage_macro  2,  4 ;   4x4
    ._tear_size_damage_macro  3,  7 ;   5x5
    ._tear_size_damage_macro  4, 12 ;   6x6
    ._tear_size_damage_macro  5, 16 ;   7x7
    ._tear_size_damage_macro  6, 24 ;   8x8
    ._tear_size_damage_macro  7, 36 ;   9x9 (technically 8x8 but more filled out)
    ._tear_size_damage_macro  8, 52 ; 10x10
    ._tear_size_damage_macro  9, 72 ; 12x12
    ._tear_size_damage_macro 10, 96 ; 14x14
    sep #$20
    lda #11
    sta.l projectile_size,X
    rtl

projectile_tick__:
    .INDEX 16
    .ACCU 16
    rep #$30
    sty.b PROJECTILE_TMP_IDX
; Handle lifetime (drop when life ends)
    lda.w projectile_lifetime,Y
    bne @noFall
        lda.w loword(projectile_height),Y
        sec
        sbc #256
        sta.w loword(projectile_height),Y
        bpl @lifeEnd
        jmp _projectile_delete
    @noFall:
    dec A
    sta.w projectile_lifetime,Y
    @lifeEnd:
; Apply speed to position
    ; X
    lda.w entity_posx,Y
    clc
    adc.w entity_velocx,Y
    sta.w entity_posx,Y
    ; store X index
    xba
    sep #$20
    clc
    adc #$04
    sta.b PROJECTILE_TMP_POSX
    lsr
    lsr
    lsr
    lsr
    sta.b PROJECTILE_TMP_VAL
    ; Y
    rep #$20
    lda.w entity_posy,Y
    clc
    adc.w entity_velocy,Y
    sta.w entity_posy,Y
    xba
    sep #$30
    clc
    adc #$04
    sta.b PROJECTILE_TMP_POSY
    and #$F0
    ora.b PROJECTILE_TMP_VAL
    sta.b PROJECTILE_TMP_VAL
; Homing
    lda.w loword(projectile_flags),Y
    bit #PROJECTILE_FLAG_HOMING
    beql @no_homing
        ; get nearest entity
        sep #$30
        lda #0
        xba
        ldx.b PROJECTILE_TMP_VAL
        lda.w pathfind_nearest_enemy_id,X
        beql @no_homing
; Calculate direction to this enemy
; Credit for method of calculating the angle:
; https://codebase64.org/doku.php?id=base:8bit_atan2_8-bit_angle
; A couple of modifications were made for accuracy
        ; get dx
        tax
        stz.b tempDP
        lda.w entity_box_x1,X
        clc
        adc.w entity_box_x2,X
        ror
        sec
        sbc.b PROJECTILE_TMP_POSX
        bcs +
            eor #$FF
        +:
        sta.b tempDP+2
        rol.b tempDP
        ror
        cmp #40
        bcsl @no_homing
        ; get dy
        lda.w loword(entity_ysort),X
        sec
        sbc.b PROJECTILE_TMP_POSY
        bcs +
            eor #$FF
        +:
        sta.b tempDP+4
        rol.b tempDP
        ror
        cmp #40
        bcsl @no_homing
        ; calculate log(x) - log(y)
        ldx.b tempDP+2
        lda.l Log2Mult32Table8,X
        ldx.b tempDP+4
        sec
        sbc.l Log2Mult32Table8,X
        bcc +
            eor #$FF
        +:
        tax
        rol.b tempDP
        ; calculate atan
        lda.l AtanLogTable8,X
        ldx.b tempDP
        eor.l AtanOctantAdjustTable8,X
        adc #$80
        tax
        ; slow velocity
        rep #$30
        lda.w entity_velocx,Y
        .NEG_A16
        .ShiftRight_SIGN 5, 1
        clc
        adc.w entity_velocx,Y
        sta.w entity_velocx,Y
        lda.w entity_velocy,Y
        .NEG_A16
        .ShiftRight_SIGN 5, 1
        clc
        adc.w entity_velocy,Y
        sta.w entity_velocy,Y
        lda #0
        sep #$30
        ; add velocity
        lda.l CosTable8,X
        .Convert8To16_SIGNED 0, 1
        .ShiftRight_SIGN 3, 1
        clc
        adc.w entity_velocx,Y
        sta.w entity_velocx,Y
        lda #0
        sep #$30
        lda.l SinTable8,X
        .Convert8To16_SIGNED 0, 1
        .ShiftRight_SIGN 3, 1
        clc
        adc.w entity_velocy,Y
        sta.w entity_velocy,Y
@no_homing:
    sep #$30
; Check tile
    ldx.b PROJECTILE_TMP_VAL
    lda.l GameTileToRoomTileIndexTable,X
    cmp #97
    bcc +
        jmp _projectile_delete ; remove if oob
    +:
    tay
    ; intermission: skip collision checking if too damn high up
    ldx.b PROJECTILE_TMP_IDX
    lda.w loword(projectile_height)+1,X
    cmp #25
    bcc +
        jmp @skipCollisionHandler
    +:
    ; continuing on...
    lda [currentRoomTileTypeTableAddress],Y
    bpl @skipTileHandler
    rep #$30
    and #$00FF
    asl
    tax
    jsr (ProjectileTileHandlerTable,X)
    jmp _projectile_delete
@skipTileHandler:
; Check collisions
    sep #$30
    ; set detection mask
    ; ldx.b PROJECTILE_TMP_IDX
    lda #ENTITY_MASK_TEAR
    sta.b $00
    lda.w projectile_type,X
    bpl +
        ; enemy projectile: change mask
        lda #ENTITY_MASK_PROJECTILE
        sta.b $00
    +:
    jsl GetEntityCollisionAt ; Y = new entity
    cpy #0
    beq @skipCollisionHandler
        ; found object:
        ; update veloc
        rep #$30
        ldx.b PROJECTILE_TMP_IDX
        ; lda.w entity_velocx,X
        ; .ShiftRight_SIGN 1, FALSE
        lda.w entity_velocx,X
        .ShiftRight_SIGN 3, FALSE
        clc
        adc.w entity_velocx,Y
        sta.w entity_velocx,Y
        ; lda.w entity_velocy,X
        ; .ShiftRight_SIGN 1, FALSE
        lda.w entity_velocy,X
        .ShiftRight_SIGN 3, FALSE
        clc
        adc.w entity_velocy,Y
        sta.w entity_velocy,Y
        ; reduce HP
        lda.w entity_health,Y
        sta.b $00
        sec
        sbc.w projectile_damage,X
        sta.w entity_health,Y
        ; signal damaged
        sep #$20
        php
        lda.w entity_signal,Y
        ora #ENTITY_SIGNAL_DAMAGE
        ; signal killed if health < 0
        plp
        bcs +
            ora #ENTITY_SIGNAL_KILL
        +:
        sta.w entity_signal,Y
        lda #ENTITY_FLASH_TIME
        sta.w loword(entity_damageflash),Y
        rep #$30
        ; if damage < targethp or !(flags&POLYPHEMUS): kill
        lda.w projectile_damage,X
        cmp.b $00
        bcc @hit_and_kill
        beq @hit_and_kill
        lda.w loword(projectile_flags),X
        and #PROJECTILE_FLAG_POLYPHEMUS
        beq @hit_and_kill
        ; reduce damage
        lda.w projectile_damage,X
        sec
        sbc.b $00
        sta.w projectile_damage,X
        jsl Projectile.SetSizeFromDamage
        jmp @skipCollisionHandler
    @hit_and_kill:
        jmp _projectile_delete
@skipCollisionHandler:
    rep #$10
    ldy.b PROJECTILE_TMP_IDX
    sep #$20
    lda.w entity_box_x1,Y
    clc
    adc #8
    sta.w entity_box_x2,Y
    lda.w entity_box_y1,Y
    clc
    adc #4
    sta.w loword(entity_ysort),Y
    adc #4
    sta.w entity_box_y2,Y
    jsr _projectile_update_sprite
    rtl

; Create a new projectile, whose position and velocity inherits from entity [Y]
; Returns projectile ID in [X]
; Make sure to set `lifetime`, `flags`, `damage`, `size`, and `type` afterwards.
Projectile.CreateAndInheritVelocity:
; Create
    rep #$20
    sep #$10
    lda #ENTITY_TYPE_PROJECTILE
    phy
    jsl entity_create_and_init
    sep #$30
    tyx
    ply ; Y = this, X = projectile
; projectile->position = this->center - vec2(2, 2)
    ; X coordinate
    lda.w entity_box_x1,Y
    clc
    adc.w entity_box_x2,Y
    ror
    sec
    sbc #4
    sta.w entity_box_x1,X
    ; Y coordinate
    lda.w loword(entity_ysort),Y
    sec
    sbc #5
    sta.w entity_box_y1,X
; projectile->velocity = this->velocity
    rep #$20
    lda.w entity_velocx,Y
    sta.w entity_velocx,X
    lda.w entity_velocy,Y
    sta.w entity_velocy,X
    rtl

; Updates projectile in [X] to add velocity based on input.
; $00: u16 - SPEED
Projectile.AddInputVelocity:
    .ACCU 16
; velocity - check direction
    lda.w joy1held
    bit #JOY_Y
    bne @tear_left
    bit #JOY_A
    bne @tear_right
    bit #JOY_B
    bnel @tear_down
;tear_up:
    lda.w entity_velocy,X
    .ShiftRight_SIGN 1, FALSE
    .AMIN P_IMM, $0100 * 0.25
    .AMAX P_IMM, -$0100
    sec
    sbc.b $00
    sta.w entity_velocy,X
    jmp @tear_velocity_end
@tear_left:
    lda.w entity_velocx,X
    .ShiftRight_SIGN 1, FALSE
    .AMIN P_IMM, $0100 * 0.25
    .AMAX P_IMM, -$0100
    sec
    sbc.b $00
    sta.w entity_velocx,X
    jmp @tear_velocity_end
@tear_right:
    lda.w entity_velocx,X
    .ShiftRight_SIGN 1, FALSE
    .AMAX P_IMM, -$0100 * 0.25
    .AMIN P_IMM, $0100
    clc
    adc.b $00
    sta.w entity_velocx,X
    jmp @tear_velocity_end
@tear_down:
    lda.w entity_velocy,X
    .ShiftRight_SIGN 1, FALSE
    .AMAX P_IMM, -$0100 * 0.25
    .AMIN P_IMM, $0100
    clc
    adc.b $00
    sta.w entity_velocy,X
@tear_velocity_end:
    rtl

; Updates projectile in [Y] to add velocity based on target direction.
; $00: u8 - SPEED (Q7.1)
; entityTargetAngle: u8 - ANGLE
Projectile.AddAngleVelocity:
    .ACCU 16
    .INDEX 8
    ldx.b entityTargetAngle
    stz.b $30
    sep #$20
; A = LENGTH
    lda.b $00
    sta.l MULTU_A
; B = sin(θ)
    lda.l SinTable8,X
    bpl +
        sta.b $30 ; $30: sin(θ)
        .NEG_A8
    +:
    sta.l MULTU_B
    nop ; 2 cycles
; veloc.y = sign(sin(θ)) * length·sin(θ)
    rep #$20 ; 3 cycles
    lda.l MULTU_RESULT ; 4 cycles before load
    bit.b $30-1
    bpl +
        .NEG_A16
    +:
    sta.w entity_velocy,Y
; B = cos(θ)
    sep #$20
    lda.l CosTable8,X
    bpl +
        sta.b $31 ; $31: cos(θ)
        .NEG_A8
    +:
    sta.l MULTU_B
    nop ; 2 cycles
; veloc.x = sign(cos(θ)) * cos(θ)
    rep #$20 ; 3 cycles
    lda.l MULTU_RESULT ; 4 cycles before load
    bit.b $31-1
    bpl +
        .NEG_A16
    +:
    sta.w entity_velocx,Y
; end
    rtl

.ENDS