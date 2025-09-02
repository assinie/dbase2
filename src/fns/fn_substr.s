
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
.import ident
.import value
.import string
.import bcd_value
.import logic_value

.import param1
.importzp pfac1

.import is_pfac_byte

.import fns_save_y

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_substr

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
; substr(<expC>,<expN1>, <expN2>)
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
.proc fn_substr
		sty	fns_save_y

		; Chaine vide.
;		lda	string
;		beq	end_null

		; Point de départ > 255?
		lda	pfac1+1
		ora	pfac1+2
		ora	pfac1+3
		bne	error62

		; Index pour la copie
		ldy	#$00

		; Calcul longueur string
		ldx	#$ff
	loop:
		inx
		lda	string,x
		bne	loop

		cpx	pfac1
		; Point de départ = len(expC)?
		;beq	end_null

		; Point de départ > len(expC)?
		bcc	error62

		; Longueur à copier (modulo 256) dans pfac

		; La chaine commence à l'offset 0 mais le 1er caractère est 1
		; donc on corrige X
		ldx	pfac1
		dex

		; Copie la chaine
	loopC:
		lda	string,x
		sta	string,y
		beq	end_null

		inx
		iny
		dec	pfac
		bne	loopC

	end_null:
		lda	#$00
		sta	string,y

		lda	#'C'
		sta	param_type

		ldy	fns_save_y

		clc
		rts

	error62:
		; SUBSTR() : Start point out of range.
		lda	#62
		sec

		ldy	fns_save_y
		rts

.endproc

