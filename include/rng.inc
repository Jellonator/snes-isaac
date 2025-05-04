; STAGE RNG
; Use stage RNG for generating the level, i.e. in mapgenerator.asm

; Use if boolean value is needed for stage
; Though you may still be able to use more of byte if bad entropy is acceptible
.FuncDefine "RNG.Stage.Rand1"
    .FuncInA 16
    .FuncIgnoreX
    .FuncIgnoreBank
    .FuncIgnoreDirect
.FuncDefineEnd

; Use if 4-bit value is needed for stage
; Result stored in lower byte of A
.FuncDefine "RNG.Stage.Rand4"
    .FuncInA 16
    .FuncIgnoreX
    .FuncIgnoreBank
    .FuncIgnoreDirect
.FuncDefineEnd

; Use if 8-bit value is needed for stage
; Result stored in lower byte of A, though higher byte may also be used if
; bad entropy is acceptible
.FuncDefine "RNG.Stage.Rand8"
    .FuncInA 16
    .FuncIgnoreX
    .FuncIgnoreBank
    .FuncIgnoreDirect
.FuncDefineEnd

; Use if 16-bit value is needed for stage
.FuncDefine "RNG.Stage.Rand16"
    .FuncInA 16
    .FuncIgnoreX
    .FuncIgnoreBank
    .FuncIgnoreDirect
.FuncDefineEnd

; Use if 32-bit value is needed for stage
; lower two bytes stored in A, higher two bytes stored in Y
.FuncDefine "RNG.Stage.Rand32"
    .FuncInA 16
    .FuncIgnoreX
    .FuncIgnoreBank
    .FuncIgnoreDirect
.FuncDefineEnd

; ROOM RNG
; Use Room RNG for the init functions of entities, the FIRST TIME THEY LOAD,
; and for room rewards

; Use if 8-bit value is needed for stage
; Result stored in lower byte of A, though higher byte may also be used if
; bad entropy is acceptible
.FuncDefine "RNG.Room.Rand8"
    .FuncInA 16
    .FuncIgnoreX
    .FuncIgnoreBank
    .FuncInDirect $0000
.FuncDefineEnd

; Use if 16-bit value is needed for stage
.FuncDefine "RNG.Room.Rand16"
    .FuncInA 16
    .FuncIgnoreX
    .FuncIgnoreBank
    .FuncInDirect $0000
.FuncDefineEnd

; Get a questionably random 16-bit number.
; Much, much faster than other random number generating functions. However,
; these numbers are just spit out in the same order every time from a table.
; These are better used for instances where this isn't too noticeable and
; doesn't affect level generation.
.FuncDefine "RNG.QuickRand16"
    .FuncInA 16
    .FuncIgnoreX
    .FuncIgnoreBank
    .FuncIgnoreDirect
.FuncDefineEnd

; Clear RNG with known values
.FuncDefine "RNG.Clear"
    .FuncInA 16
    .FuncIgnoreX
    .FuncIgnoreBank
    .FuncIgnoreDirect
.FuncDefineEnd

.FuncDefine "RNG.InitFromTimer"
    .FuncInA 16
    .FuncIgnoreX
    .FuncIgnoreBank
    .FuncIgnoreDirect
.FuncDefineEnd