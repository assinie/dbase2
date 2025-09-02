
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
.export fn_sgn

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
; sgn(expN)
; (pas dBase III)
;
; Entrée:
;	A = n° de la commande
;	Y = offset vers le caractère suivant dans la ligne
;	X = offset dernier token lu
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
.proc fn_sgn
		lda	pfac+3
		bmi	negative

		bne	positive

		ora	pfac
		ora	pfac+1
		ora	pfac+2
		beq	end_0

	positive:
		lda	#$01
		sta	pfac
		lda	#$00
		beq	end

	negative:
		lda	#$ff
		sta	pfac

	end:
		sta	pfac+1
		sta	pfac+2
		sta	pfac+3

	end_0:
		; Inutile de modifier param_type puisque on
		; utilise déjà une valeur numérique
		clc
		rts
.endproc

