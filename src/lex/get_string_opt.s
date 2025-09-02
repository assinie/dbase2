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
.import stringz_flg
.import string

.import get_string

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_string_opt

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
; ( ''' .+ ''' ) | ('"' .+ '"') |
;
; Entrée:
;	AX: adresse de la ligne
;	Y: offset dans la ligne
;
; Sortie:
;	idem get_string
;	string_opt: 0 -> pas de chaine, 1 -> chaine éventuellement nulle
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc get_string_opt
		sta	lex_ptr
		stx	lex_ptr+1

		lda	#$00
		sta	stringz_flg

		lda	(lex_ptr),y
		beq	end

		cmp	#'"'
		beq	_string
		cmp	#"'"
		bne	end

		; Chaine avec délimiteurs
	_string:
		inc	stringz_flg
		sec
		lda	lex_ptr
		jmp	get_string

		; Chaine vide
	end:
		lda	#$00
		sta	string
		tax

		clc
		rts
.endproc

