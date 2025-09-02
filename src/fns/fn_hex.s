
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
.import fn_numtostr

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_hex

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
.proc fn_hex
		lda	#'$'
		jmp	fn_numtostr
.if 0
		sta	string
		lda	#'0'
		sta	string+1

		ldx	#$00
		stx	string+2

		ldy	#$03
	loop:
		lda	pfac,y
		jsr	byte
		dey
		bpl	loop

		cpx	#$00
		beq	end

		lda	#$00
		sta	string+1,x

	end:
		; inx
		; inx
		; stx	string_len
		ldy	fns_save_y
		clc
		rts

	.proc byte
			pha
			lsr
			lsr
			lsr
			lsr
			jsr	nibble
			pla
			and	#$0f

		nibble:
			bne	ok

			cpx	#$00
			beq	end

		ok:
			clc
			adc	#'0'
			cmp	#'9'+1
			bcc	store
			adc	#$06
		store:
			sta	string+1,x
			inx
		end:
			rts
	.endproc
.endif
.endproc
