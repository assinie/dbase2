
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

; From fns.lib
.import fn_lupdate

; From fns
.import fn_isopen

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_dbf_lupdate

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
		unsigned char low

	.segment "DATA"

.popseg

;----------------------------------------------------------------------
;			Chaines statiques
;----------------------------------------------------------------------
.pushseg
	.segment "RODATA"
		b2b_table:
			.byte	$63,$31,$15,$07,$03,$01,$00

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
.proc fn_dbf_lupdate
		jsr	fn_isopen
		bcs	error52

		sty	save_y+1

		jsr	fn_lupdate

		; Century
		lda	#$19
		sta	bcd_value

		jsr	fn_lupdate
		; A: Day
		; X: Month
		; Y: Year

		; Year
		; sty	bcd_value+1
		; Month
		stx	bcd_value+2

		; Day
		sta	bcd_value+3
		jsr	bin2bcd
		sta	bcd_value+3

		; Month
		lda	bcd_value+2
		jsr	bin2bcd
		sta	bcd_value+2

		; Year
		tya
		jsr	bin2bcd
		sta	bcd_value+1

		; Ajuste le siècle
		clc

		php
		sei
		sed

		txa
		; clc
		adc	bcd_value
		sta	bcd_value

		plp

		lda	#'D'
		sta	param_type

		clc

	end:
	save_y:
		ldy	#$ff
		rts

	error52:
		; 52: No database is in USE.
		lda	#52
		sec
		bcs	end
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	- A: valeur binaire
; Sortie:
;	- A: valeur BCD (dizaines / unitées)
;	- X: vleur BCD (centaines)
;	- Y: inchangé
; Variables:
;	Modifiées:
;		- low
;	Utilisées:
;		- b2b_table
; Sous-routines:
;	-
;----------------------------------------------------------------------
; http://www.6502.org/users/mycorner/6502/shorts/bin2bcd.html
;----------------------------------------------------------------------
.proc bin2bcd
		php
		sei

	; table of BCD values for each binary bit, put this somewhere.
	; note! values are -1 as the ADC is always done with the carry set
	bin_2_bcd:
		sed			; all adds in decimal mode
		sta	low		; save A
		lda	#$00		; clear A
		ldx	#$07		; set bit count
	bit_loop:
		lsr	low		; bit to carry
		bcc	skip_add	; branch if no add

		adc	b2b_table-1,X	; else add BCD value
	skip_add:
		dex			; decrement bit count
		bne	bit_loop	; loop if more to do

	;***********************************************************************
	; if you only require conversion of numbers between $00 and $63 (0 to 99
	; decimal) then omit all code between the "*"s

		bcc	skip_100	; branch if no 100's carry
					; if Cb set here (and can only be set by the
					; last loop add) then there was a carry into
		inx			; the 100's so add 100's carry to the high byte
	skip_100:
					; now check the 2^7 (128) bit
		lsr	low		; bit 7 to carry
		bcc	skip_fin	; branch if no add

		inx			; else effectively add 100 part of 128
		adc	#$27		; and then add 128 (-1) part of 128
		bcc	skip_fin	; branch if no further carry

		inx			; else add 200's carry
	skip_fin:
	;	stx	high		; save result high byte

	; end of 100's code
	;***********************************************************************

	;	sta	low		; save result low byte
	;	cld			; clear decimal mode
		plp
		rts
.endproc

