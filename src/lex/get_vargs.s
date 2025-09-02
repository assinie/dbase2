;----------------------------------------------------------------------
;			includes cc65
;----------------------------------------------------------------------
.feature string_escapes
.feature loose_char_term

.include "telestrat.inc"

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
.include "macros/utils.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
; From main
.import _argc

; From lex
.importzp lex_work_ptr
;.importzp pfac
.import ident
.import ident1
.import param_type

.import skip_spaces

.import get_argv

.import get_string
.import get_int
.import get_ident

.import cmnd_store

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_vargs

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
;				Page Zéro
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"
.popseg

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "DATA"
		unsigned char param_nb
		unsigned char save_a2
		unsigned char save_x2
		unsigned char save_y2

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
; arg1 [, arg2, ...]
;
; /?\ À transférer dans cmnd_parameters.
;
; Entrée:
;	AX: adresse de la ligne
;	Y: offset
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
.proc get_vargs
		sta	save_a2
		stx	save_x2
		sty	save_y2

		; dbase2 <fichier> param1 param2...
		;    0       1        2      3  ...
		lda	#$02
		sta	param_nb

	_vargs:
		lda	param_nb
		cmp	_argc
		bcs	error94

		lda	save_a2
		;ldx	lex_save_x
		;ldy	save_y2
		jsr	skip_spaces
		beq	error10

		lda	save_a2
		jsr	get_ident
		sty	save_y2
		bcs	error10

		; Sauvegarde le nom de la variable
		; (get_param écrase ident)
		ldx	#IDENT_LEN
	loop:
		lda	ident,x
		sta	ident1,x
		dex
		bpl	loop

		; Récupère les paramètres depuis la ligne de commande
		; [
		; getmainarg param_nb, (_argv), lex_work_ptr
		; lda	lex_work_ptr
		; ldx	lex_work_ptr+1
		; ldy	#$00
		; /!\ ATTENTION: get_expr attend que les chaînes soient entre
		; "" ou '', pas valable pour la ligne de commande mais ok si
		; appel de procédure avec DO <procedure> WITH arg1,arg2,...
		; jsr	get_expr
		; bcs	error10
		; ]
		; [ Fonctionne avec le nouveau get_argv
		;   un paramètre est soit un nombre soit une chaîne
		lda	#'N'
		sta	param_type

		ldx	param_nb
		jsr	get_argv
		sta	lex_work_ptr
		sty	lex_work_ptr+1

		;lda	lex_work_ptr
		ldx	lex_work_ptr+1
		ldy	#$00
		jsr	get_int
		bcs	string
		beq	store

	string:
		lda	#'C'
		sta	param_type

		lda	lex_work_ptr
		ldx	lex_work_ptr+1
		ldy	#$00
		clc
		jsr	get_string
		; ]

	store:
		; Restaure ident
		ldx	#IDENT_LEN
	loop1:
		;inx
		lda	ident1,x
		sta	ident,x
		;bne	loop1
		dex
		bpl	loop1

		jsr	cmnd_store
		bcs	error

		inc	param_nb

		lda	save_a2
		ldx	save_x2
		ldy	save_y2
		jsr	skip_spaces
		beq	end
		cmp	#','
		bne	error10
		iny
		bne	_vargs

	error10:
		; 10 Syntax error.
		lda	#10
		bne	error

	error94:
		; Renvoie le nombre de paramètres lus dans X
		tax
		; 94 Wrong number of parameters.
		lda	#94

	error:
		ldy	save_y2
		sec
		rts

	end:
		lda	param_nb
		cmp	_argc
		bne	error94
		clc
		rts
.endproc

