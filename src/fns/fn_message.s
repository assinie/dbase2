
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
.import string

.importzp fns_ptr
.import fns_save_y

.import error_code
.import fn_message_cmnd
.import default_err_msg

.import fn_run

.import binstr

.import fExternal_error

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_message

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
; message()
;
; Entrée:
;
; Sortie:
;	Y: inchangé
;	C: 0
;
; Variables:
;	Modifiées:
;		fns_ptr
;		fns_save_y
;		pfac
;		fn_message_cmnd
;		default_err_msg
;		string
;		param_type
;
;	Utilisées:
;		fExternal_error
;
; Sous-routines:
;	fn_run
;	binstr
;	cursor
;----------------------------------------------------------------------
.proc fn_message
		sty	fns_save_y

		; Place le code erreur dans pfac
		lda	error_code
		sta	pfac

		lda	#$00
		sta	pfac+1
		sta	pfac+2
		sta	pfac+3

		; Efface la dernière valeur utilisée
		lda	#' '
		sta	fn_message_cmnd+13
		sta	fn_message_cmnd+14
		sta	fn_message_cmnd+15

		sta	default_err_msg+9
		sta	default_err_msg+10
		sta	default_err_msg+11

		ldx	#<pfac
		ldy	#>pfac
		jsr	binstr

		stx	fns_ptr
		sty	fns_ptr+1
		tay

		dey
	loop:
		lda	(fns_ptr),y
		sta	fn_message_cmnd+13,y
		sta	default_err_msg+9,y
		dey
		bpl	loop

		; Utilisation de dbaserr?
		lda	fExternal_error
		beq	internal_msg

		lda	#<fn_message_cmnd
		sta	pfac
		lda	#>fn_message_cmnd
		sta	pfac+1

		jsr	fn_run
		bcc	end

	internal_msg:
		; Message par défaut
		ldx	#$ff
	loop1:
		inx
		lda	default_err_msg,x
		sta	string,x
		bne	loop1

	end:
		cursor	on

		lda	#'C'
		sta	param_type

		ldy	fns_save_y
		clc
		rts
.endproc

