
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
.export fn_replicate

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
; TODO: modifier pour copier la chaîne complète et non le 1er caractère seul
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
.proc fn_replicate
		lda	string
		sta	fns_save_a
		beq	end

		lda	#$00
		sta	string

		; Longueur < 256?
		lda	pfac+1
		ora	pfac+2
		ora	pfac+3
		bne	error88

		lda	pfac
		beq	end

		; Longueur >= 128?
		cmp	#128
		bcs	error88

		tax
		lda	#$00
		sta	string,x
		dex

		lda	fns_save_a
	loop:
		sta	string,x
		dex
		bpl	loop

	end:
		lda	#'C'
		sta	param_type

		clc
		rts

	error88:
		; 88 REPLICATE(): String too large.
		lda	#88
		sec
		rts
.endproc

