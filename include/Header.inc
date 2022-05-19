
.MEMORYMAP
    DEFAULTSLOT 3
    SLOT 0 $0000 $0100 "ZeroMemory" ; Zero page RAM
    SLOT 1 $0100 $1E00 "MainMemory" ; RAM mirror slot
    SLOT 2 $2000 $6000 "Registers" ; register slot
    SLOT 3 $8000 $8000 "ROM" ; ROM slot
    SLOT 4 $2000 $E000 "ExtraMemory" ; Non-mirrored RAM slot
    SLOT 5 $0000 $8000 "SRAM" ; SRAM slot
.ENDME

.ROMBANKMAP
    BANKSTOTAL $80
    BANKSIZE $8000
    BANKS $80
.ENDRO
; ROM starts at $80, NOT $00
; This only really matters since we're using FASTROM
.BASE $80

.SNESHEADER
    ID "SNES"
    ; Program title, 21 byttes
    NAME "Binding of Isaac SNES"
    ; FASTROM + LoROM
    FASTROM
    LOROM

    CARTRIDGETYPE $00 ; $00 = ROM only
    SRAMSIZE $00      ; No SRAM
    COUNTRY $01       ; $01 = U.S.
    LICENSEECODE $00
    VERSION $00
.ENDSNES

.SNESNATIVEVECTOR
    COP EmptyHandler
    BRK EmptyHandler
    ABORT EmptyHandler
    NMI VBlank
    IRQ EmptyHandler
.ENDNATIVEVECTOR

.SNESEMUVECTOR
    COP EmptyHandler
    ABORT EmptyHandler
    NMI EmptyHandler
    RESET Start
    IRQBRK EmptyHandler
.ENDEMUVECTOR

.BANK $00 SLOT "ROM"
.ORG $0000
.SECTION "EmptyVectors" SEMIFREE
EmptyHandler:
    rti
.ENDS

.EMPTYFILL $00