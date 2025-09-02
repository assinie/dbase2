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
; Chaines statiques
.import opt_date_fmt

; From main
.import submit_line

; From utils
.import _find_cmnd

; From lex
.import opt_num
.import lex_save_y

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_date_fmt

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
; "AMERICAN" | "ANSI" | "BRITISH" | "FRENCH" | "GERMAN" | "ITALIAN"
;
; Entrée:
;	AX: adresse de la ligne
;	Y: offset dans la ligne
;
; Sortie:
;	A: dernier caractère lu
;	Y: offset vers le dernier caractère lu
;	C: 0-> Ok, 1->erreur (premier caractère non numérique)
;	Z: fonction du dernier caractère lu (Z=1 -> EOL)
;
; Variables:
;	Modifiées:
;		string
;		prt
;
;	Utilisées:
;		-
;
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc get_date_fmt
		sty	lex_save_y
		ldx	lex_save_y
		lda	#<opt_date_fmt
		ldy	#>opt_date_fmt
		jsr	_find_cmnd
		bcs	error

		; Sortie:
		; A = caractère suivant la commande
		; Y = offset du caractère après la commande
		sta	opt_num
		stx	lex_save_y
		ldy	lex_save_y
		lda	submit_line,y
		rts

		clc
		rts
	error:
		ldy	lex_save_y
		sec
		rts
.endproc

