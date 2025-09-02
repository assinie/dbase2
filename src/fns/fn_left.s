
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

.import fns_save_a

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_left

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
.proc fn_left
		; Calcule la longueur de la chaine
		ldx	#$ff
	loop:
		inx
		lda	string,x
		bne	loop
		stx	fns_save_a

		; Index < 256?
		lda	pfac+1
		ora	pfac+2
		ora	pfac+3
		bne	error

		; Index > len(str) => erreur?
		lda	pfac
		cmp	fns_save_a
		bcc	end
		beq	end
		; bcs	error
		lda	fns_save_a

	end:
		tax
		lda	#$00
		sta	string,x

		lda	#'C'
		sta	param_type

		clc
		rts

	error:
		sec
		rts
.endproc

