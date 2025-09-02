
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
.import readline

.importzp line_ptr

.import submit_line

.import string
.import ident
.import param_type

.import cmnd_store
.import get_expr
.import get_string

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_input

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
		; unsigned short ptr

	.segment "DATA"
		unsigned char ident_save[IDENT_LEN+1]
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
.proc cmnd_input

		; Sauvegarde le nom de la variable (ident peut être écrasé
		; par get_expr)
		ldx	#IDENT_LEN
	loop:
		lda	ident,x
		sta	ident_save,x
		dex
		bpl	loop

		; Message?
		lda	string
		beq	_input

	disp_string:
		print	string


	_input:
		input	":", ::LINE_MAX_SIZE, line_ptr
		; Ligne vide?
		bne	set_var

	error:
		prints	"Syntax error, re-enter\x0d\x0a"
		jmp	_input

	set_var:
		; TODO: placer la ligne saisie dans la variable ident
		; var_type='C' si la ligne commence par '"'
		; Si chaine de caractères sans "" -> expression à évaluer
		; Si erreur de conversion -> "Syntax error, re-enter"
		; (mais ne réaffiche pas le message [dBaseII])

		lda	line_ptr
		ldx	line_ptr+1
		ldy	#$00
		lda	(line_ptr),y
		cmp	#'"'
		beq	g_string
		cmp	#'''
		bne	expr

	g_string:
		lda	line_ptr
		jsr	get_string
		bcs	error
		lda	#'C'
		sta	param_type
		bcc	update

	expr:
		; /!\ ATTENTION: l'appel à get_expr permet de saisie une
		;     expression at non uniquement un nom de variable.
		;     C'est aussi le comportement de dBASE III.
		;
		; TODO: Pour que get_expr puisse reconnaitre une fonction il faut
		; modifier _find_cmnd qui utilise submit_line et non line_ptr
		; (voir aussi get_expr qui appelle _find_cmnd)
		; [
		; Copie de (line_ptr) dans submit_line
		ldy	#$ff
	loop1:
		iny
		lda	(line_ptr),y
		sta	submit_line,y
		bne	loop1
		ldy	#$00
		; ]

		lda	line_ptr
		jsr	get_expr
		bcs	error

	update:
		; Restaure ident
		; On copie la totalité du buffer pour effacer totalement un
		; éventuel autre identificateur.
		; Ex: "input to msg" avec réponse: errorlevel
		; Si on n'efface pas tout on va avoir
		; ident: M S G \00 R L E V E L \00
		ldx	#IDENT_LEN
	loop_id:
		lda	ident_save,x
		sta	ident,x
		dex
		bpl	loop_id

		; Sauvegarde de la saisie dans la variable
		jsr	cmnd_store
	end:
		clc
		rts
.endproc

