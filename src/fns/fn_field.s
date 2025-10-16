
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
.importzp fns_ptr

.importzp pfac

.import param_type
.import string

.import fns_save_y

; From fns.lib
.import fn_field

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_dbf_field

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
; field(<expN>), avec 1 <= expN <= 128
; dBase III: retourne une erreur si expN < 0
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
.proc fn_dbf_field
		lda	#$00
		sta	string

		; Numéro du champ < 256
		lda	pfac+1
		ora	pfac+2
		ora	pfac+3
		bne	endEmpty

		sty	fns_save_y

		ldx	pfac
		jsr	fn_field
		cmp	#EOK
		bne	endEmpty

		stx	fns_ptr
		sty	fns_ptr+1

		ldy	#$ff
		ldx	#$ff
	loop1:
		inx
		iny
		lda	(fns_ptr),y
		sta	string,x
		beq	end

		cmp	#' '
		bne	loop1

	end:
		lda	#$00
		sta	string,x

	endEmpty:
		lda	#'C'
		sta	param_type

		ldy	fns_save_y
		clc
		rts
.endproc

