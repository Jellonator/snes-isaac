; GROUND DEFS

; Maximum number of ground operations in one tick
.DEFINE MAX_GROUND_OPS 512

; Ground palettes
.DEFINE GROUND_PALETTE_BROWN ($00 << 2)
.DEFINE GROUND_PALETTE_RED ($01 << 2)
.DEFINE GROUND_PALETTE_GREY ($02 << 2)
.DEFINE GROUND_PALETTE_YELLOW ($03 << 2)

; Function definitions

.FuncDefine "GroundAddOp"
    .FuncInA 16
    .FuncInX 16
    .FuncIgnoreBank
    .FuncIgnoreDirect
.FuncDefineEnd
