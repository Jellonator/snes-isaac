; SORTING ALGORITHMS
; These are implemented as macros, since its a bit faster and more dynamic
; than providing a custom sorting function pointer

; Get index of left child in a heap 'A = 2A+1'
.MACRO .SortHeap_ChildLeft_A
    asl
    inc A
.ENDM

; Get index of right child in a heap 'A = 2A+2'
.MACRO .SortHeap_ChildRight_A
    inc A
    asl
.ENDM

; Get index of parent in a heap 'A = (A-1)/2'
.MACRO .SortHeap_Parent_A
    dec A
    lsr
.ENDM

; Build a heap-sorting function with the given sort function
; `sort_func` will be called with X and Y as pointers to elements
; If C flag is clear, then array[X] will be sorted before array[Y]
; Try to make sure X and Y are maintained by the end of the function
; Heap functions assume we are in the correct data bank
.MACRO .SortHeap_Build ARGS funcname, sort_func, word_size
    .ASSERT word_size == 8 || word_size == 16

    ; Sort array at X with size A
    {funcname}:
        rep #$30
        .DEFINE ARRAY $09
        .DEFINE START $07
        .DEFINE END   $05
        .DEFINE ROOT  $03
        .DEFINE CHILD $01
        phx ; ARRAY $09,S
        pha ; START $07,S
        pha ; END   $05,S
        pha ; ROOT  $03,S
        pha ; CHILD $01,S
        lsr
        sta START,S
        ; LOOP
    ; while (END > 1):
    @loop_main:
        lda END,S
        cmp #2
        bccl @end_main
        ; if START > 0:
        lda START,S
        cmp #1
        bcc @extract
            ; --start
            lda START,S
            dec A
            sta START,S
            jmp @end_inc
        ; else:
        @extract:
            ; --end
            lda END,S
            dec A
            sta END,S
            ; swap(end, 0)
            .IF word_size == 16
                asl
            .ENDIF
            clc
            adc ARRAY,S
            tax
            lda ARRAY,S
            tay
            .IF word_size == 8
                sep #$20
            .ENDIF
            lda.w $0000,X
            pha
            lda.w $0000,Y
            sta.w $0000,X
            pla
            sta.w $0000,Y
            .IF word_size == 8
                rep #$20
            .ENDIF
        @end_inc:
        ; ROOT = START
        lda START,S
        sta ROOT,S
        ; while left(ROOT) < END:
        @loop_sift:
            lda ROOT,S
            .SortHeap_ChildLeft_A
            cmp END,S
            bcs @end_sift
            ; CHILD = left(ROOT)
            sta CHILD,S
            ; if CHILD+1 < END && ARRAY[CHILD] < ARRAY[CHILD+1]
            inc A
            cmp END,S
            bcs @no_right_child
                .IF word_size == 16
                    asl
                .ENDIF
                clc
                adc ARRAY,S
                tay
                lda CHILD,S
                .IF word_size == 16
                    asl
                .ENDIF
                clc
                adc ARRAY,S
                tax
                jsl sort_func
                rep #$30
                bcs @use_left_child
                    ; ++CHILD
                    lda CHILD,S
                    inc A
                    sta CHILD,S
        @use_left_child:
        @no_right_child:
            ; if ARRAY[ROOT] < ARRAY[CHILD]:
            lda ROOT,S
            .IF word_size == 16
                asl
            .ENDIF
            clc
            adc ARRAY,S
            tax
            lda CHILD,S
            .IF word_size == 16
                asl
            .ENDIF
            clc
            adc ARRAY,S
            tay
            jsl sort_func
            rep #$30
            bcs @end_sift ; else break
                ; swap(ROOT, CHILD)
                .IF word_size == 8
                    sep #$20
                .ENDIF
                lda.w $0000,X
                pha
                lda.w $0000,Y
                sta.w $0000,X
                pla
                sta.w $0000,Y
                .IF word_size == 8
                    rep #$20
                .ENDIF
                ; ROOT = CHILD
                lda CHILD,S
                sta ROOT,S
            jmp @loop_sift
        @end_sift:
        jmp @loop_main
    @end_main:
        pla
        pla
        pla
        pla
        plx
        rtl
        .UNDEFINE ARRAY
        .UNDEFINE START
        .UNDEFINE END
        .UNDEFINE ROOT
        .UNDEFINE CHILD

.ENDM