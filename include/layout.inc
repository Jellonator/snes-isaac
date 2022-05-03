; Position format (for now):
; positions are one byte pixel position, one byte subpixel
; If I ever decide to have big rooms (doubtful),
; then one bit of subpixel may be added to the position instead
; Thus, speed is subpixels per frame

.struct position_t
    x dw
    y dw
.endst

.struct player_t
    pos instanceof position_t
    speed instanceof position_t
    stat_speed dw
    stat_accel dw
.endst

.enum $0100
    joy1raw dw
    joy1press dw
    joy1held dw
.ende

.enum $0200
    player instanceof player_t
.ende

.DEFINE JOY_A $0080
.DEFINE JOY_X $0040
.DEFINE JOY_L $0020
.DEFINE JOY_R $0010
.DEFINE JOY_B $8000
.DEFINE JOY_Y $4000
.DEFINE JOY_SELECT $2000
.DEFINE JOY_START $1000
.DEFINE JOY_UP $0800
.DEFINE JOY_DOWN $0400
.DEFINE JOY_LEFT $0200
.DEFINE JOY_RIGHT $0100
.DEFINE JOY_ID $00FF