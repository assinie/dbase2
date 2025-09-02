
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
.import fns_save_y

.import fn_day
.import fn_month
.import fn_year

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_dow

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
.proc fn_dow
	;* This routine works for any date from 1900-03-01 to 2155-12-31.
	;* No range checking is done, so validate input before calling.
	;*
	;* I use the formula
	;*     Weekday = (day + offset[month] + year + year/4 + fudge) mod 7
	;* where the value of fudge depends on the century.
	;*
	;* Input: Y = year (0=1900, 1=1901, ..., 255=2155)
	;*        X = month (1=Jan, 2=Feb, ..., 12=Dec)
	;*        A = day (1 to 31)
	;*
	;* Output: Weekday in A (0=Sunday, 1=Monday, ..., 6=Saturday)
		sty	fns_save_y

		jsr	fn_day
		lda	pfac
		pha

		jsr	fn_month
		lda	pfac
		pha

		; Calcule la différence par rapport à 1900
		lda	bcd_value
		sed
		sec
		sbc	#$19
		cld
		sta	bcd_value
		jsr	fn_year
		ldy	pfac

		pla
		tax
		pla

		jsr	weekday
		sta	pfac
		lda	#$00
		sta	pfac+1

		ldy	fns_save_y
		clc
		rts

	tmp = fns_ptr			; Temporary storage

	weekday:
		cpx	#3		; Year starts in March to bypass
		bcs	march		; leap year problem
		dey			; If Jan or Feb, decrement year
	march:
		eor	#$7F		; Invert A so carry works right
		cpy	#200		; Carry will be 1 if 22nd century
		adc	mtab-1,x	; A is now day+month offset
		sta	tmp
		tya			; Get the year
		jsr	mod7		; Do a modulo to prevent overflow
		sbc	tmp		; Combine with day+month
		sta	tmp
		tya			; Get the year again
		lsr			; Divide it by 4
		lsr
		clc			; Add it to y+m+d and fall through
		adc	tmp
	mod7:
		adc	#7		; Returns (A+3) modulo 7
		bcc	mod7		; for A in 0..255
		rts
	mtab:
		.byte 1,5,6,3,1,5,3,0,4,2,6,4	; Month offsets
.endproc

