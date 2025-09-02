;----------------------------------------------------------------------
;			includes cc65
;----------------------------------------------------------------------
.feature string_escapes
.feature loose_char_term

.include "telestrat.inc"

;----------------------------------------------------------------------
;			includes SDK
;----------------------------------------------------------------------
.include "SDK.mac"
.include "types.mac"
.include "case.mac"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "include/dbase.inc"
.include "macros/utils.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
; From get_term
.import term_a
.import term_x
.import term_y

; From lex
.import lex_prev_y

.importzp pfac
.importzp pfac1

.import skip_spaces

.import get_expr_num
.import get_expr_num1

; From math.s
.import init
.import push_num
.import pull_num
.import add
.import sub
.import divide
.import minus
.import multiply

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_term_num
.export get_term_num_entry

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;				Page Zéro
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"
		result: .res 8
.popseg

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "DATA"
		unsigned char flag
.popseg

;----------------------------------------------------------------------
;			Chaines statiques
;----------------------------------------------------------------------
.pushseg
	.segment "RODATA"

.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"

;----------------------------------------------------------------------
; (<ident> | <num>) [<op> (<ident> | <num>)...]
;
; Entrée:
;	AX: adresse de la ligne
;	Y: offset
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc get_term_num
	::get_term_num_entry := entry

		sta	term_a
		stx	term_x

		jsr	get_expr_num1
		bcs	error

	entry:
	loop:

		lda	term_a
		ldx	term_x

		jsr	skip_spaces
		beq	end

		cmp	#'+'
		beq	term
		cmp	#'-'
		beq	term
		cmp	#'*'
		bne	end

	term:
		sta	op+1
		iny

		lda	term_a
		jsr	skip_spaces
		lda	term_a

		jsr	get_expr_num
		bcs	error

	op:
		lda	#'+'
		cmp	#'+'
		beq	add
		cmp	#'*'
		beq	mult

	sub:
		sec
		lda	pfac1
		sbc	pfac
		sta	pfac1

		lda	pfac1+1
		sbc	pfac+1
		sta	pfac1+1

		lda	pfac1+2
		sbc	pfac+2
		sta	pfac1+2

		lda	pfac1+3
		sbc	pfac+3
		sta	pfac1+3
		jmp	loop

	add:
		clc
		lda	pfac1
		adc	pfac
		sta	pfac1

		lda	pfac1+1
		adc	pfac+1
		sta	pfac1+1

		lda	pfac1+2
		adc	pfac+2
		sta	pfac1+2

		lda	pfac1+3
		adc	pfac+3
		sta	pfac1+3

		jmp	loop

	error10:
		; 10 Syntax error.
		lda	#10

	error:
		ldy	lex_prev_y
		sec
		rts

	end:
		; Recopie pfac1 dans pfac
		ldx	#$03
	loop_end:
		lda	pfac1,x
		sta	pfac,x
		dex
		bpl	loop_end

		clc
		rts
.endproc

;----------------------------------------------------------------------
; Multiplication signée 32x32 = 64
; /!\ ATTENTION: utilise TR0 à TR7
;                pas d'erreur en cas d'overflow (valeur > +/-2^31)
;
; Entrée:
;	AX: adresse de la ligne
;	Y: offset
;
; Sortie:
;
; Variables:
;	Modifiées:
;		TR0-TR7: /!\
;
;	Utilisées:
;		pfac
;		pfac1
; Sous-routines:
;	-
;----------------------------------------------------------------------
; omult22.a
; based on Dr Jefyll, http://forum.6502.org/viewtopic.php?f=9&t=689&start=0#p19958
; - adjusted to use fixed zero page addresses
; - removed 'decrement to avoid clc' as this is slower on average
; - rearranged memory use to remove final memory copy and give LSB first order to result
; - X counter counts up from $fc to avoid cpx
; - i.e. mult60 expanded into 32 bit x 32 bit
; - could be unrolled for more speed at the cost of more memory
;
;
; multiplicand
; +------+------+------+------+
; |  +3  |  +2  |  +1  |  +0  |
; +------+------+------+------+
;              ||
;             _||_  add
;             \  /               initially set to
; result       \/                multiplier
; +------+------+------+------+  +------+------+------+------+
; |  +7  |  +6  |  +5  |  +4  |  |  +3  |  +2  |  +1  |  +0  |
; +------+------+------+------+  +------+------+------+------+
;
; (1) first 8 times around loop, shift right: result+7 into +6 into +5 into +4 into +0:
;
; ----------------------------> shift                 >
;                              \_____________________/
;
;
; (2)  next 8 times around loop, shift right: result+7 into +6 into +5 into +4 into +1:
;
; ----------------------------> shift          >
;                              \______________/
;
;
; (3)  next 8 times around loop, shift right: result+7 into +6 into +5 into +4 into +2:
;
; ----------------------------> shift   >
;                              \_______/
;
;
; (3) final 8 times around loop, shift right: result+7 into +6 into +5 into +4 into +3:
;
; -------------------------------> shift
;
;
; 32 bit x 32 bit unsigned multiply, 64 bit result
; Average cycles: 1653.00
; 59 bytes

multiplicand    = pfac   ; 4 bytes
multiplier      = pfac1  ; 4 bytes
;result          = TR0   ; 8 bytes   (note: shares memory with multiplier)

;* = $0200

; 32 bit x 32 bit unsigned multiply, 64 bit result
;
; On Entry:
;   multiplier:     four byte value
;   multiplicand:   four byte value
; On Exit:
;   result:         eight byte product (note: 'result' shares memory with 'multiplier')
.proc mult
		sty	term_y

		; Step 1: unsigned multiply
		; copy multiplier into result (multiplier preserved for sign calculation later)
		lda	multiplier
		sta	result
		lda	multiplier+1
		sta	result+1
		lda	multiplier+2
		sta	result+2
		lda	multiplier+3
		sta	result+3


		lda	#0			;
		sta	result+6		;
		sta	result+5		;
		sta	result+4	; 32 bits of zero in A, result+6, result+5, result+4
					; (think of A as a local cache of result+7)
					;  Note:    First 8 shifts are  A -> result+6 -> result+5 -> result+4 -> result
					;           Next  8 shifts are  A -> result+6 -> result+5 -> result+4 -> result+1
					;           Next  8 shifts are  A -> result+6 -> result+5 -> result+4 -> result+2
					;           Final 8 shifts are  A -> result+6 -> result+5 -> result+4 -> result+3
		ldx	#$fc		; count for outer loop. Loops four times.

		; outer loop (4 times)
	outer_loop:
		ldy	#8              ; count for inner loop
		lsr	result+4,x      ; think "result" then later "result+1" then "result+2" then "result+3"

		; inner loop (8 times)
	inner_loop:
		bcc	shift

		; (result+4, result+5, result+6, A) += (multiplicand, multiplicand+1, multiplicand+2. multiplicand+3)
		sta	result+7        ; remember A
		lda	result+4
		clc
		adc	multiplicand
		sta	result+4
		lda	result+5
		adc	multiplicand+1
		sta	result+5
		lda	result+6
		adc	multiplicand+2
		sta	result+6
		lda	result+7        ; recall A
		adc	multiplicand+3

	shift:
		ror                 ; shift
		ror	result+6        ;
		ror	result+5        ;
		ror	result+4        ;
		ror	result+4,x      ; think "result" then later "result+1" then "result+2" then "result+3"
		dey
		bne	inner_loop      ; go back for 1 more shift?

		inx
		bne	outer_loop      ; go back for 8 more shifts?

		sta	result+7        ;

		; Step 2: apply sign (See C=Hacking16 for details).
		bit	multiplier+1
		bpl	multiplicand_sign	; skip if multiplier is positive
		sec
		lda	result+4
		sbc	multiplicand
		sta	result+4

		lda	result+5
		sbc	multiplicand+1
		sta	result+5

		lda	result+6
		sbc	multiplicand+2
		sta	result+6

		lda	result+7
		sbc	multiplicand+3
		sta	result+7

	multiplicand_sign:
		bit	multiplicand+1
		bpl	end               ; skip if multiplicand is positive
		sec
		lda	result+4
		sbc	multiplier
		sta	result+4

		lda	result+5
		sbc	multiplier+1
		sta	result+5

		lda	result+6
		sbc	multiplier+2
		sta	result+6

		lda	result+6
		sbc	multiplier+3
		sta	result+7

	end:

		; Recopie result dans pfac
		ldx	#$03
	loop_end:
		lda	result,x
		sta	pfac,x
		dex
		bpl	loop_end

		ldy	term_y
		clc
		rts
.endproc
