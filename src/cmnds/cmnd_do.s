
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

.import get_term
.import skip_spaces

.import string
.import param_type
.import main_input_mode

.import file_open
.import file_close

.import main_fp

.import reset_labels

.import buffer_reset

.import init_argv
.import _argc

.import fn_str
.import fn_ltoc
.import fn_dtoc

; From scan.s
.import scan

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_do

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
		unsigned char filename[FILENAME_LEN]

		; [ compatibilité submit $0=<nom_du_pgm>
		dummy: .byte "xx "
		; ]
		unsigned char cmdline[80]

		unsigned char save_x
		unsigned char save_y
.popseg

;----------------------------------------------------------------------
;			Chaines statiques
;----------------------------------------------------------------------
.pushseg
	.segment "RODATA"
		.ifndef SUBMIT
			default_ext: .byte "grp."
		.else
			default_ext: .byte "bus."
		.endif
.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"

;----------------------------------------------------------------------
; cmnd_do: instruction DO <file> [WITH parameters...]
;
; Entrée:
;	A: n° de token de WITH
;	X: offset des paramètres
;	Y: offset vers la fin de la ligne
;
; Sortie:
;
; Variables:
;	Modifiées:
;		main_input_mode
;	Utilisées:
;		main_fp
; Sous-routines:
;	open
;	close
;----------------------------------------------------------------------
.proc cmnd_do
		; Sauvegarde l'offset vers le premier paramètre
		stx	save_y

		; Sauvegarde le nom du fichier pour les ouvertures
		; suivantes (reopen)
		; On le copie également dans la ligne de commande pour get_argv
		ldx	#$ff
	loop:
		inx
		cpx	#FILENAME_LEN
		bcs	endloop
		lda	string,x
		sta	filename,x
		sta	cmdline,x
		bne	loop

		; Ajoute '.prg' si pas d'extension
		lda	filename-2,x
		cmp	#'.'
		beq	no_default
		lda	filename-3,x
		cmp	#'.'
		beq	no_default
		lda	filename-4,x
		cmp	#'.'
		beq	no_default

		ldy	#$03
	loop_ext:
		lda	default_ext,y
		sta	filename,x
		sta	cmdline,x
		inx
		dey
		bpl	loop_ext

	no_default:
		lda	#' '
		sta	cmdline,x

	endloop:
		lda	#$00
		sta	filename,x
		inx
		sta	cmdline,x

		stx	save_x

		; On essaye d'ouvrir le fichier
		lda	#<filename
		ldy	#>filename
		jsr	file_open
		bcc	_close
		rts
	_close:
		; On peut refermer le fichier, il sera ouvert par fgetline
		jsr	file_close

		; Ajout des arguments dans la ligne de commande
	loop_args:
		ldy	save_y
		lda	line_ptr
		ldx	line_ptr+1
		jsr	skip_spaces
		bne	suite
		jmp	end

	suite:
		lda	line_ptr
		jsr	get_term
		bcs	error10

		sty	save_y

		lda	param_type
		and	#$7f
		cmp	#'C'
		beq	arg_str

		cmp	#'N'
		beq	arg_num

		cmp	#'L'
		beq	arg_logic

		cmp	#'D'
		bne	error10

	arg_date:
		jsr	fn_dtoc
		bcc	append

	arg_logic:
		jsr	fn_ltoc
		bcc	append

	arg_num:
		jsr	fn_str

	append:
		ldx	save_x
		dex
		ldy	#$ff
	loop_str2:
		inx
		cpx	#80
		bcs	errorxx
		iny
		lda	string,y
		sta	cmdline,x
		bne	loop_str2

	add_sep:
		lda	#' '
		sta	cmdline,x
		inx
		lda	#$00
		sta	cmdline,x
		stx	save_x
		lda	line_ptr
		ldx	line_ptr+1
		ldy	save_y
		jsr	skip_spaces
		beq	end
		cmp	#','
		bne	error10
		iny
		sty	save_y
		bne	loop_args

	arg_str:
		ldx	save_x
		lda	#'''
		sta	cmdline,x
		ldy	#$ff
	loop_str:
		inx
		cpx	#80
		bcs	errorxx
		iny
		lda	string,y
		sta	cmdline,x
		bne	loop_str
		lda	#'''
		sta	cmdline,x
		inx
		bne	add_sep

	error10:
		; 10 Syntax error.
		lda	#10
		bne	errorxx

	end:
		; [ compatibilité submit $0=<nom_du_pgm>
		lda	#<(cmdline-3)
		ldy	#>(cmdline-3)
		; ]
		; [ sinon
		;lda	#<cmdline
		;ldy	#>cmdline
		; ]
		jsr	init_argv
		sta	_argc

		lda	main_fp
		sta	main_input_mode

		; Reset des labels
		jsr	reset_labels

		; Scan des blocs IF / ELSE / ENDIF
		jsr	scan
		bcs	errorxx

		; On peut refermer le fichier, il sera ouvert par fgetline
		; déjà fait par fgsets
		; jsr	file_close

		; Pas de curseur allumé en mode batch
		; cursor off

		; Reset du buffer (déjà fait par scan)
		; jsr	buffer_reset

		rts


	error18:
		; 18 Line exceeds maximum of 254 characters.
		lda	#18

	errorxx:
		ldy	save_y
		sec
		rts
.endproc


