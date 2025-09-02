
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
.include "case.mac"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "include/dbase.inc"
.include "macros/readline.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.importzp _argv
.import _argc

.importzp line_ptr

.import submit_line

.import get_param
.import get_ident
.import param_type
.import string
.import fn_dtoc
.import fn_ltoc
.import fn_str

; From get_args.s
.import init_argv
.import get_argv

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export submit

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
		unsigned short ptr

	.segment "DATA"
		unsigned char save_x
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
;
; Entrée:
;	-
; Sortie:
;	-
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc submit
		ldx	#$ff
		ldy	#$ff

	loop:
		inx
	loop1:
		iny
	loop2:
		lda	(line_ptr),y
		beq	eol

	parse:
		sta	submit_line,x

		cmp	#PARAM_PREFIX
		bne	ctrl

		iny
		lda	(line_ptr),y
		beq	eol

		cmp	#PARAM_PREFIX
		beq	loop

	param:
		sta	submit_line,x

		cmp	#'9'+1
		bcs	variable
		cmp	#'0'
		bcc	loop

		; Récupération du paramètre
		; C=1
		; ('0'-1 pour sauter le nom de l'interpréteur [dbase2])
		sbc	#'0'-1
		cmp	_argc
		; bcs	error12
		bcs	loop1

		stx	save_x
		sty	save_y
		tax

		; [
		; getmainarg X, (_argv), ptr
		; ]
		; [
		jsr	get_argv
		sta	ptr
		sty	ptr+1
		; ]

		ldx	save_x

		dex
		ldy	#$ff
	loop_arg:
		inx
		iny
		lda	(ptr),y
		sta	submit_line,x
		bne	loop_arg

		ldy	save_y
		bne	loop1
		beq	error18

	ctrl:
		cmp	#CTRL_PREFIX
		bne	loop

		iny
		lda	(line_ptr),y
		beq	eol

		cmp	#CTRL_PREFIX
		beq	loop


	ctrl_char:
		sta	submit_line,x
		cmp	#'['+1
		bcs	loop

		cmp	#'A'
		bcc	loop

		; C=1
		sbc	#'A'-1
		sta	submit_line,x
		jmp	loop

	eol:
		sta	submit_line,x

		; Recopie la nouvelle ligne dans (line_ptr)
		ldy	#$ff
	eol_copy:
		iny
		lda	submit_line,y
		sta	(line_ptr),y
		bne	eol_copy

		;print	(line_ptrà
		;crlf

		clc
		rts

	variable:
		; Récupération de la variable
		stx	save_x
		sty	save_y
		lda	line_ptr
		ldx	line_ptr+1
		ldy	save_y

		; Au retour de get_param, Y pointe vers le caractère suivant
		jsr	get_param
		bcs	error12

		sty	save_y

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
		ldx	save_x
		;dex
		ldy	#$ff
	loop_string:
		inx
		beq	error18
		iny
		lda	string,y
		sta	submit_line-1,x
		bne	loop_string

		; Décrémente X car submit_line,x pointe après le '\0' final
		dex

		; Au retour de get_param, Y pointe vers le caractère suivant
		; donc on ne l'incrémente pas
		ldy	save_y
		jmp	loop2

	error18:
		; 18 Line exceeds maximum of 254 characters.
		lda	#18
		sec
		rts

	error10:
		; 10 Syntax error.
		lda	#10
		sec
		rts

	error12:
		; 11 Invalid function argument.
		; 12 Variable not found.
		; 46 Illegal value.
		; 48 Field not found.
		; 106 Invalid index number.
		; [
		; lda	#12
		; sec
		; rts
		; ]
		; [ $var => var
		; ldx	save_x
		; jmp	loop2
		; ]
		; [ Compatibilité submit: $var => ''
		lda	line_ptr
		ldx	line_ptr+1
		clc
		jsr	get_ident
		ldx	save_x
		jmp	loop2
.endproc
