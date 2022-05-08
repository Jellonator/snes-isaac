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
    tear_timer dw
    stat_speed dw
    stat_accel dw
    stat_tear_delay dw
    stat_tear_speed dw
    flags dw
.endst

; ENSURE tear_t is some kind of power of 2, that way
; multiplication/division is easy
; currently, size is 16
.struct tear_t
    speed instanceof position_t
    pos instanceof position_t
    lifetime dw ; frames before this tear is removed
    size db ; size; [0-3]
    type db
    damage dw
    flags dw
.endst

.enum $0100
    joy1raw dw
    joy1press dw
    joy1held dw
.ende

.define TEAR_ARRAY_MAX_COUNT 32
.define TEAR_ARRAY_MAX_SIZE (TEAR_ARRAY_MAX_COUNT*_sizeof_tear_t)

.enum $0200
    player instanceof player_t
    tear_bytes_used dw ; number of bytes used of tear_array
    tear_array instanceof tear_t TEAR_ARRAY_MAX_COUNT
.ende


.DEFINE JOY_A $0080 ; RIGHT
.DEFINE JOY_X $0040 ; UP
.DEFINE JOY_L $0020
.DEFINE JOY_R $0010
.DEFINE JOY_B $8000 ; DOWN
.DEFINE JOY_Y $4000 ; LEFT
.DEFINE JOY_SELECT $2000
.DEFINE JOY_START $1000
.DEFINE JOY_UP $0800
.DEFINE JOY_DOWN $0400
.DEFINE JOY_LEFT $0200
.DEFINE JOY_RIGHT $0100
.DEFINE JOY_ID $00FF
.DEFINE JOY_SHOOT_LEFT JOY_Y
.DEFINE JOY_SHOOT_RIGHT JOY_A
.DEFINE JOY_SHOOT_UP JOY_X
.DEFINE JOY_SHOOT_DOWN JOY_B

.DEFINE PLAYER_FLAG_EYE $0001