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
.import opt_to

; From utils
.import _find_cmnd

; From lex
.import ident

.importzp lex_ptr
.import lex_save_y

.import skip_spaces
.import get_ident

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_to_ident_opt

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
; "TO" <ident> |
;
; Entrée:
;	AX: adresse de la ligne
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
.proc get_to_ident_opt
		sta	lex_ptr
		stx	lex_ptr+1
		sty	lex_save_y

		lda	(lex_ptr),y
		beq	no_opt

		ldx	lex_save_y
		lda	#<opt_to
		ldy	#>opt_to
		jsr	_find_cmnd
		bcs	no_opt

		; Replace l'offset dans la ligne dans Y
		stx	lex_save_y
		ldy	lex_save_y

		lda	lex_ptr
		ldx	lex_ptr+1
		jsr	skip_spaces
		; Restaure A (détruit par skip_spaces)
		lda	lex_ptr
		;jsr	get_ident
		;bcs	no_opt
		jmp	get_ident
		rts

		; Chaine vide
	no_opt:
		lda	#$00
		sta	ident
		tax

		ldy	lex_save_y
		clc
		rts
.endproc

