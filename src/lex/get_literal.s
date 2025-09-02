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
; From yacc
.importzp yacc_ptr

; From lex
.import lex_strict
.import lex_prev_y
.import lex_save_y

.import ident

.import get_ident

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_literal

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
; [<literal>]
;
; /!\ ATTENTION: détruit ident
;
; Entrée:
;	AX: adresse de la ligne
;	Y: offset
;	C: 1-> délimiteur ' ', 0-> délimiteur non alphanumérique
;	V: 1-> case sensitive
;
; Sortie:
;	A: dernier caractère lu
;	Y: offset dernier caractère lu
;	C: 0->Ok, 1->Erreur
;	X: longueur de l'instruction
;
; Variables:
;	Modifiées:
;		ident
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc get_literal
		; Sauvegarde A
		pha

		; Place V dans lex_strict
		php
		pla
		asl
		asl
		lda	#$00
		ror
		sta	lex_strict

		; Restaure A
		pla

		; Si l'instruction se termine sur un caractère non alpha numérique
		clc

		; Si l'instruction doit être suivie par un ' '
		; sec

		; Pas de conversion minuscules/MAJUSCULES
		bit	sev

		sty	lex_prev_y
		jsr	get_ident

		pha
		bcs	error10

		sty	lex_save_y

		ldy	#$ff
	loop:
		iny
		lda	ident,y
		beq	error10

		; Case insensitive?
		bit	lex_strict
		bmi	cmp_strict
		and	#$DF

	cmp_strict:
		cmp	(yacc_ptr),y
		beq	loop

		; Dernier caractère de l'instruction?
		ora	#$80
		cmp	(yacc_ptr),y
		bne	error10

		; Oui, est-ce aussi le dernier de l'identificateur?
		lda	ident+1,y
		bne	error10

		; Ajuste ptr
		; sortie avec C=0
		iny

		clc
		tya
		adc	yacc_ptr
		sta	yacc_ptr
		bcc	end
		inc	yacc_ptr+1
		clc
	end:
		; Restaure le pointeur de ligne
		ldy	lex_save_y
		pla
		rts

	error10:
		; 10 Syntax error.
		pla
		lda	#10
		ldy	lex_prev_y
		sec
	sev:
		rts
.endproc
