
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

.importzp fns_ptr

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_string_from_table

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
;	X: n° du mot dans la table
;	fns_ptr: pointeur vers la table des mmots
; Sortie:
;	C=0
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc get_string_from_table

		ldy	#$ff

		dex
		beq	get_string

	loop:
		iny
		lda	(fns_ptr),y
		bpl	loop
		dex
		bne	loop

	get_string:
		ldx	#$ff
		; dex
	loop1:
		iny
		inx
		lda	(fns_ptr),y
		sta	string,x
		bpl	loop1

		and	#$7f
		sta	string,x
		inx
		lda	#$00
		sta	string,x

		lda	#'C'
		sta	param_type

		clc
		rts
.endproc

