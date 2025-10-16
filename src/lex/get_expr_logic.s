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
.import lex_save_y

.import param1_type
.import logic_value

.import comp_oper
.import logic_oper

.import skip_spaces

.import get_expr
.import get_expr1
.import get_cmp_op

; From utils.s
.import _find_cmnd

; From cond_expxr
.import cond_value
.import cond_expr

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
;	- A: modifié
;	- X: modifié
;	- Y: inchangé
;
; Variables:
;	Modifiées:
;		- comp_oper
;		- logic_vlue
;		- cond_value
;	Utilisées:
;		- logic_oper
;		- lex_ptr
;		- param1_type
; Sous-routines:
;	- skip_spaces
;	- _find_cmnd
;	- get_expr
;	- get_expr1
;	- get_cmp_op
;	- cond_expr
;----------------------------------------------------------------------
.proc get_expr_logic
		; Pas d'inversion du test
		lda	#$00
		sta	_eor+1

		; Y => X
		tya
		tax

		lda	#<logic_oper
		ldy	#>logic_oper
		jsr	_find_cmnd
		bcs	normal

		; cmp	#$00
		; bne	error10

		; .NOT. Inverse le test
		dec	_eor+1

	normal:
		; X => Y
		txa
		tay

		lda	lex_ptr
		ldx	lex_ptr+1

		; Si C=1 on n'a pas trouvé de ".NOT." donc inutile de sauter d'éventuels ' '
		bcs	no_spaces
		; pha
		jsr	skip_spaces
		; Restaure A (modifié par skip_spaces)
		; pla
		lda	lex_ptr

	no_spaces:
		jsr	get_expr1
		bcs	error

		lda	lex_ptr
		ldx	lex_ptr+1
		jsr	skip_spaces
		; Si Z=1 => fin de ligne, donc pas d'opérateur logique

		lda	lex_ptr
		; ldx	lex_ptr+1
		jsr	get_cmp_op
	_eor:
		eor	#$00
	;	and	#$07
		sta	comp_oper
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

		lda	logic_value
		eor	_eor+1
		sta	logic_value
		sta	cond_value
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
		; ldx	lex_ptr+1
		; [
		; jmp	get_expr
		; ]
		; [
		jsr	get_expr
		bcs	error

		jsr	cond_expr
		bcs	error

;		lda	lex_ptr
;		ldx	lex_ptr+1
		rts
		; ]
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

