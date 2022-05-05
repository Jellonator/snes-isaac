.include "Header.inc"
.include "Snes_Init.asm"
.include "layout.inc"
.include "util.inc"

.bank 0
.section "MainCode"

Start:
    sei ; Disabled interrupts
    Snes_Init
    ; Disable rendering temporarily
    sep #$20
    lda #%10000000
    sta $2100
    ; Set background color
    lda #%11100000
    sta $2122
    lda #%00000011
    sta $2122
    ; Set up tilemap mode
    lda #%00010001
    sta $2105
    lda #%01100000 ; tile data at $6000 (>>10)
    sta $2107
    lda #%00000100 ; tile character data at $4000 (>>12)
    sta $210B
    ; Set up sprite mode
    lda #%00000000
    sta $2101
    ; copy palette to CGRAM
    rep #$20 ; 16 bit A
    lda #32.w
    sta $4305 ; 32 bytes for palette
    lda #palettes@base.w
    sta $4302 ; source address
    sep #$20 ; 8 bit A
    lda #$01
    sta $4304 ; source bank
    lda #$80
    sta $2121 ; destination is first sprite palette
    stz $4300 ; write to PPU, absolute address, auto increment, 1 byte at a time
    lda #$22
    sta $4301 ; Write to CGRAM
    lda #$01
    sta $420B ; Begin transfer
    ; copy palette 2 to CGRAM
    rep #$20 ; 16 bit A
    lda #32.w
    sta $4305
    lda #palettes@basement.w
    sta $4302
    sep #$20 ; 8 bit A
    lda #$01
    sta $4304
    lda #$00
    sta $2121
    stz $4300
    lda #$22
    sta $4301
    lda #$01
    sta $420B
    ; copy sprite to VRAM
    rep #$20 ; 16 bit A
    lda #1024.w
    sta $4305
    lda #sprites@isaac.w
    sta $4302
    lda #$0000
    sta $2116
    sep #$20 ; 8 bit A
    lda #$01
    sta $4304
    lda #$80
    sta $2115
    lda #$01
    sta $4300 ; write to PPU, absolute address, auto increment, 2 bytes at a time
    lda #$18
    sta $4301
    lda #$01
    sta $420B
    ; copy tilemap to VRAM
    rep #$20 ; 16 bit A
    lda #8192.w
    sta $4305
    lda #sprites@basement.w
    sta $4302
    lda #$4000 ; put character data in $4000 of VRAM
    sta $2116
    sep #$20 ; 8 bit A
    lda #$01
    sta $4304
    lda #$80
    sta $2115
    lda #$01
    sta $4300
    lda #$18
    sta $4301
    lda #$01
    sta $420B

    ; Set up tilemap. First, write empty in all slots
    rep #$30 ; 16 bit X, Y, Z
    lda #$6000
    sta $2116
    lda #$0020
    ldx #$0000
tile_map_loop:
    sta $2118
    inx
    cpx #$0400 ; overwrite entire tile map
    bne tile_map_loop

    ; now, copy data for room layout
    ; room is 16x12, game is 32x32
    lda #$6000
    sta $2116
    ldx #$0000 ; rom tile data index
    ldy #$0000 ; vram tile data index
tile_data_loop:
    ; lda TileData.w,x
    ; sta $2118
    tya
    and #%0000000000111111
    cmp #32.w
    bcs tile_data_loop@copyzero
    lda TileData.w,x
    inx
    inx
    jmp @store
@copyzero:
    lda #$0020
@store:
    sta $2118
    iny
    iny
    cpy #$0300 ; 32 * 12 tiles
    bne tile_data_loop
    sep #$30 ; 8 bit X, Y, Z
    ; put a sprite in the center
    stz $2102
    stz $2103
    lda #120
    sta $2104
    lda #104
    sta $2104
    stz $2104
    stz $2104
    lda #120
    sta $2104
    lda #114
    sta $2104
    lda #$02
    sta $2104
    stz $2104
    ; show sprites and layer 1
    lda #$11
    sta $212c
    ; re-enable rendering
    lda #%00001111
    sta $2100
    cli ; Enable interrupts and joypad
    lda #$81
    sta $4200
    lda #$E0
    sta $210E
    lda #$FF
    sta $210E
    jsr PlayerInit
    jmp UpdateLoop

UpdateLoop:
    wai
    rep #$30 ; 16 bit AXY
    jsr PlayerUpdate
    jsr UpdateTears
    jmp UpdateLoop

VBlank:
    sep #$30 ; 16 bit AXY
    lda $4210

    jsr ReadInput

    stz $2102
    stz $2103
    lda player.pos.x + 1
    sta $2104
    lda player.pos.y + 1
    sec
    sbc #10
    sta $2104
    stz $2104
    lda #%00110000
    sta $2104
    lda player.pos.x + 1
    sta $2104
    lda player.pos.y + 1
    sta $2104
    lda #$02
    sta $2104
    lda #%00100000
    sta $2104

    sep #$10 ; 8 bit x
    ldx #2
    lda #240
clear_sprites_loop:
    stz $2104
    sta $2104
    stz $2104
    stz $2104
    INX
    cpx #128
    bne clear_sprites_loop
    lda #%00001010
    sta $2104

    jsr DrawTears
    sep #$30 ; 8 bit mode

    RTI

PlayerInit:
    rep #$20 ; 16 bit A
    lda #16
    sta player.stat_accel
    lda #256
    sta player.stat_speed
    lda #12
    sta player.stat_tear_delay
    lda #0
    sta player.speed.x
    lda #0
    sta player.speed.y
    lda #((32 + 6 * 16 - 8) * 256)
    sta player.pos.x
    lda #((64 + 4 * 16 - 8) * 256)
    sta player.pos.y
    sep #$20 ; 8 bit A
    stz tear_bytes_used
    stz tear_bytes_used+1
    rts

ReadInput:
    ; loop until controller allows itself to be read
    lda $4212
    and #$01
    bne ReadInput

    ; Read input
    rep #$30 ; 16 bit AXY
    ldx joy1raw
    lda $4218
    sta joy1raw
    txa
    eor joy1raw
    and joy1raw
    sta joy1press
    txa
    and joy1raw
    sta joy1held
    ; Not worried about controller validity for now

    sep #$30 ; 8 bit AXY
    rts

PlayerUpdate:
    rep #$30 ; 16 bit AXY

    lda player.stat_speed
    sta $00
    ; check (LEFT OR RIGHT) AND (UP OR DOWN)
    ; if so, multiply speed by 3/4; aka (A+A+A) >> 2
    lda joy1held
    ; LEFT or RIGHT. 00 = F; 01,10,11 = T
    bit #$0C00
    beq @skip_slow
    bit #$0300
    beq @skip_slow
    lda player.stat_speed
    asl
    clc
    adc $00
    lsr
    lsr
    sta $00
@skip_slow:

    ldx player.speed.y
    lda joy1held
    bit #JOY_DOWN
    bne @down
    bit #JOY_UP
    bne @up
    txa
    cmp #0
    bpl @slowup ; If speed.y > 0

    ; slowright
    clc
    adc player.stat_accel
    AMINI $00
    jmp @endy
@slowup:
    ; slowleft
    sec
    sbc player.stat_accel
    AMAXI $00
    jmp @endy
@down:
    ; right
    txa
    clc
    adc player.stat_accel
    AMIN $00
    jmp @endy
@up:
    ; left
    txa
    sec
    sbc player.stat_accel
    eor #$FFFF
    inc A
    AMIN $00
    eor #$FFFF
    inc A
@endy:
    sta player.speed.y
    
    ldx player.speed.x
    lda joy1held
    bit #JOY_RIGHT
    bne @right
    bit #JOY_LEFT
    bne @left
    ; X stop
    txa
    cmp #0
    bpl @slowleft ; If speed.x > 0

    ; slowright
    clc
    adc player.stat_accel
    AMINI $00
    jmp @endx
@slowleft:
    ; slowleft
    sec
    sbc player.stat_accel
    AMAXI $00
    jmp @endx
@right:
    ; right
    txa
    clc
    adc player.stat_accel
    AMIN $00
    jmp @endx
@left:
    ; left
    txa
    sec
    sbc player.stat_accel
    eor #$FFFF
    inc A
    AMIN $00
    eor #$FFFF
    inc A
@endx:
    sta player.speed.x

    ; apply speed
    lda player.pos.x
    clc
    adc player.speed.x
    AMAXUI (32 - 4)*256
    AMINUI (32 + 12*16 - 12)*256
    sta player.pos.x
    lda player.pos.y
    clc
    adc player.speed.y
    AMAXUI (64 - 4)*256
    AMINUI (64 + 8*16 - 12)*256
    sta player.pos.y
; handle player shoot
    lda player.tear_timer
    cmp player.stat_tear_delay ; if tear_timer < stat_tear_delay: ++tear_timer
    bcc @tear_not_ready
    ; check inputs
    lda joy1held
    bit #(JOY_A|JOY_B|JOY_Y|JOY_X)
    beq @end_tear_code
    jsr PlayerShootTear
    jmp @end_tear_code
@tear_not_ready:
    inc A
    sta player.tear_timer
@end_tear_code:
    sep #$30 ; 8 bit AXY
    rts

PlayerShootTear:
    rep #$30 ; 16 bit AXY
    jsr GetTearSlot
    lda player.flags
    eor #PLAYER_FLAG_EYE
    sta player.flags
    ; lda player.pos.x
    ; sta tear_array.1.pos.x,X
    ; lda player.pos.y
    ; sta tear_array.1.pos.y,X
    lda #240
    sta tear_array.1.lifetime,X
    stz tear_array.1.size,X
    lda #$0000
    sta player.tear_timer
    lda joy1held
    bit #JOY_Y
    bne @tear_left
    bit #JOY_A
    bne @tear_right
    bit #JOY_B
    bne @tear_down
;tear_up:
    lda player.speed.x
    lsr
    sta tear_array.1.speed.x,X
    lda #0;player.speed.y
    lsr
    sec
    sbc #256
    sta tear_array.1.speed.y,X
    jmp @vertical
@tear_left:
    lda player.speed.y
    sta tear_array.1.speed.y,X
    lda #0;player.speed.x
    sec
    sbc #256
    sta tear_array.1.speed.x,X
    jmp @horizontal
@tear_right:
    lda player.speed.y
    sta tear_array.1.speed.y,X
    lda #0;player.speed.x
    clc
    adc #256
    sta tear_array.1.speed.x,X
    jmp @horizontal
@tear_down:
    lda player.speed.x
    sta tear_array.1.speed.x,X
    lda #0;player.speed.y
    clc
    adc #256
    sta tear_array.1.speed.y,X
    jmp @vertical
@vertical:
    lda player.flags
    bit #PLAYER_FLAG_EYE
    bne @vertical_skip
    lda player.pos.x
    sta tear_array.1.pos.x,X
    lda player.pos.y
    clc
    adc #256*4
    sta tear_array.1.pos.y,X
    rts
@vertical_skip:
    lda player.pos.x
    clc
    adc #256*8
    sta tear_array.1.pos.x,X
    lda player.pos.y
    clc
    adc #256*4
    sta tear_array.1.pos.y,X
    rts
@horizontal:
    lda player.flags
    bit #PLAYER_FLAG_EYE
    bne @horizontal_skip
    lda player.pos.x
    clc
    adc #256*4
    sta tear_array.1.pos.x,X
    lda player.pos.y
    sta tear_array.1.pos.y,X
    rts
@horizontal_skip:
    lda player.pos.x
    clc
    adc #256*4
    sta tear_array.1.pos.x,X
    lda player.pos.y
    clc
    adc #256*8
    sta tear_array.1.pos.y,X
    rts

DrawTears:
    ; rts
    rep #$30 ; 16 bit mode
    lda #8
    sta $2102
    ldx #0
    cpx tear_bytes_used
    bcs @end
@iter:
    sep #$20 ; 8 bit A, 16 bit X
    lda tear_array.1.pos.x+1,X
    sta $2104
    lda tear_array.1.pos.y+1,X
    sta $2104
    stz $2104
    lda #%00110000
    sta $2104
    rep #$20 ; 16 bit mode
    txa ; ++X
    clc
    adc #_sizeof_tear_t
    tax
    cpx tear_bytes_used ; X != tear_bytes_used
    bcc @iter
@end:
    rts

UpdateTears:
    rep #$30 ; 16 bit AXY
    ldx #$0000
    cpx tear_bytes_used
    beq @end
    jmp @iter
@iter_remove:
    jsr RemoveTearSlot
    ; No ++X, but do check that this is the end of the array
    cpx tear_bytes_used ; X != tear_bytes_used
    bcs @end
@iter:
    lda tear_array.1.lifetime,X
    dec A
    cmp #0 ; if lifetime == 0, then remove
    beq @iter_remove
    sta tear_array.1.lifetime,X
    lda tear_array.1.pos.x,X
    clc
    adc tear_array.1.speed.x,X
    sta tear_array.1.pos.x,X
    lda tear_array.1.pos.y,X
    clc
    adc tear_array.1.speed.y,X
    sta tear_array.1.pos.y,X
    txa ; ++X
    clc
    adc #_sizeof_tear_t
    tax
    cpx tear_bytes_used ; X < tear_bytes_used
    bcc @iter
@end:
    rts

; Get the next available tear slot, and store it in X
; if there are no available slots, the tear with the lowest life will be chosen
GetTearSlot:
    rep #$30 ; 16 bit AXY
    lda tear_bytes_used
    cmp #TEAR_ARRAY_MAX_SIZE
    bcc @has_empty_slots
; no empty slots available:
; find the slot with the lowest lifetime
    lda #$7FFF
    sta $00 ; $00 is best value
    ldx #0 ; x is current index
    ldy #0 ; Y is best index
@iter_tears:
    lda tear_array.1.lifetime,X
    cmp $00
    bcs @skip_store
    sta $00
    txy ; if tears[X].lifetime < tears[Y].lifetime: Y=X
@skip_store:
; ++X
    txa ; increment X
    clc
    adc #_sizeof_tear_t
    tax
; X < TEAR_ARRAY_MAX_SIZE
    cpx #TEAR_ARRAY_MAX_SIZE
    bcc @iter_tears
; Finish, transfer Y to X
    tyx
    rts
; empty slots available:
@has_empty_slots:
    tax
    clc
    adc #_sizeof_tear_t
    sta tear_bytes_used
    rts

; Remove the tear at the index X
; AXY must be 16bit
RemoveTearSlot:
    rep #$30 ; 16 bit AXY
    ; decrement number of used tears
    lda tear_bytes_used
    sec
    sbc #_sizeof_tear_t
    sta tear_bytes_used
    ; Check if X is the last available tear slot
    cpx tear_bytes_used
    beq @skip_copy
    ; copy last tear slot to slot being removed
    ldy tear_bytes_used
    lda tear_array+0,Y
    sta tear_array+0,X
    lda tear_array+2,Y
    sta tear_array+2,X
    lda tear_array+4,Y
    sta tear_array+4,X
    lda tear_array+6,Y
    sta tear_array+6,X
    lda tear_array+8,Y
    sta tear_array+8,X
    lda tear_array+10,Y
    sta tear_array+10,X
    lda tear_array+12,Y
    sta tear_array+12,X
    lda tear_array+14,Y
    sta tear_array+14,X
@skip_copy:
    rts

TileData:
.dw $0002 $0004 $0004 $0004 $0004 $0004 $0004 $000C $000E $0004 $0004 $0004 $0004 $0004 $0004 $4002
.dw $0022 $0024 $0026 $0026 $0026 $0026 $0026 $002C $002E $0026 $0026 $0026 $0026 $0026 $4024 $4022
;              [                                                                       ]
.dw $0022 $0006 $0008 $000A $000A $000A $000A $000A $000A $000A $000A $000A $000A $4008 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0040 $0042 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4042 $4040
.dw $0060 $0062 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4062 $4060
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $0028 $002A $002A $002A $002A $002A $002A $002A $002A $002A $002A $4028 $4006 $4022
.dw $0022 $0006 $8008 $800A $800A $800A $800A $800A $800A $800A $800A $800A $800A $C008 $4006 $4022
;              [                                                                       ]
.dw $0022 $8024 $8026 $8026 $8026 $8026 $8026 $802C $802E $8026 $8026 $8026 $8026 $8026 $C024 $4022
.dw $8002 $8004 $8004 $8004 $8004 $8004 $8004 $800C $800E $8004 $8004 $8004 $8004 $8004 $8004 $C002

.ends

.bank 1
.section "Graphics"

.include "assets.inc"

.ends
