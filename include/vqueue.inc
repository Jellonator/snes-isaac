.FuncDefine "ClearVQueue"
    .FuncInA 16
    .FuncIgnoreX
    .FuncIgnoreBank
    .FuncIgnoreDirect
.FuncDefineEnd

.FuncDefine "ProcessVQueue"
    .FuncInA 16
    .FuncInX 16
    .FuncInBank $7F
    .FuncIgnoreDirect
    .FuncOutA 8
    .FuncOutBank $00
.FuncDefineEnd