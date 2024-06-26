.MEMORYMAP
    DEFAULTSLOT 3
    SLOT 0 $0000 $0100 "ZeroMemory" ; Zero page RAM
    SLOT 1 $0100 $1D00 "SharedMemory" ; RAM mirror slot (excluding $200 of stack space)
    SLOT 2 $2000 $6000 "Registers" ; register slot
    SLOT 3 $0000 $10000 "ROM" ; ROM slot
    SLOT 4 $2000 $E000 "ExtraMemory" ; Non-mirrored RAM slot
    SLOT 5 $0000 $10000 "FullMemory" ; Full RAM slot
    SLOT 6 $0000 $8000 "SRAM" ; SRAM slot
    SLOT 7 $1E00 $0200 "Stack" ; Stack slot, ensuring at least 512 bytes reserved for stack
.ENDME

.ROMBANKMAP
    BANKSTOTAL $40
    BANKSIZE $10000
    BANKS $40
.ENDRO
; ROM starts at $80, NOT $00
; This only really matters since we're using FASTROM
.BASE $C0

.SNESHEADER
    ID "SNES"
    ; Program title, 21 bytes
    NAME "Super BindingOfIsaac "
         ;                     ;
    ; FASTROM + LoROM
    FASTROM
    HIROM

    CARTRIDGETYPE $00 ; $00 = ROM only
    SRAMSIZE $00      ; No SRAM
    COUNTRY $01       ; $01 = U.S.
    LICENSEECODE $00
    VERSION $00
.ENDSNES

.EMPTYFILL $00