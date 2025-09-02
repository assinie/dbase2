
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
.import fns_save_a

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export datetonum

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
.proc datetonum
		; Stockage date: CCYYMMDD

		sta	fns_save_a
		ldx	#$03
		lda	#$00
	loop:
		sta	pfac,x
		dex
		bpl	loop
		lda	fns_save_a

		tax
		lda	bcd_value,x

		; Conversion BCD -> Binaire (Lee Davison https://philpem.me.uk/leeedavison/6502/shorts/bcd2bin.html )
		tax				; copy BCD value
		and	#$F0			; mask top nibble
		lsr				; /2 (/16*8)
		sta	fns_ptr			; save it
		lsr				; /4 (/16*4)
		lsr				; /8 (/16*2)
		adc	fns_ptr			; add /2 (carry always clear)
						; ((n/16*8)+(n/16*2) = (n/16*10))
		sta	fns_ptr			; save it
		txa				; get original back
		and	#$0F			; mask low nibble
		adc	fns_ptr			; add shifted (carry always clear)

		sta	pfac

		lda	#'N'
		sta	param_type

		clc
		rts

.endproc

