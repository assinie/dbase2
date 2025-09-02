
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
.import token_start
.import string
.importzp pfac

.import cmnd_run

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_dir

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
		default_mask:
			.ifdef SUBMIT
				; [ submit
				.asciiz "*.*"
				; ]
			.else
				; [ dBase
				.asciiz "*.dbf"
				; ]
			.endif
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
.proc cmnd_dir
		; Calcule la taille de la chaine
		ldy	#$ff
	loop_len:
		iny
		lda	string,y
		bne	loop_len

		; [ masque par défaut
		cpy	#$00
		bne	make_cmd

		dey
	loop_default:
		iny
		lda	default_mask,y
		sta	string,y
		bne	loop_default
		; ]

	make_cmd:
		; TODO: Utiliser une constante pour la longueur max de string (128)
		cpy	#(128-4)
		bcs	error10

		; Déplace la chaine de 3 octets
	loop_copy:
		lda	string,y
		sta	string+3,y
		dey
		bpl	loop_copy

		; Insère 'ls ' au début de la ligne
		lda	#'l'
		sta	string
		lda	#'s'
		sta	string+1
		lda	#' '
		sta	string+2

		lda	#<string
		sta	pfac
		lda	#>string
		sta	pfac+1
		jmp	cmnd_run

	error10:
		; 10 Syntax error.
		lda	#10
		ldy	token_start
		sec
		rts
.endproc


