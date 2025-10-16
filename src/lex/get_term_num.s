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
.importzp lex_ptr
.import lex_prev_y

.importzp pfac
.importzp pfac1

.import skip_spaces

.import get_expr_num
.import get_expr_num1

; From math.s
.import push_num
.import pull_num
.import math_get_sp
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
		; [ temporaire, pour indiquer qu'on a déjà une valeur à
		; mettre sur la pile
		lda	#$ff
		sta	flag
		; ]
;		jsr	math_get_sp
;		; On soustrait 4 parce que on empile une valeur lors de la première passe
;		sec
;		sbc	#$04
;		sta	check_sp+1
;		ldy	lex_prev_y

	loop:

		lda	term_a
		ldx	term_x

		jsr	skip_spaces
		beq	end

		jsr	term
;		bcc	loop
		bcc	end

;		jsr	skip_spaces
;		jmp	end

;		jsr	math_get_sp
;	check_sp:
;		cmp	#$ff
;		beq	end

	error:
		ldy	lex_prev_y
		sec
		rts

	end:
		sty	term_y
		ldy	#$00
		jsr	pull_num
		ldy	term_y
		clc
		rts
.endproc


;----------------------------------------------------------------------
;
; Entrée:
;	A: -
;	X: -
;	Y: offset dans la ligne
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
;
; TERM = FACTOR $('+' FACTOR .OUT('add')
;     |       '-' FACTOR .OUT('sub')
;
;----------------------------------------------------------------------
.proc term
		jsr	factor
		bcs	L6
	L7:
		lda	#'+'
		jsr	expect_char
		bcs	L8
		jsr	factor
		bcs	error
		jsr	add

	L8:
		beq	L9
		lda	#'-'
		jsr	expect_char
		bcs	L10
		jsr	factor
		bcs	error
		jsr	sub

	L10:
	L9:
		beq	L7
		clc
		bcs	error
	L6:
	L11:
		rts

	error:
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	A: -
;	X: -
;	Y: offset dans la ligne
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
;
; FACTOR = POWER $('*' POWER .OUT('mpy')
;     |       '/' POWER .OUT('div')
;
;----------------------------------------------------------------------
.proc factor
		jsr	power
		bcs	L12
	L13:
		lda	#'*'
		jsr	expect_char
		bcs	L14
		jsr	power
		bcs	error
		jsr	multiply

	L14:
		bcc	L15
		lda	#'/'
		jsr	expect_char
		bcs	L16
		jsr	power
		bcs	error
		jsr	divide

	L16:
	L15:
		bcc	L13
		clc
		bcs	error
	L12:
	L17:
		rts

	error:
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	A: -
;	X: -
;	Y: offset dans la ligne
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
;
; POWER = UNARY $('^' POWER .OUT('exp')
;
;----------------------------------------------------------------------
.proc power
	.if 0
		jsr	unary
		bcs	L18
	L19:
		lda	#'^'
		jsr	expect_char
		bcs	L20
		jsr	power
		bcs	error
		jsr	exp

	L20:
	L21:
		bcc	L19
		clc
		bcs	error
	L18:
	L22:
		rts

	error:
		rts

	.else
		jmp	unary
	.endif
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	A: -
;	X: -
;	Y: offset dans la ligne
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
;
; UNARY = '+' VALUE
;     | '-' VALUE .OUT ('minus')
;     | VALUE
;
;----------------------------------------------------------------------
.proc unary
	_unary:
		jsr	value
		bcs	L26
	L26:
		bcc	L23
		lda	#'+'
		jsr	expect_char
		bcs	L23
		jsr	value
		bcs	error
	L23:
		bcc	L24
		lda	#'-'
		jsr	expect_char
		bcs	L24
		jsr	value
		bcs	error
		jsr	minus

	L24:
		rts

	error:
		rts

.if 0
;		bcc	L23
		lda	#'+'
		jsr	expect_char
		bcs	L23
		jsr	value
		bcs	error
	L23:
		bcc	L24
		lda	#'-'
		jsr	expect_char
		bcs	L25
		jsr	value
		bcs	error
		jsr	minus

	L25:
		bcc	L24
		jsr	value
		bcs	L26
	L26:
	L24:
		rts

	error:
		rts
.endif
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	A: -
;	X: -
;	Y: offset dans la ligne
;	flag: $ff: si on doit ajouter directement pfac à la pile
;	      $00: expression complète
; Sortie:
;	-
; Variables:
;	Modifiées:
;		- flag
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
;
; VALUE = .ID .OUT('load ' *)
;     | .NUMBER .OUT('literal ' *)
;     | '(' TERM ')'
;
;----------------------------------------------------------------------
.proc value
		; [ temporaire, pour indiquer qu'on a déjà une valeur à
		; mettre sur la pile
		lda	flag
		beq	L27a

		inc	flag
		jsr	push_num
		clc
		rts
		; ]

;		jsr	get_ident
;		bcs	L27
;		jsr	push_var


	L27:
;		bcc	L28
	L27a:
		lda	term_a
		ldx	term_x
		jsr	get_expr_num
		bcs	L29
		jsr	push_num


	L29:
		bcc	L28
		lda	#'('
		jsr	expect_char
		bcs	L30
		jsr	term
		bcs	error
		lda	#')'
		jsr	expect_char
		bcs	error
	L30:
	L28:
		rts

	error:
		rts
.endproc


;----------------------------------------------------------------------
;
; Entrée:
;	A: Caractère attendu
;	Y: offset dans la ligne
;
; Sortie:
;	A: Inchangé si Ok
;	X: Modifié (term_x)
;	Y: offset dans la ligne
;	C: 0-> Ok, 1-> error
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc expect_char
;		sty	lex_prev_y

		sta	cmp_a+1

		lda	term_a
		ldx	term_x
		jsr	skip_spaces
		beq	error

	cmp_a:
		cmp	#$ff
		bne	error

		iny
		clc
		rts

	error:
		lda	#10
		sec
		rts
.endproc

