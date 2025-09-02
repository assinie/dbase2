
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
.export fn_oct

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
.proc fn_oct
		lda	#'@'
		jmp	fn_numtostr
.if 0
		; 4 octets -> 11 chiffres en octal
		sty	fns_save_y

		lda	#'C'
		sta	param_type

		lda	#'@'
		sta	string
		lda	#'0'
		sta	string+1

		ldx	#$00
		stx	string+2

		;		3		2		1		0
		;	0aa aaa aaa 	bbb bbb bbc 	ccc ccc cdd 	ddd ddd 000
	byte3:
		clc
		lda	pfac+3
		beq	byte2
		jsr	octal3

		; Voir pour supprimes les '0' inutiles
	byte2:
		lda	pfac+1
		cmp	#$80
		lda	pfac+2
		rol
		jsr	octal3

	byte1:
		lda	pfac+1
		asl	pfac
		rol
		asl	pfac
		rol
		jsr	octal3

	byte0:
		lda	pfac
		asl
		jsr	octal2


		lda	#$00
		sta	string+1,x

		ldy	fns_save_y
		clc
		rts


	octal3:
		rol
		rol
		rol

		pha
		php
		and	#$07
		clc
		adc	#'0'
		sta	string+1,x
		inx
		plp
		pla

	octal2:
		rol
		rol
		rol

		pha
		php
		and	#$07
		clc
		adc	#'0'
		sta	string+1,x
		inx
		plp
		pla

	octal1:
		rol
		rol
		rol

		and	#$07
		clc
		adc	#'0'
		sta	string+1,x
		inx
		rts
.endif
.endproc

