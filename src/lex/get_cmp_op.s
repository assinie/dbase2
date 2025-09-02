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
; From main
.import submit_line

; From utils
.import _find_cmnd

; Chaines statiques
.import cmp_oper

; From lex
.import comp_oper
.import lex_save_y

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_cmp_op

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
; "<" | "=" | ">" | "<>"
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
.proc get_cmp_op
		sty	lex_save_y
		ldx	lex_save_y
		lda	#<cmp_oper
		ldy	#>cmp_oper
		jsr	_find_cmnd
		bcs	error10

		; Sortie:
		; A = caractère suivant la commande
		; Y = offset du caractère après la commande
		adc	#$01
		sta	comp_oper

		stx	lex_save_y
		ldy	lex_save_y
		lda	submit_line,y
		rts

		clc
		rts

	error10:
		ldy	lex_save_y
		;  10: Syntax error.
		; 107: Invalid operator.
		lda	#10
		sec
		rts
.endproc

