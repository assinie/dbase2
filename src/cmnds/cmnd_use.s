
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

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "include/dbase.inc"
.include "macros/readline.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
; From cmnd_set_message
.import status_display

; From yacc.s
.import token_start

; From lex
.import string

; From dbf.lib
.import dbf_open
.import dbf_close
.import dbf_goto_top

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_use

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
		default_ext: .byte $00,"fbd."
.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"

;----------------------------------------------------------------------
;
; Entrée:
;	A: n° de token de USE
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
.proc cmnd_use
		lda	string
		beq	close_all

;		prints	"use "
;		print	string
;		crlf

		; Calcule la longueur de la ligne
		ldx	#$ff
	loop_len:
		inx
		lda	string,x
		bne	loop_len

		; X pointe vers le $00 final
		; -1 pour pointer le dernier caractère
		; -2 parce que le '.' ne peut pas être le dernier caractère

		; Vérifie si il y a une extension
		lda	#'.'
		cmp	string-2,x
		beq	no_default
		cmp	string-3,x
		beq	no_default
		cmp	string-4,x
		beq	no_default

		; Ajoute l'extension par défaut
		ldy	#$04
	loop_default:
		lda	default_ext,y
		sta	string,x
		inx
		dey
		bpl	loop_default

		; Ouverture du fichier
	no_default:
		lda	#<string
		ldy	#>string
		jsr	dbf_open
		cmp	#EOK
		bne	error

		; Déplacement vers le premier enregistrement
		jsr	dbf_goto_top

		; clc
		; rts
		jmp	status_display

	error:
		; A = EINVAL ou ENOENT
		cmp	#EINVAL
		bne	errorNotFound

		; 15: Not a dBase database.
		lda	#15
		bne	endError

	errorNotFound:
		; 01: File does not exist.
		lda	#01

	endError:
		ldy	token_start
		sec
		rts

	close_all:
		; Pas de paramètre, on ferme tous les fichiers
		; prints	"close all files"
		; crlf
		jsr	dbf_close

	end:
		; clc
		; rts
		jmp	status_display
.endproc


