
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
.include "ch376.inc"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "include/dbase.inc"
.include "macros/utils.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.importzp pfac
.importzp fns_ptr

.import param_type
;.import ident
;.import value
.import string
;.import bcd_value
;.import logic_value
.importzp pfac1

.import is_pfac_byte

.import fns_save_y
.import lex_save_a

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_peek

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
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"

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
;
; Entrée:
;	AX = lex_ptr
;	Y = offset vers le caractère suivant dans la ligne
;	X = offset dernier token lu
;
; Sortie:
;	C: 0-> Ok, 1-> Erreur
;	A: Code erreur ou 'N'
;	X: inchangé
;	Y: inchangé
;
; Variables:
;	Modifiées:
;		- fns_save_y
;		- fns_save_a
;		- fns_ptr
;		- pfac
;		- param_type
;
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc fn_peek
		sty	fns_save_y

		lda	pfac+2
		ora	pfac+3
		bne	error46

		lda	pfac
		sta	fns_ptr
		lda	pfac+1
		sta	fns_ptr+1

		ldy	#$00
		sty	pfac+1

		lda	(fns_ptr),y
		sta	pfac

		lda	lex_save_a
		cmp	#TOKEN_PEEK
		beq	end

		iny
		lda	(fns_ptr),y
		sta	pfac+1

	end:

		ldy	fns_save_y

		lda	#'N'
		sta	param_type
		clc
		rts

	error46:
		; 46 Illegal value.
		lda	#46
		sec
		rts
.endproc

