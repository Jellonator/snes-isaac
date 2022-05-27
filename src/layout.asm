.include "base.inc"

; This is ONLY to ensure that the game is staying within memory limits

.RAMSECTION "ZP" BANK $7E SLOT "ZeroMemory" FREE
.ENDS

.RAMSECTION "Shared" BANK $7E SLOT "SharedMemory" FREE
    rawMemoryShared ds (rawMemorySizeShared-$0100)
.ENDS

.RAMSECTION "7E" BANK $7E SLOT "ExtraMemory" FREE
    rawMemory7E ds (rawMemorySize7E-$7E2000)
.ENDS

.RAMSECTION "7F" BANK $7F SLOT "ExtraMemory" FREE
    rawMemory7F ds (rawMemorySize7F-$7F0000)
.ENDS
