
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
.import fns_save_y

.import date_fmt

.import bcd2str

.import get_option

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_dtoc

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
OPT_CENTURY = 24

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
.proc fn_dtoc

		; Stockage: CCYYMMDD
		;
		; Formats:
		;	AMERICAN = mm/jj/aa
		;	ANSI     = aa.mm.jj
		;	BRITISH  = jj/mm/aa
		;	FRENCH   = jj/mm/aa
		;	GERMAN   = jj.mm/aa
		;	ITALIAN  = jj-mm-aa

		sty	fns_save_y

		; Séparateur
		lda	date_fmt
		and	#$2f
		sta	fns_save_a

		; CENTURY ON/OFF
		; [
;		ldx	#$01
;
;		lda	#$10
;		and	date_fmt
;		beq	date_format
;		dex
		; ]
		; [
		ldx	#$01

		lda	#OPT_CENTURY
		jsr	get_option
		beq	date_format
		dex
		; ]

	date_format:
		stx	fns_ptr
		bit	date_fmt
		bmi	french
		bvc	american

		; CCYY/MM/DD	(ANSI)
		; CENTURY ON
	ansi:
		; Inverse l'offset century
		ldy	#$ff
		cpx	#$01
		beq	century_off

		iny
		lda	bcd_value
		jsr	bcd2str

		; CENTURY OFF
	century_off:
		ldx	#$01
	@loop:
		iny
		lda	bcd_value,x
		jsr	bcd2str
		iny
		lda	fns_save_a
		sta	string,y
		inx
		cpx	#$04
		bne	@loop

	date_end:
		lda	#$00
		sta	string,y

		lda	#'C'
		sta	param_type

		ldy	fns_save_y

		clc
		rts

		; MM/DD/YY	(AMERICAN)
		; CENTURY ON|OFF
	american:
		ldy	#$ff
		ldx	#$02

	@loop:
		iny
		lda	bcd_value,x
		jsr	bcd2str
		iny
		lda	fns_save_a
		sta	string,y
		inx
		cpx	#$04
		bne	@loop

		; CENTURY ON
		ldx	fns_ptr
		; CENTURY OFF
		; ldx	#$01
	@loop1:
		iny
		lda	bcd_value,x
		jsr	bcd2str
		inx
		cpx	#$02
		bne	@loop1

		iny
		bne	date_end
;		lda	#$00
;		sta	string,y
;		beq	end

		;
		; DD/MM/YY	(BRITISH/FRENCH/GERMAN/ITALIAN)
		; CENTURY ON|OFF
	french:
		ldy	#$ff
		ldx	#$03
	@loop:
		iny
		lda	bcd_value,x
		jsr	bcd2str
		iny
		lda	fns_save_a
		sta	string,y
		dex
		cpx	#$01
		bne	@loop

		; CENTURY ON
		ldx	fns_ptr
		; CENTURY OFF
		; ldx	#$01
	@loop1:
		iny
		lda	bcd_value,x
		jsr	bcd2str
		inx
		cpx	#$02
		bne	@loop1

		iny

		bne	date_end
;		lda	#$00
;		sta	string,y
;		beq	end

.endproc

