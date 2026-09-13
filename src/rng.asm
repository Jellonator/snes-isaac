.include "base.inc"
.include "rng.inc"

.BANK $01 SLOT "ROM"
.SECTION "RNG" FREE

; macro for loop unrolling
.MACRO .UpdateRng_ABS ARGS rngaddr, N
    lda.w rngaddr
    .REPT N
        asl A
        rol.w rngaddr+2
        bcc +++++
        eor #$A3
        +++++:
    .ENDR
    sta.w rngaddr
.ENDM

; macro for loop unrolling
.MACRO .UpdateRng_DIR_INDL ARGS rngaddr_low, rngaddr_high, N
    lda [rngaddr_low]
    .REPT N
        asl A
        pha
        lda [rngaddr_high]
        rol
        sta [rngaddr_high]
        pla
        bcc +++++
        eor #$A3
        +++++:
    .ENDR
    sta [rngaddr_low]
.ENDM

; STAGE RNG
; Use stage RNG for generating the level, i.e. in mapgenerator.asm

; Use if boolean value is needed for stage
; Though you may still be able to use more of byte if bad entropy is acceptible
.IgnoreFlags
.SoftSetBank D_BANK_MIRROR_LOWRAM
.SoftSetA 16
.procimpll "Random.Stage.Update1"
    .UpdateRng_ABS stageSeed, 1
    rtl
.endproc

; Use if 4-bit value is needed for stage
; Result stored in lower byte of A
.IgnoreFlags
.SoftSetBank D_BANK_MIRROR_LOWRAM
.SoftSetA 16
.procimpll "Random.Stage.Update4"
    .UpdateRng_ABS stageSeed, 4
    rtl
.endproc

; Use if 8-bit value is needed for stage
; Result stored in lower byte of A, though higher byte may also be used if
; bad entropy is acceptible
.IgnoreFlags
.SoftSetBank D_BANK_MIRROR_LOWRAM
.SoftSetA 16
.procimpll "Random.Stage.Update8"
    .UpdateRng_ABS stageSeed, 8
    rtl
.endproc

; Use if 16-bit value is needed for stage
.IgnoreFlags
.SoftSetBank D_BANK_MIRROR_LOWRAM
.SoftSetA 16
.procimpll "Random.Stage.Update16"
    .UpdateRng_ABS stageSeed, 16
    rtl
.endproc

; Use if 32-bit value is needed for stage
; lower two bytes stored in A, higher two bytes stored in Y
.IgnoreFlags
.SoftSetBank D_BANK_MIRROR_LOWRAM
.SoftSetAX 16, 16
.procimpll "Random.Stage.Update32"
    .UpdateRng_ABS stageSeed, 32
    ldy.w stageSeed+2
    rtl
.endproc

.IgnoreFlags
.SoftSetBank D_BANK_MIRROR_LOWRAM
.SoftSetA 16
.procdefines "_RngGeneratorInitStage"
    .UpdateRng_ABS gameSeed, 16
    sta.w stageSeed.low
    .UpdateRng_ABS gameSeed, 16
    sta.w stageSeed.high
    rts
.endproc

; ROOM RNG
; Use Room RNG for the init functions of entities, the FIRST TIME THEY LOAD,
; and for room rewards

; Use if 8-bit value is needed for stage
; Result stored in lower byte of A, though higher byte may also be used if
; bad entropy is acceptible
.IgnoreFlags
.SoftSetA 16
.SoftSetDirect $0000
.procimpll "Random.Room.Update8"
    .UpdateRng_DIR_INDL currentRoomRngAddress_Low, currentRoomRngAddress_High, 8
    rtl
.endproc

; Use if 16-bit value is needed for stage
.IgnoreFlags
.SoftSetA 16
.SoftSetDirect $0000
.procimpll "Random.Room.Update16"
    .UpdateRng_DIR_INDL currentRoomRngAddress_Low, currentRoomRngAddress_High, 16
    rtl
.endproc

; Get a questionably random 16-bit number.
; Much, much faster than other random number generating functions. However,
; these numbers are just spit out in the same order every time from a table.
; These are better used for instances where this isn't too noticeable and
; doesn't affect level generation.
.IgnoreFlags
.SoftSetAX 16, 16
.SoftSetBank D_BANK_MIRROR_LOWRAM
.procimpll "Random.Quick16"
    inc.w quickrandIndex
    lda #$FFFF ~ (RANDTABLE_SIZE-1)
    trb.w quickrandIndex
    ldx.w quickrandIndex
    lda.l RandTable,X
    rtl
.endproc

; Clear RNG with known values
.IgnoreFlags
.SoftSetBank D_BANK_MIRROR_LOWRAM
.procimpll "Random.Clear"
    .SetA 16
    stz.w quickrandIndex
    lda #$0000
    sta.w gameSeed.low
    sta.w gameSeedStored.low
    lda #$0000
    sta.w gameSeed.high
    sta.w gameSeedStored.high
    .call "_RngGeneratorInitStage"
    rtl
.endproc

.IgnoreFlags
.SoftSetBank D_BANK_MIRROR_LOWRAM
.procimpll "Random.InitFromTimer"
    .SetA 16
    stz.w quickrandIndex
    ; copy seed
    lda.l seed_timer_low
    sta.w gameSeed.low
    lda.l seed_timer_high
    sta.w gameSeed.high
    ; shuffle
    .UpdateRng_ABS gameSeed, 32
    lda.w gameSeed.low
    sta.w gameSeedStored.low
    lda.w gameSeed.high
    sta.w gameSeedStored.high
    ; init stage seed
    .call "_RngGeneratorInitStage"
    rtl
.endproc

.ENDS