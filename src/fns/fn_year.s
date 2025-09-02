
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

.import datetonum

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_year

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
.proc fn_year
		lda	#$01
		jsr	datetonum

		lda	bcd_value
		and	#$0f
		tax
		beq	mille

	@loop:
		; 100 = $64
		clc
		lda	#$64
		adc	pfac
		sta	pfac
		lda	#$00
		adc	pfac+1
		dex
		bne	@loop

	mille:
		lda	bcd_value
		lsr
		lsr
		lsr
		lsr
		beq	end
		tax
	@loop:
		; 1000 = $03e8
		clc
		lda	#$e8
		adc	pfac
		sta	pfac
		lda	#$03
		adc	pfac+1
		sta	pfac+1
		dex
		bne	@loop

	end:
		clc
		rts
.endproc

