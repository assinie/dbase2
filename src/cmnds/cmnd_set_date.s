
;----------------------------------------------------------------------
;			includes cc65
;----------------------------------------------------------------------
.feature string_escapes

.include "telestrat.inc"
.include "fcntl.inc"

;----------------------------------------------------------------------
;			includes SDK
;----------------------------------------------------------------------
.include "SDK.mac"
.include "types.mac"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "include/dbase.inc"
.include "macros/readline.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.import opt_date_fmt
.import opt_num

; From lex
.import lex_save_y

; From utils
.import _find_cmnd

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_set_date
.export date_fmt

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
		;unsigned char date_fmt
		date_fmt:
			.byte $2f | $80 | $10
			;	/   FR    CENTURY ON
.popseg

;----------------------------------------------------------------------
;			Chaines statiques
;----------------------------------------------------------------------
.pushseg
	.segment "RODATA"
		date_fmt_tbl:
			.byte	$2f
			.byte	$2e | $40
			.byte	$2f | $80
			.byte	$2f | $80
			.byte	$2e | $80
			.byte	$2d | $80
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
.proc cmnd_set_date
		sty	lex_save_y
		ldx	lex_save_y
		lda	#<opt_date_fmt
		ldy	#>opt_date_fmt
		jsr	_find_cmnd
		bcs	error10

		sta	opt_num

		; AMERICAM	=> $2f + $00
		; ANSI		=> $2e + $40
		; BRITISH	=> $2f + $80
		; FRENCH	=> $2f + $80
		; GERMAN	=> $2e + $80
		; ITALIAN	=> $2d + $80

		lda	date_fmt
		and	#$10

		ldx	opt_num
		ora	date_fmt_tbl,x
		sta	date_fmt

		clc
		rts

	error10:
		; 10 Syntax error.
		lda	#10
		ldy	lex_save_y
		rts
.endproc


