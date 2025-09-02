
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
.importzp line_ptr

.import skip_spaces

.import get_term

.import param_type
.import string
.import value
.import bcd_value

.importzp pfac

;.import xbindx
;.import binstr
.import fn_str
.import fn_dtoc
.import fn_ltoc

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_print

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
; TOKEN_PRINT_NOCR = 13-2

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"

	.segment "DATA"
		unsigned char no_cr

		; Pour gérer la liste de paramètres
		unsigned char save_y
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
; Note: dBASE: ? n'accepte qu'un paramètre de type chaine
;
; Entrée:
;	A: n° de token '?' ou '??'
;	X: offset des paramètres
;	Y: offset vers la fin de la ligne
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
.proc cmnd_print
		; Sauvegarde l'offset vers le premier paramètre
		stx	save_y

		; A = n° commande
	.ifndef SUBMIT
		; Pour dBase2 TOKEN_PRINT_NOCR > TOKEN_PRINT
		cmp	#TOKEN_PRINT_NOCR
	.else
		; Pour submit TOKEN_PRINT > TOKEN_PRINT_NOCR
		cmp	#TOKEN_PRINT
	.endif
		ror	no_cr

		; [ liste d'arguments
	loop_args:
		ldy	save_y
		lda	line_ptr
		ldx	line_ptr+1
		jsr	skip_spaces
		beq	end

		lda	line_ptr
		jsr	get_term
		bcs	errorxx

		sty	save_y
		; ]

		lda	param_type
		and	#$7f

		cmp	#'C'
		beq	_string

		cmp	#'N'
		beq	numeric

		cmp	#'L'
		beq	logical

		cmp	#'D'
		bne	error10

	date:
		jsr	fn_dtoc
		bcc	_string

	logical:
		jsr	fn_ltoc
		bcc	_string

	numeric:
		jsr	fn_str

	_string:
		print	string

		; [ liste d'arguments
		lda	line_ptr
		ldx	line_ptr+1
		ldy	save_y
		jsr	skip_spaces
		beq	end
		cmp	#','
		bne	error10
		cputc	' '
		iny
		sty	save_y
		bne	loop_args
		; ]

	end:
		; ? ou ??
		lda	no_cr

	.ifndef SUBMIT
		; Pour dBase2 TOKEN_PRINT_NOCR > TOKEN_PRINT
		bmi	no_crlf
	.else
		; Pour submit TOKEN_PRINT > TOKEN_PRINT_NOCR
		bpl	no_crlf
	.endif

		crlf

	no_crlf:
		clc
		rts

	error10:
		; 10 Syntax error.
		lda	#10

	errorxx:
		ldy	save_y
		sec
		rts
.endproc

