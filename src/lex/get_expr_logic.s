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
; From lex
.importzp lex_ptr
.import lex_prev_y

.import param1
.import param1_type

.import comp_oper

.import skip_spaces

.import get_expr
.import get_expr1
.import get_cmp_op

;.import get_term
;.import get_term1

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_expr_logic

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
; <expr> | <expr> <cmp_op> <expr>
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
.proc get_expr_logic
		jsr	get_expr1
		bcs	error

		lda	lex_ptr
		ldx	lex_ptr+1
		jsr	skip_spaces

		lda	lex_ptr
		ldx	lex_ptr+1
		jsr	get_cmp_op

		bcc	expression

		; Pas d'opérateur de comparaison trouvé
		lda	param1_type
		and	#$7f
		cmp	#'L'
		bne	error37

		; la condition est une valeur logique seule donc on peut sortir
		; (param=param1)
		; Indique pas de comparaison
		lda	#$ff
		sta	comp_oper

		lda	lex_ptr
		ldx	lex_ptr+1

		clc
		rts

	expression:
		lda	lex_ptr
		ldx	lex_ptr+1

		jsr	skip_spaces
		beq	error37

		lda	lex_ptr
		ldx	lex_ptr+1
		jmp	get_expr


	error37:
		; 37 Not a Logical expression.
		; 10 Syntax error.
		; ldy	lex_prev_y
		lda	#37
		sec
	error:

	end:
		rts
.endproc

