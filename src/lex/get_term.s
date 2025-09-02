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
.import lex_prev_y

.import param1_type

.import get_expr1

.import get_term_num
.import get_term_num_entry
.import get_term_str
.import get_term_str_entry

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_term

.export term_a
.export term_x
.export term_y

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
		unsigned char term_a
		unsigned char term_x
		unsigned char term_y

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
; (<ident> | <string>) [<op> (<ident> | <string>)...]
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
.proc get_term
		sta	term_a
		stx	term_x
		jsr	get_expr1
		bcs	error

		lda	param1_type
		and	#$7f

		cmp	#'C'
		beq	expr_string

		cmp	#'N'
		beq	expr_num

		rts

	expr_num:
		jmp	get_term_num_entry

	expr_string:
		jmp	get_term_str_entry

;	error46:
;		; 46 Illegal value.
;		lda	#46
;		sec

	error:
		ldy	lex_prev_y
		sec
		rts
.endproc

