
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
.importzp fns_ptr

.import param_type
;.import ident
;.import value
.import string
;.import bcd_value
;.import logic_value
.importzp pfac1

.import is_pfac_byte

.import fns_save_y

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_peek_str

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
;	AX = lex_ptr
;	Y = offset vers le caractère suivant dans la ligne
;
; Sortie:
;	C: 0-> Ok, 1-> Erreur
;	A: Code erreur ou 'C'
;	X: inchangé
;	Y: inchangé
;
; Variables:
;	Modifiées:
;		- fns_save_y
;		- fns_ptr
;		- string
;		- param_type
;
;	Utilisées:
;		- pfac
;		- pfac1
; Sous-routines:
;	- is_pfac_byte
;----------------------------------------------------------------------
.proc fn_peek_str
		sty	fns_save_y

		jsr	is_pfac_byte
		bne	error46

		ldy	pfac
		beq	end

		; /!\ TODO: faire le test par rapport à strlen(string) et
		;           déporter le test par rapport à VARS_DATALEN dans
		;           cmnd_store.s
		;
		; Longueur maximale d'une chaine = 128 caractères
		; cpy	#$80
		; Longueur maximale pour une variable chaine = 32 caractères
		cpy	#VARS_DATALEN
		bcs	error46

		lda	pfac1+2
		ora	pfac1+3
		bne	error46

		lda	pfac1
		sta	fns_ptr
		lda	pfac1+1
		sta	fns_ptr+1

		ldy	#$00

	loop:
		lda	(fns_ptr),y
		sta	string,y
		iny
		dec	pfac
		bne	loop

	end:
		lda	#$00
		sta	string,y

		ldy	fns_save_y

		lda	#'C'
		sta	param_type
		clc
		rts

	error46:
		; 46 Illegal value.
		lda	#46
		sec
		rts
.endproc

