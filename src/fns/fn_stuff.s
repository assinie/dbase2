
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
.import param1
.importzp pfac1
.import bcd_value
.import logic_value

.import is_pfac_byte

.import fns_save_y

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_stuff

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
; STUFF(<expC1>, <expN1>, <expN2>, <expC2>)
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
.proc fn_stuff
		; param1 = expC1
		; pfac1 = expN1
		; pfac = expN2
		; string = expC2
		sty	fns_save_y

		jsr	is_pfac_byte
		bne	error11

		; Valeur < 256?
		lda	pfac1+1
		ora	pfac1+2
		ora	pfac1+3
		bne	error11

		; Si la expC1 est vide, le résultat est expC2
		lda	param1
		beq	end

		; Calcule la longueur de expC1
		ldx	#$ff
	loop_len:
		inx
		lda	param1,x
		bne	loop_len

		; Point de départ >= len(expC1)?
		; (len(expC1) <= point de départ)
		cpx	pfac1
		beq	concat
		bcc	concat

		; expN1+expN2 >= len(expC1)?
		; (len(expC1) < expN1+expN2)
		clc
		lda	pfac
		adc	pfac1
		sta	_cpx+1
	_cpx:
		cpx	#$ff
		;beq	concat1
		bcc	concat1

		; Sauvegarde l'index de fin d'insertion
		tax
		; -1 parce que le premier caractère est en param1[0] et non param1[1]
		dex

		; Ici il faut insérer expC2 dans expC1
		; Calcule la longueur de expC
		ldy	#$ff
	loop_len2:
		iny
		lda	string,y
		bne	loop_len2

		; Ajoute la fin de expC1 à expC2
		dex
		dey
	loop_append:
		inx
		iny
		lda	param1,x
		sta	string,y
		bne	loop_append

	concat1:
		; Ici expN1+expN2 >= len(expC1)
		; donc on ajoute expC2 à expC1
		ldx	pfac1
		; -1 parce que le premier caractère est en param1[0] et non param1[1]
		dex

		; Concatène les deux chaines
	concat:
		ldy	#$ff
		dex

	loop_concat:
		inx
		; Chaine résultante trop longue?
		; TODO: utiliser une variable pour la longueur de param1/string
		cpx	#128
		bcs	error102

		iny
		lda	string,y
		sta	param1,x
		bne	loop_concat

		; Copie expC1 dans string (x=len(expC1)
	copy:
		lda	param1,x
		sta	string,x
		dex
		bpl	copy

	end:
		lda	#'C'
		sta	param_type

		ldy	fns_save_y
		clc
		rts

	error102:
		; 102 STUFF():  String too large.
		lda	#102
		bne	error

	error11:
		; 11 Invalid function argument.
		lda	#11

	error:
		ldy	fns_save_y
		sec
		rts
.endproc

