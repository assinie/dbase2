
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

.import param_type
.import ident
.import value
.import string
.import bcd_value
.import logic_value

.import is_pfac_byte

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_space

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
.proc fn_space
		lda	pfac+3
		bmi	error60

		jsr	is_pfac_byte
		bne	error59

		; Longueur >= 128?
		lda	pfac
		cmp	#128
		bcs	error59

		tax

		lda	#$00
		sta	string,x

		dex
		bmi	end

		lda	#' '
	loop:
		sta	string,x
		dex
		bpl	loop

	end:
		lda	#'C'
		sta	param_type
		clc
		rts

	error59:
		; 59 SPACE() : Too large.
		lda	#59
		bne	error

	error60:
		; 60 SPACE() : Negative.
		lda	#60
;		bne	error

;	error27:
;		; 27 Not a numeric expression.
;		lda	#27

	error:
		sec
		rts
.endproc

