
;----------------------------------------------------------------------
;			includes cc65
;----------------------------------------------------------------------
.feature string_escapes

.include "telestrat.inc"
.include "fcntl.inc"
.include "errno.inc"

;----------------------------------------------------------------------
;			includes SDK
;----------------------------------------------------------------------
.include "SDK.mac"
.include "types.mac"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
; From strbin.s
;.importzp pfac
;.import sfac
;pfac1 := sfac

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.exportzp pfac
.exportzp sfac

.export sp

.export init_aexp

.export add
.export sub
.export divide
; .export exp
.export sgn
.export abs
.export sqr
.export minus
.export multiply
.export push_num
.export pull_num
.export math_get_sp

; Pour dbf_goto
.exportzp multiplicand
.exportzp multiplier
.exportzp result
.export mult

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
ITEM_SIZE = 4
STACK_SIZE = ITEM_SIZE*10

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"
		unsigned long pfac
		unsigned long sfac
	;	unsigned long result[2]
		unsigned long result_ext
		unsigned short pztemp

		multiplicand    = pfac		; 4 bytes
		multiplier      = sfac		; 4 bytes
		;result          = TR0		; 8 bytes   (note: shares memory with multiplier)
		result		= sfac

		dividend 	:= pfac		; contiendra le résultat de la division
		divisor		:= sfac
		remainder 	:= result_ext	; remainder is in zero-page to gain some cycle/byte ($fb-$fd)
		; pztemp 	 	:= result+4

	.segment "DATA"
		unsigned char stack[256]

		unsigned char sp

		unsigned char math_y

	.segment "RODATA"

.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"

;----------------------------------------------------------------------
;
; Entrée:
;	-
; Sortie:
;	A: Inchangé
;	X: $ff
;	Y: Inchangé
;
; Variables:
;	Modifiées:
;		- sp
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc init_aexp
		ldx	#$ff
		stx	sp
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	-
; Sortie:
;	A: Modifié
;	X: Mis à jour
;	Y: Inchangé
;	C: 0-> Ok, 1-> stack overflow
;
; Variables:
;	Modifiées:
;		- sp
;		- stack
;	Utilisées:
;		- pfac
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc push_num
		lda	sp
		sec
		sbc	#$04
		tax
		bcc	stack_overflow

		lda	pfac			; LSB
		sta	stack,x
		lda	pfac+1
		sta	stack+1,x
		lda	pfac+2
		sta	stack+2,x
		lda	pfac+3			; MSB
		sta	stack+3,x

		stx	sp
		clc

		rts

	stack_overflow:
		sec
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	Y: offset par rapport à pfac (0 pour pfac ou 4 pour sfac)
;
; Sortie:
;	A: Modifié
;	X: Mis à jour
;	Y: Inchangé
;	C: 0-> Ok, -> stack underflow
;
; Variables:
;	Modifiées:
;		- sp
;		- pfac
;		- sfac
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc pull_num
		lda	sp				; [4]
		cmp	#$ff-4+1			; [2]
		bcs	stack_underflow			; [2/3]

		adc	#$04				; [2]
		tax					; [2]

		lda	stack-4,x			; [4]
		sta	pfac,y				; [5]
		lda	stack-3,x			; [4]
		sta	pfac+1,y			; [5]
		lda	stack-2,x			; [4]
		sta	pfac+2,y			; [5]
		lda	stack-1,x			; [4]
		sta	pfac+3,y			; [5]

		stx	sp				; [4]

		rts					; [6]

	stack_underflow:
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	-
; Sortie:
;	A: Modifié
;	X: inchangé
;	Y: Inchangé
;	Z: fonction de sp
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		- sp
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc math_get_sp
		lda	sp
		rts
.endproc

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------

;----------------------------------------------------------------------
; Change le signe du nombre au sommet de la pile
;
; Entrée:
;	-
; Sortie:
;	A: Modifié
;	X: SP
;	Y: Inchangé
;	C: 0-> Ok, 1-> empty stack
;
; Variables:
;	Modifiées:
;		- stack
;	Utilisées:
;		- sp
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc minus
		ldx	sp
		cpx	#$fb+1
		bcs	empty_stack

		; clc
		lda	stack,x
		eor	#$ff
		adc	#$01
		sta	stack,x

		lda	stack+1,x
		eor	#$ff
		adc	#$00
		sta	stack+1,x

		lda	stack+2,x
		eor	#$ff
		adc	#$00
		sta	stack+2,x

		lda	stack+3,x
		eor	#$ff
		adc	#$00
		sta	stack+3,x

		; Pas d'erreur
		; lda	#$00
		clc
		rts

	empty_stack:
		; sec
		; lda	#$ff
                rts
.endproc

;----------------------------------------------------------------------
; Additonne les deux valeurs au sommet de la pile
;
; Entrée:
;	-
; Sortie:
;	A: Modifié
;	X: Mis à jour
;	Y: Inchangé
;	C: 0-> Ok, 1-> overflow / stack underflow
;
; Variables:
;	Modifiées:
;		- sp
;		- stack
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc add
		lda	sp
		cmp	#$ff-(2*4)+1
		bcs	stack_underflow

		; clc
		adc	#$04
		tax

		lda	stack,x			; LSB
		adc	stack-4,x
		sta	stack,x

		lda	stack+1,x
		adc	stack-3,x
		sta	stack+1,x

		lda	stack+2,x
		adc	stack-2,x
		sta	stack+2,x

		lda	stack+3,x			; MSB
		adc	stack-1,x
		sta	stack+3,x

		stx	sp
		bcs	overflow

		lda	#$00
		rts

	overflow:
		; Ici C=1
		; Remonter une errur en cas de dépassement de valeur?
		; 39: Numeric overlow (data was lost).
		lda	#39
		rts

	stack_underflow:
		tax
		rts
.endproc

;----------------------------------------------------------------------
; Soustrait les deux valeurs au sommet de la pile
;
; Entrée:
;	-
; Sortie:
;	A: Modifié
;	X: Mis à jour
;	Y: Inchangé
;	C: 0-> Ok, 1-> underflow / stack underflow
;
; Variables:
;	Modifiées:
;		- sp
;		- stack
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc sub
		lda	sp
		cmp	#$ff-(2*4)+1
		bcs	stack_underflow

		adc	#$04
		tax

		sec
		lda	stack,x			; LSB
		sbc	stack-4,x
		sta	stack,x

		lda	stack+1,x
		sbc	stack-3,x
		sta	stack+1,x

		lda	stack+2,x
		sbc	stack-2,x
		sta	stack+2,x

		lda	stack+3,x			; MSB
		sbc	stack-1,x
		sta	stack+3,x

		stx	sp
		bcc	underflow

		clc
		lda	#$00
		rts

	underflow:
		; Ici C=0
		; Remonter une errur en cas de dépassement de valeur?
		sec
		ldx	#$ff
		rts

	stack_underflow:
		tax
		rts
.endproc

;----------------------------------------------------------------------
; Multiplie les deux valeurs au sommet de la pile
;
; Entrée:
;	-
; Sortie:
;	Y: Inchangé
;	C: 0-> Ok, 1-> stack underflow
;
; Variables:
;	Modifiées:
;		- math_y
;	Utilisées:
;		-
; Sous-routines:
;	pull_num
;	push_num
;	mult
;----------------------------------------------------------------------
.proc multiply
		sty	math_y

		; Multiplier -> sfac
		ldy	#$04
		jsr	pull_num
		bcs	error

		; Multiplicand -> pfac
		ldy	#$00
		jsr	pull_num
		bcs	error

		jsr	mult

		jsr	push_num

		ldy	math_y
		lda	#$00
		rts

	error:
		ldy	math_y
		lda	#$ff
		rts
.endproc

;----------------------------------------------------------------------
; Multiplication signée
;
; Entrée:
;	multiplier
;	multiplicand
;
; Sortie:
;	A: Modifié
;	X: $ff
;	Y: $00
;	result: résultat
;	pfac: résultat
;
; Variables:
;	Modifiées:
;		result
;	Utilisées:
;		multiplicand
;		multiplier
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc mult
;		sty	term_y

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
		sta	result+4		; 32 bits of zero in A, result+6, result+5, result+4
						; (think of A as a local cache of result+7)
						;  Note:    First 8 shifts are  A -> result+6 -> result+5 -> result+4 -> result
						;           Next  8 shifts are  A -> result+6 -> result+5 -> result+4 -> result+1
						;           Next  8 shifts are  A -> result+6 -> result+5 -> result+4 -> result+2
						;           Final 8 shifts are  A -> result+6 -> result+5 -> result+4 -> result+3
		ldx	#$fc			; count for outer loop. Loops four times.

		; outer loop (4 times)
	outer_loop:
		ldy	#8			; count for inner loop
		lsr	result+4,x		; think "result" then later "result+1" then "result+2" then "result+3"

		; inner loop (8 times)
	inner_loop:
		bcc	shift

		; (result+4, result+5, result+6, A) += (multiplicand, multiplicand+1, multiplicand+2. multiplicand+3)
		sta	result+7		; remember A
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
		lda	result+7		; recall A
		adc	multiplicand+3

	shift:
		ror				; shift
		ror	result+6		;
		ror	result+5		;
		ror	result+4		;
		ror	result+4,x		; think "result" then later "result+1" then "result+2" then "result+3"
		dey
		bne	inner_loop		; go back for 1 more shift?

		inx
		bne	outer_loop		; go back for 8 more shifts?

		sta	result+7		;

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
		bpl	end			; skip if multiplicand is positive
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

;		ldy	term_y
		clc
		rts
.endproc

;----------------------------------------------------------------------
; Divise les deux valeurs au sommet de la pile
;
; Entrée:
;	-
; Sortie:
;	A: Modifié
;	X:
;	Y: Inchangé
;	C: 0-> Ok, 1-> stack underflow
;
; Variables:
;	Modifiées:
;		- math_y
;		- sign
;	Utilisées:
;		-
; Sous-routines:
;	- minus
;	- pull_num
;	- div
;	- push_num
;----------------------------------------------------------------------
.proc divide
		sty	math_y

		; Non signée
;		ldy	#$04
;		jsr	pull_num
;		ldy	#$00
;		jsr	pull_num
;		jsr	div

		; Signée
		lda	#$00
		sta	sign+1

		ldx	sp
		lda	stack+3,x
		bpl	v1

		jsr	minus
		inc	sign+1

		; Divisor -> sfac
	v1:
		ldy	#$04
		jsr	pull_num
		bcs	error

		lda	stack+3,x
		bpl	v2

		jsr	minus
		inc	sign+1

		; Dividend -> pfac
	v2:
		ldy	#$00
		jsr	pull_num
		bcs	error

		jsr	div

		jsr	push_num

	sign:
		lda	#$00
		and	#$01
		beq	end

		jsr	minus

	end:
		ldy	math_y
		lda	#$00
		rts

	error:
		ldy	math_y
		lda	#$ff
		rts
.endproc

;----------------------------------------------------------------------
; Modulo des deux valeurs au sommet de la pile
;
; Entrée:
;	-
; Sortie:
;	A:
;	X:
;	Y: inchnagé
;	C: 0-> Ok, 1-> stack overflow (impossible) / stack underflow
; Variables:
;	Modifiées:
;		- math_y
;		- pfac
;		- sfac
;	Utilisées:
;		- remainderc( result_ext)
; Sous-routines:
;	- pull_name
;	- div
;	- push_num
;----------------------------------------------------------------------
.proc mod
		sty	math_y

		; Divisor -> sfac
		ldy	#$04
		jsr	pull_num
		bcs	error

		; Dividend -> pfac
		ldy	#$00
		jsr	pull_num
		bcs	error

		jsr	div


		;[
		ldy	#$03
	loop:
		lda	remainder,y
		sta	pfac,y
		dey
		bpl	loop

		ldy	math_y

		jmp	push_num
		; ]
		; [ ou copie directe dans la pile
		; ]

	error:
		rts
.endproc

;----------------------------------------------------------------------
; Division non signée
;
; Entrée:
;	dividend (pfac)
;	divisor (sfac)
;
; Sortie:
;	A: Modifié
;	X: $00
;	Y: Modifié
;	dividend: résultat
;	remainder: modulo
;
; Variables:
;	Modifiées:
;		dividend (pfac)
;		divisor (sfac)
;		remainder
;		pztemp
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc div
	div32:
		lda	#0			; preset remainder to 0
		sta	remainder
		sta	remainder+1
		sta	remainder+2
		sta	remainder+3
		ldx	#32			; repeat for each bit: ...

	divloop:
		asl	dividend		; dividend lb & hb*2, msb -> Carry
		rol	dividend+1
		rol	dividend+2
		rol	dividend+3
		rol	remainder		; remainder lb & hb * 2 + msb from carry
		rol	remainder+1
		rol	remainder+2
		rol	remainder+3
		lda	remainder
		sec
		sbc	divisor			; substract divisor to see if it fits in
		tay				; lb result -> Y, for we may need it later

		lda	remainder+1
		sbc	divisor+1
		sta	pztemp

		lda	remainder+2
		sbc	divisor+2
		sta	pztemp+1

		lda	remainder+3
		sbc	divisor+3
		bcc	skip			; if carry=0 then divisor didn't fit in yet

		sta	remainder+3		; else save substraction result as new remainder,

		lda	pztemp+1
		sta	remainder+2

		lda	pztemp
		sta	remainder+1

		sty	remainder
		inc	dividend		; and INCrement result cause divisor fit in 1 times

	skip:
		dex
		bne	divloop
		rts
.endproc

;----------------------------------------------------------------------
; Remplace la sommet de la pile par -1 si négatif, 0 si nul, +1 si
; positif
;
; Entrée:
;	-
; Sortie:
;	A: modifié
;	X: SP
;	Y: inchangé
;	C: 0-> Ok, 1-> empty stack
;
; Variables:
;	Modifiées:
;		- stack
;	Utilisées:
;		- sp
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc sgn
		ldx	sp
		cpx	#$fb+1
		bcs	empty_stack

		lda	stack,x
		bmi	negative

		bne	positive

		ora	stack+1,x
		ora	stack+2,x
		ora	stack+3,x
		beq	end_0

	positive:
		lda	#$01
		sta	stack,x
		lda	#$00
		beq	end

	negative:
		lda	#$ff
	end_0:
		sta	stack,x
	end:
		sta	stack+1,x
		sta	stack+2,x
		sta	stack+3,x

	empty_stack:
		rts
.endproc

;----------------------------------------------------------------------
; Remplace la sommet de la pile par -1 si négatif, 0 si nul, +1 si
; positif
;
; Entrée:
;	-
; Sortie:
;	A: modifié
;	X: SP
;	Y: inchangé
;	C: 0-> Ok, 1-> empty stack
;
; Variables:
;	Modifiées:
;		-
;	Utilisées: sp
;		-
; Sous-routines:
;	- minus
;----------------------------------------------------------------------
.proc abs
		ldx	sp
		cpx	#$fb+1
		bcs	empty_stack

		lda	stack,x
		bpl	end
		jmp	minus

	end:
	empty_stack:
		rts
.endproc

;----------------------------------------------------------------------
; Racine carrée de l'argument (16 bits uniquement, à modifier pour 32)
;
; Entrée:
;	-
; Sortie:
;	A: modifié
;	X: modifié
;	Y: inchangé
;	C: 0-> Ok, 1-> empty stack
;
; Variables:
;	Modifiées:
;		- pfac
;		- sfac
;		- result_ext
;
;	Utilisées:
;		- sp
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc sqr
		ldx	sp
		cpx	#$fb+1
		bcs	empty_stack

		lda	stack+3,x
		bpl	_sqr

		; 61: SQRT() : Negative
		lda	#61
		sec
		rts

	_sqr:
		; sauvegarde Y
		sty	_ldy+1

		; Copie le sommet de la pile dans pfac
		lda	stack,x
		sta	pfac
		lda	stack+1,x
		sta	pfac+1
		lda	stack+2,x
		sta	pfac+2
		lda	stack+3,x
		sta	pfac+3

		; Cf: http://www.6502.org/source/integers/root.htm
		; By Lee Davison
		;
		; Calculates the 8 bit root and 9 bit remainder of a 16 bit unsigned integer in
		; Numberl/Numberh. The result is always in the range 0 to 255 and is held in
		; Root, the remainder is in the range 0 to 511 and is held in Reml/Remh
		;
		; partial results are held in templ/temph
		;
		; This routine is the complement to the integer square program.
		;
		; Destroys A, X registers.

		; variables - must be in RAM

		; Rem := sfac
		; Root := stack,x
		; Number := pfac
		; Temp := result_ext
		lda	#$00			; clear A
		sta	sfac			; clear remainder low byte
		sta	sfac+1			; clear remainder high byte
		sta	stack,x			; clear Root
		sta	stack+1,x		; clear Root
		sta	stack+2,x		; clear Root
		sta	stack+3,x		; clear Root

		ldy	#$08			; 8 pairs of bits to do
	loop:
		asl	stack,x			; Root = Root * 2

		asl	pfac			; shift highest bit of number ..
		rol	pfac+1			;
		rol	sfac			; .. into remainder
		rol	sfac+1			;

		asl	pfac			; shift highest bit of number ..
		rol	pfac+1			;
		rol	sfac			; .. into remainder
		rol	sfac+1			;

		lda	stack,x			; copy Root ..
		sta	result_ext		; .. to templ
		lda	#$00			; clear byte
		sta	result_ext+1		; clear temp high byte

		sec				; +1
		rol	result_ext		; temp = temp * 2 + 1
		rol	result_ext+1		;

		lda	sfac+1			; get remainder high byte
		cmp	result_ext+1		; comapre with partial high byte
		bcc	next			; skip sub if remainder high byte smaller

		bne	subtr			; do sub if <> (must be remainder>partial !)

		lda	sfac			; get remainder low byte
		cmp	result_ext		; comapre with partial low byte
		bcc	next			; skip sub if remainder low byte smaller

						; else remainder>=partial so subtract then
						; and add 1 to root. carry is always set here
	subtr:
		lda	sfac			; get remainder low byte
		sbc	result_ext		; subtract partial low byte
		sta	sfac			; save remainder low byte
		lda	sfac+1			; get remainder high byte
		sbc	result_ext+1		; subtract partial high byte
		sta	sfac+1			; save remainder high byte

		inc	stack,x			; increment Root
	next:
		dey				; decrement bit pair count
		bne	loop			; loop if not all done

	_ldy:
		ldy	#$ff
		clc
		rts

	empty_stack:
		rts
.endproc

