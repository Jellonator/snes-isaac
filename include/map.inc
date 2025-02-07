; DOOR TYPE INFO
; Note: even = can't enter, odd = can enter
; this way, checking if a door can be entered is as easy as `BIT #1`
; Opening a door should be ORA 1, closing should be AND ~1
.DEFINE DOOR_MASK_IS_CLOSED $80
.DEFINE DOOR_MASK_OPEN_METHOD $70
.DEFINE DOOR_MASK_STATUS $F0
.DEFINE DOOR_MASK_TYPE $0F

; Door status flag
.DEFINE DOOR_OPEN   $80
.DEFINE DOOR_CLOSED $00

; Door types
.DEFINE DOOR_TYPE_NULL     $00
.DEFINE DOOR_TYPE_NORMAL   $01
.DEFINE DOOR_TYPE_TREASURE $02
.DEFINE DOOR_TYPE_SHOP     $03
.DEFINE DOOR_TYPE_BOSS     $04
.DEFINE DOOR_TYPE_ARCADE   $05
.DEFINE DOOR_TYPE_SECRET   $06
.DEFINE DOOR_TYPE_CURSE    $07

; Door open method
.DEFINE DOOR_METHOD_NEVER       $00 ; DEFAULT - door can never open
.DEFINE DOOR_METHOD_KEY         $10
.DEFINE DOOR_METHOD_BOMB        $20
.DEFINE DOOR_METHOD_COIN        $30
.DEFINE DOOR_METHOD_FINISH_ROOM $40

; MAPTILE FLAGS
.DEFINE MAPTILE_EXPLORED $01   ; indicates that player has entered room
.DEFINE MAPTILE_HAS_PLAYER $02 ; indicates that player is in the room
.DEFINE MAPTILE_COMPLETED $04  ; indicates that player has completed the room
.DEFINE MAPTILE_DISCOVERED $08 ; indicates that player is been in an adjacent room
; used for generation step; marks tiles in the mapgenAvailableRooms table
.DEFINE MAPTILE_AVAILABLE $80

; MAP SIZE
.DEFINE MAP_MAX_WIDTH 16
.DEFINE MAP_MAX_HEIGHT 10
.DEFINE MAP_MAX_SIZE (MAP_MAX_WIDTH*MAP_MAX_HEIGHT)
.DEFINE MAX_MAP_SLOTS 64
.DEFINE MAP_ZPBUF_ADDR (256-MAX_MAP_SLOTS) ; 96/$60

; MAP TILE POSITION STRUCT
.STRUCT maptilepos_t
    value db ; lower 4 bits for X, upper 4 bits for Y
.ENDST

; Branch if tile is on left border
; Assume tile is in A
.MACRO .BranchIfTileOnLeftBorderA ARGS label
    bit #$0F
    beq label
.ENDM

; Branch if tile is on right border
; Assume tile is in A
.MACRO .BranchIfTileOnRightBorderA ARGS label
    inc A
    bit #$0F
    bne @@@@@\.\@
    dec A
    bra label
@@@@@\.\@:
    dec A
.ENDM

; Branch if tile is on top border
; Assume tile is in A
.MACRO .BranchIfTileOnTopBorderA ARGS label
    bit #$F0
    beq label
.ENDM

; Branch if tile is on bottom border
; Assume tile is in A
.MACRO .BranchIfTileOnBottomBorderA ARGS label
    cmp #$90
    bcs label
.ENDM