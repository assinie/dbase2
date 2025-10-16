
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

.importzp lex_work_ptr

; From fn_upper.s
.import fn_upper

; From fn_isopen.s
.import fn_isopen

; From dbf.lib
.import fn_dbf

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_alias

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
;	- Y: inchangé
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc fn_alias
		sty	save_y+1

		jsr	fn_isopen
		bcc	open

		ldx	#$00
		beq	eos

	open:
		jsr	fn_dbf
		sta	lex_work_ptr
		sty	lex_work_ptr+1

		; Copie ke nom du fichier dans string
		ldy	#$ff
	loop_copy:
		iny
		lda	(lex_work_ptr),y
		sta	string,y
		bne	loop_copy

		; Conversion minuscules/MAJUSCULES
		jsr	fn_upper

		; Cherche le '.'
		ldx	#$ff
	loop_dot:
		inx
		lda	string,x
		beq	eos
		cmp	#'.'
		bne	loop_dot

	eos:
		lda	#' '
	loop_fill:
		cpx	#10
		bcs	end
		sta	string,x
		inx
		bne	loop_fill

	end:
		lda	#$00
		sta	string+10

		; Si alias est une fonction
		; [
		; Type = 'C'
		lda	#'C'
		sta	param_type
		ldx	#10
		; ]

	save_y:
		ldy	#$ff
		clc
		rts
.endproc

