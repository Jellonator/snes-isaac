.InvalidateContext
.SoftSetAX 8, 8
.SoftSetBank $7E
.IgnoreDirect
.procheaderl "MapGen.UpdateDoors"
.endproc

.InvalidateContext
.IgnoreDirect
.SoftSetBank D_BANK_MIRROR_LOWRAM
.procheaderl "MapGen.ClearAll"
    .SoftSetAX 8, 8
.endproc

.InvalidateContext
.procheaderl "MapGen.GenerateMap"
    .SetAX 8, 8
    .SetBank $7E
    .InvalidateContext
.endproc

.DEFINE DEVILROOM_DOORTYPE (DOOR_TYPE_NORMAL | DOOR_METHOD_DEVIL | DOOR_OPEN)
; Update doors connected to room 'X', such that:
;  * All doors only connect to boss rooms
;  * All doors are set to the special devil room type
.InvalidateContext
.SoftSetAX 8, 8
.SoftSetBank $7E
.IgnoreDirect
.procheaderl "MapGen.UpdateDoorsForDevilRoom"
.endproc

; Initialize the tile at X, into given slot
; Parameters:
;     slot:     db $05,S
;     roomtype: db $04,S
.InvalidateContext
.SoftSetAX 8, 8
.SoftSetBank $7E
.IgnoreDirect
.procheaderl "MapGen.InitializeRoomXIntoSlot"
.endproc

; Setup the room at tile position X
.InvalidateContext
.SoftSetAX 8, 8
.SoftSetBank $7E
.IgnoreDirect
.procheaderl "MapGen.SetupRoomX"
    .SetAX 8, 8
.endproc