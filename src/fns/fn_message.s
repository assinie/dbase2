
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

.import global_dbaserr

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
	;	unsigned char save_x
	;	fn_message_cmnd: .asciiz "dbaserr -q 0,%d /a/dbase.msg"
	;	unsigned char string1[80]
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
;		global_dbaserr
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
		lda	global_dbaserr
		beq	internal_msg

	;	jsr	fn_fprintf
	;	bne	internal_msg

		lda	#<fn_message_cmnd
	;	lda	#<string1
		sta	pfac
	;	lda	#>string1
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

;----------------------------------------------------------------------
;
; Entrée:
;	fns_ptr: pointe vers la chaine du code erreur
;
; Sortie:
;	A: Code erreur
;	X: modifié
;	Y: modifié
;	Z: 0-> erreur, 1-> Ok
;
; Variables:
;	Modifiées:
;		pfac
;		string1
;		save_x
;
;	Utilisées:
;		fn_message_cmnd
;		fns_ptr
;
; Sous-routines:
;	-
;----------------------------------------------------------------------
.if 0
.proc fn_fprintf
		; Recherche de %d dans la chaine
		ldx	#$ff
	loop:
		inx
		lda	fn_message_cmnd,x
		sta	string1,x
		beq	error10

		cmp	#'%'
		bne	loop

		lda	fn_message_cmnd+1,x
		cmp	#'d'
		bne	loop

		; Sauvegarde l'index (x: offser de '%')
		stx	save_x

		; Conversion
	;	ldx	#<pfac
	;	ldy	#>pfac
	;	jsr	binstr

	;	stx	fns_ptr
	;	sty	fns_ptr+1

		; Ajoute la chaine à string et default_err_msg
	;	ldx	save_x
		dex

		ldy	#$ff
	loop1:
		iny
		inx
		lda	(fns_ptr),y
		sta	string1,x
		bne	loop1

		; Copie la fin de la chaine
		ldy	save_x
		iny
		dex
	loop2:
		iny
		inx
		lda	fn_message_cmnd,y
		sta	string1,x
		bne	loop2

	end:
		rts

	error10:
		; 10: Syntax error.
		lda	#10
		rts
.endproc
.endif
