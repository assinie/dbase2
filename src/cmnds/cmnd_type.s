
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
.export cmnd_type

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
.proc cmnd_type
		; Calcule la taille de la chaine
		ldy	#$ff
	loop_len:
		iny
		lda	string,y
		bne	loop_len

		; TODO: Utiliser une constante pour la longueur max de string (128)
		cpy	#(128-5)
		bcs	error10

		; Déplace la chaine de 4 octets
	loop_copy:
		lda	string,y
		sta	string+4,y
		dey
		bpl	loop_copy

		; Insère 'cat ' au début de la ligne
		lda	#'c'
		sta	string
		lda	#'a'
		sta	string+1
		lda	#'t'
		sta	string+2
		lda	#' '
		sta	string+3

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


