
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
; From main.s
.importzp line_ptr
.import global_cursor
.import global_status

; From lex
.importzp lex_ptr
.importzp lex_work_ptr
.import get_expr_str
.import get_term_str
.import string

; From fns
.import fn_isopen
.import fn_upper
.import fn_dbf_recno
.import fn_dbf_reccount
.import fn_str

; From cmnd_set
.import opt_num
.import get_option

; From fn_alias
.import fn_alias

; From dbf.lib
.import fn_dbf
.import fn_eof

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_set_message
.export message_display
.export status_display

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
		message:
			.asciiz "        Enter a dBase command.        "
		status:
			.asciiz "Cmd Line |          |                 "
.popseg

;----------------------------------------------------------------------
;			Chaines statiques
;----------------------------------------------------------------------
.pushseg
	.segment "RODATA"
			;       "123456789.123456789.123456789.123456789."
		default:
			.asciiz "        Enter a dBase command.        "
		eof_msg:
			.asciiz "EOF"
		rec_msg:
			.asciiz "Rec: "
		cmd_msg:
			.asciiz "Cmd Line "
.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"

;----------------------------------------------------------------------
; SET FILTER TO [<condition>] | [FILE <filename> | ?]
;
; Entrée:
;	A: numéro option (OFF, ON, TO)
;	X: -
;	Y: offset vers le paramètre
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
.proc cmnd_set_message
		; Sauvegarde l'offset
		; sty	save_y+1

		; TO
		lda	(lex_ptr),y
		beq	set_default

		; Vérifie la syntaxe du filter
		lda	lex_ptr
		ldx	lex_ptr+1
		jsr	get_term_str
		bcs	end_err
		; Ici:
		;      A = code erreur
		;      X = len(string)
		;      Y = offset

		; Fin de ligne après le filtre?
		lda	(lex_ptr),y
		bne	error10

		cpx	#39
		bcs	error10

		; Sauvegarde l'offset
		sty	save_y+1

		; Efface la le message
		stx	save_x+1
		lda	#' '
		ldx	#38
	loop_blank:
		sta	message,x
		dex
		bpl	loop_blank

		; Centre le message
		sec
		lda	#38
	save_x:
		sbc	#$ff
		lsr
		tax

		ldy	#$00
	loop:
		lda	string,y
		beq	display
		sta	message,x
		iny
		inx
		bne	loop

	display:
	save_y:
		ldy	#$ff
		jsr	message_display
		clc
		rts

	set_default:
		ldx	#$ff
	loop_default:
		inx
		lda	default,x
		sta	message,x
		bne	loop_default

	end:
		jmp	message_display

		; Restaure l'offset
		;ldy	save_y+1
		;clc
		;rts

	error10:
		; 10: Syntax error
		lda	#10
	end_error:
		sec
	;save_y:
		; ldy	#$ff
	end_err:
		rts

.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	- Y: offset
;
; Sortie:
;	- Y: inchangé
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	- display
;----------------------------------------------------------------------
.proc message_display
		lda	global_status
		bne	disp

		clc
		rts

	disp:
		ldx	#$40+27
		jmp	display
.if 0
		sty	save_y+1
		lda	#OPT_STATUS
		jsr	get_option
		beq	end

		clc
		lda	SCRX
		adc	#$40
		pha
		lda	SCRY
		adc	#$40
		pha

		lda	#$10
		sta	SCRX
		lda	#$1b
		sta	SCRY
		cputc	$1f
		cputc	$5b				; $5b = $40 + 27
		cputc	$42				; $42 = *40 + 2
		print	message
		cputc	$1f
		pla
		cputc
		pla
		cputc

	end:
	save_y:
		ldy	#$ff
		rts
.endif
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	- Y: offset
;
; Sortie:
;	- Y: inchangé
;
; Variables:
;	Modifiées:
;		- status
;	Utilisées:
;		- string
; Sous-routines:
;	- get_option
;	- fn_alias
;	- display
;----------------------------------------------------------------------
.proc status_display
	;	lda	#OPT_STATUS
	;	jsr	get_option
		lda	global_status
		bne	ok

		clc
		rts

	ok:
		sty	save_y+1

		jsr	fn_alias
		ldx	#$ff
	loop:
		inx
		lda	string,x
		beq	isopen
		beq	open

		sta	status+10,x
		bne	loop

	isopen:
		ldx	#$00
		jsr	fn_isopen
		; bcc	open
	;	bcs	end
		bcs	end_reccount

	;	lda	#' '
	;	ldx	#20
	;loop_clear:
	;	sta	status+21,x
	;	dex
	;	bpl	loop_clear
	;	bmi	end

	open:
		ldy	#$ff
	loop_rec:
		iny
		lda	rec_msg,y
		beq	end_rec
		sta	status+21,y
		bne	loop_rec

	end_rec:
		; Position dans le fichier .dbf
		jsr	fn_eof
		beq	recno

		ldx	#$00
	loop_eof:
		lda	eof_msg,x
		beq	reccount
		sta	status+21,y
		inx
		iny
		bne	loop_eof

	recno:
		jsr	fn_dbf_recno
		jsr	fn_str

		ldx	#$00
	loop_recno:
		lda	string,x
		beq	reccount
		sta	status+21,y
		inx
		iny
		bne	loop_recno

		; Nombre d'enregistrements du fichier .dbf
	reccount:
		sty	save_x+1
	;	sty	save_y+1
		jsr	fn_dbf_reccount
		jsr	fn_str

	save_x:
		ldx	#$ff
		lda	#'/'
		sta	status+21,x

		ldy	#$ff
	loop_reccount:
		inx
		iny
		lda	string,y
		beq	end_reccount
		sta	status+21,x
		bne	loop_reccount

	end_reccount:
		lda	#' '
	loop_clr:
		cpx	#17
		bcs	@ok
		sta	status+21,x
		inx
		bne	loop_clr

	@ok:
	save_y:
		ldy	#$ff
	end:
		ldx	#$40+25
		jmp	display
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	- Y: offset
;
; Sortie:
;	- Y: inchangé
;	- C: 0
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		- message
;		- status
;		- SCRX
;		- SCRY
; Sous-routines:
;	- get_options
;	- cputc
;	- print
;----------------------------------------------------------------------
.proc display
		sty	save_y+1
		; Test fait par l'appelant
		; [
		; lda	#OPT_STATUS
		; jsr	get_option
		; beq	end_no_display
		; ]

		stx	save_x+1
		cursor	off
	save_x:
		ldx	#$ff

		clc
		lda	SCRX
		adc	#$40
		pha
		lda	SCRY
		adc	#$40
		pha

		lda	#$10
		sta	SCRX
		lda	#$1b
		sta	SCRY
		; /!\ Suppose X inchangé par cputc
		cputc	$1f
		txa
		cputc
		cputc	$42				; $42 = *40 + 2

		cpx	#$59				; $5b = $40 + 25
		bne	disp_message

	disp_status:
		; X = $59
		print	status
		jmp	end

	disp_help:
		; X = $5A

	disp_message:
		; X = $5b
		print	message

	end:
		cputc	$1f
		pla
		cputc
		pla
		cputc

		lda	global_cursor
		beq	end_no_display
		cursor	on

	end_no_display:
	save_y:
		ldy	#$ff
		clc
		rts
.endproc

