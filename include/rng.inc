; STAGE RNG
; Use stage RNG for generating the level, i.e. in mapgenerator.asm

; Use if boolean value is needed for stage
; Though you may still be able to use more of byte if bad entropy is acceptible
.IgnoreFlags
.SoftSetBank D_BANK_MIRROR_LOWRAM
.SoftSetA 16
.procheaderl "Random.Stage.Update1"
.endproc

; Use if 4-bit value is needed for stage
; Result stored in lower byte of A
.IgnoreFlags
.SoftSetBank D_BANK_MIRROR_LOWRAM
.SoftSetA 16
.procheaderl "Random.Stage.Update4"
.endproc

; Use if 8-bit value is needed for stage
; Result stored in lower byte of A, though higher byte may also be used if
; bad entropy is acceptible
.IgnoreFlags
.SoftSetBank D_BANK_MIRROR_LOWRAM
.SoftSetA 16
.procheaderl "Random.Stage.Update8"
.endproc

; Use if 16-bit value is needed for stage
.IgnoreFlags
.SoftSetBank D_BANK_MIRROR_LOWRAM
.SoftSetA 16
.procheaderl "Random.Stage.Update16"
.endproc

; Use if 32-bit value is needed for stage
; lower two bytes stored in A, higher two bytes stored in Y
.IgnoreFlags
.SoftSetBank D_BANK_MIRROR_LOWRAM
.SoftSetAX 16, 16
.procheaderl "Random.Stage.Update32"
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
.procheaderl "Random.Room.Update8"
.endproc

; Use if 16-bit value is needed for stage
.IgnoreFlags
.SoftSetA 16
.SoftSetDirect $0000
.procheaderl "Random.Room.Update16"
.endproc

; Get a questionably random 16-bit number.
; Much, much faster than other random number generating functions. However,
; these numbers are just spit out in the same order every time from a table.
; These are better used for instances where this isn't too noticeable and
; doesn't affect level generation.
.IgnoreFlags
.SoftSetAX 16, 16
.SoftSetBank D_BANK_MIRROR_LOWRAM
.procheaderl "Random.Quick16"
.endproc

; Clear RNG with known values
.IgnoreFlags
.SoftSetBank D_BANK_MIRROR_LOWRAM
.procheaderl "Random.Clear"
    .SoftSetA 16
.endproc

; Initialize RNG from global timer
.IgnoreFlags
.SoftSetBank D_BANK_MIRROR_LOWRAM
.procheaderl "Random.InitFromTimer"
    .SoftSetA 16
.endproc