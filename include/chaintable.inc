; Implementation for 'hash' table using coalesced chaining.
; * 'hash' in quotation marks since our hash function is just H(x) = x % N
; * keys are assumed to be 16b
; * insertion and deletion can be a little bit inefficient (as a treat), but search should be somewhat speedy

; Three key states for each table entry:
; * empty                  (0, -1) (high bit of ptr is 1)
; * has value, no pointer  (X, -1) (high bit of ptr is 1)
; * has value, has pointer (X, Y)
; note that this means that the inserted value can not be 0 (though its hash can still be 0)

; valueTable and ptrTable must both be 16b tables, with space reserved for (nBuckets + nCellar)*2 bytes each
; nBuckets is the number of buckets to reserve for actual values
; nCellar is extra space to reserve for the purpose of reducing overhead of hash table
; To hold N values, nBuckets + nCellar must be at least N.
; It is recommended, however, that nBuckets >= N, where N is the expected maximum number of elements in the table.
; It is suggested that nCellar = nBuckets / 5
.MACRO .MakeChainTableStatic ARGS valueTable, ptrTable, nBuckets, nCellar, postfix
    ; total size = buckets + cellar

    ; Clear table
    table_clear{postfix}:
        rep #$30
        ldx #2 * (nBuckets + nCellar)
        lda #-1
    @loop:
        stz.w valueTable-2,X
        sta.w ptrTable-2,X
        dex
        dex
        bne @loop
        rtl

    ; insert A into table
    table_insert{postfix}:
        rep #$30
        sta.b $00
    ; get pointer offset from A
        .CheapModA16 nBuckets
        asl
        tax ; X = (A % N) * 2
    ; check if value is null
        lda.w valueTable,X
        bne @insert
            ; value is null, just insert
            lda.b $00
            sta.w valueTable,X
            rtl
    @insert:
        ; find first empty bucket from end
        ldy.w #2 * (nBuckets + nCellar)
    @loop:
        dey
        dey
        lda.w valueTable,Y
        bne @loop
        ; found value
        lda.b $00
        sta.w valueTable,Y
        ; Y->ptr = X->ptr
        lda.w ptrTable,X
        sta.w ptrTable,Y
        ; X->ptr = Y
        tya
        sta.w ptrTable,X
        rtl

    ; Returns table offset in X
    table_find{postfix}:
        rep #$30
        sta.b $00
        ; get pointer offset from A
        .CheapModA16 nBuckets
        asl
        tax ; X = (A % N) * 2
        lda.b $00
    ; Find value
    @loop:
        cmp.w valueTable,X
        beq @endx ; found value, return X
        ldy.w ptrTable,X ; Y = X->ptr
        bmi @endy ; null pointer, return null
        cmp.w valueTable,Y
        beq @endy ; found value, return Y
        ldx.w ptrTable,Y ; X = Y->ptr
        bmi @endx ; null pointer, return null
        bra @loop
    @endy:
        tyx
    @endx:
        rtl

    ; Remove value A from table
    table_remove{postfix}:
    ; slightly modified 'find' routine,
        rep #$30
        sta.b $00
        ; get pointer offset from A
        .CheapModA16 nBuckets
        asl
        tax ; X = (A % N) * 2
        lda.b $00
    ; Find value
        cmp.w valueTable,X
        beq @endxonly
        ldy.w ptrTable,X ; Y = X->ptr
        bmi @endnull
    @loop:
        cmp.w valueTable,Y
        beq @endy ; found value, return Y
        ldx.w ptrTable,Y
        bmi @endnull ; null pointer, return null
        cmp.w valueTable,X
        beq @endx ; found value, return X
        ldy.w ptrTable,X
        bmi @endnull ; null pointer, return null
        bra @loop
    @endxonly:
        ; Found X, no prev pointer
        ; X->ptr = -1
        lda #-1
        sta.w ptrTable,X
        ; X->value = 0
        stz.w valueTable,X
        rtl
    @endy:
        ; Found at Y, X->ptr = Y
        ; prev->ptr = Y->ptr
        lda.w ptrTable,Y
        sta.w ptrTable,X
        ; Y->ptr = -1
        lda #-1
        sta.w ptrTable,Y
        ; Y->value = 0
        inc A
        sta.w valueTable,Y
        rtl
    @endx:
        ; Found at X, Y->ptr = X
        ; prev->ptr = X->ptr
        lda.w ptrTable,X
        sta.w ptrTable,Y
        ; X->ptr = -1
        lda #-1
        sta.w ptrTable,X
        ; X->value = 0
        stz.w valueTable,X
        rtl
    @endnull:
        rtl

.ENDM