; single byte type
.STRUCT byte_t
    data db
.ENDST

; two byte type
.STRUCT word_t
    data dw
.ENDST

; three byte type
.STRUCT long_t
    data dl
.ENDST

; Position type
; Position format (for now):
; positions are one byte pixel position, one byte subpixel
; If I ever decide to have big rooms (doubtful),
; then one bit of subpixel may be added to the position instead
; Thus, speed is subpixels per frame
.STRUCT position_t
    x dw
    y dw
.ENDST

; Represents RNG state
.STRUCT rng_t
    low dw
    high dw
.ENDST