
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
.export fn_fklabel

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
		fklabels:
			string80	"F2"
			string80	"F3"
			string80	"F4"
			string80	"F5"
			string80	"F6"
			string80	"F7"
			string80	"F8"
			string80	"F9"
			string80	"F10"
			.byte	$00
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
;	A: modifié
;	X: modifié
;	Y: inchangé
;
; Variables:
;	Modifiées:
;		- string
;		- param_type
;	Utilisées:
;		- pfac
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc fn_fklabel
		lda	#$00
		sta	string

		lda	#'C'
		sta	param_type

		lda	pfac+1
		ora	pfac+2
		ora	pfac+3
		bne	end

		lda	pfac
		beq	end

		cmp	#FKMAX+1
		bcs	end

		sty	save_y+1
		ldy	#$ff

		; Ici C=0, donc A=A-1
		sbc	#$00

		beq	copy
		tax
	loop:
		iny
		lda	fklabels,y
		bpl	loop
		dex
		bne	loop

	copy:
		ldx	#$ff
	loop_copy:
		inx
		iny
		lda	fklabels,y
		sta	string,x
		bpl	loop_copy
		and	#$7f
		sta	string,x

		lda	#$00
		sta	string+1,x

	save_y:
		ldy	#$ff

	end:
		clc
		rts
.endproc

