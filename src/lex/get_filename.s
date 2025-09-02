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

.import param_type
.import string

.import get_expr_str

; From main
.import submit_line

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_filename
.export get_filenamez

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
; <string> | .+ (' ' | $)
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
_get_filename_pla:
		pla

.proc get_filename
		jsr	get_expr_str
		bcs	_string

	ok:
		lda	param_type
		and	#$7f
		cmp	#'C'
		bne	error45

		; TODO: Vérifier que <string> est un nom de fichier valide?
		clc
		rts

	error45:
		; 45 Not a Character expression.
		lda	#45
		ldy	lex_prev_y
		sec
		rts

	_string:
		; get_expr a sauvegardé AX dans lex_ptr
		dey
		ldx	#$ff
	loop:
		inx
		iny
		lda	(lex_ptr),y
		sta	string,x
		beq	end

		cmp	#' '
		bne	loop

		; Ajooute le '\0' final
		lda	#$00
		sta	string,x

	end:
		; Chaine vide interdite
		cpx	#$00
		beq	error45

		; TODO: Vérifier que <string> est un nom de fichier valide?
		lda	#'C'
		sta	param_type
		clc
		rts
.endproc

;----------------------------------------------------------------------
; <string> | .+ (' ' | $) |
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
.proc get_filenamez
		pha
		lda	submit_line,y
		bne	_get_filename_pla

		sta	string
		pla

		lda	#'C'
		sta	param_type
		clc
		rts
.endproc

