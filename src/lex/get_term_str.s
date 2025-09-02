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
; From get_term
.import term_a
.import term_x
.import term_y

; From lex
.import lex_prev_y

.import string
.import param1

.import skip_spaces

.import get_expr_str
.import get_expr_str1

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_term_str
.export get_term_str_entry

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
; (<ident> | <string>) [<op> (<ident> | <string>)...]
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
.proc get_term_str
	::get_term_str_entry := entry

		sta	term_a
		stx	term_x

		jsr	get_expr_str1
		bcs	error

		; Ici X = len(param1)
		; On sauvegarde la longueur de la chainé
	entry:
		stx	str_len+1

	loop:
		lda	term_a
		ldx	term_x

		jsr	skip_spaces
		beq	end

		cmp	#'+'
		beq	term
		cmp	#'-'
		bne	end

	term:
		sta	op+1
		iny
		lda	term_a
		ldx	term_x
		jsr	skip_spaces
		lda	term_a
		jsr	get_expr_str
		bcs	error

		; Chaine vide?
		cpx	#$00
		beq	loop

		sty	term_y
	op:
		lda	#'+'
		cmp	#'+'
		beq	add

	sub:
		; Reporte les ' ' situés à la fin de la première chaîne
		; après la concaténation: '123  ' - '456' => '123456  '
		; Ici X = len(string)
		txa
		tay
		dey
		ldx	str_len+1

	sub_spaces:
		iny
		; Longueur > 127?
		; TODO: utiliser une constante pour la définition de string et param1
		bmi	error77

		dex
		lda	param1,x
		cmp	#' '
		bne	sub_add

		sta	string,y
		beq	sub_spaces

	sub_add:
		inx
		lda	#$00
		sta	string,y
		beq	concat

	add:
	str_len:
		ldx	#$00
	concat:
		ldy	#$00
		dey
		dex

	loop_add:
		inx
		; Longueur > 127?
		; TODO: utiliser une constante pour la définition de string et param1
		bmi	error77

		iny
		lda	string,y
		sta	param1,x
		bne	loop_add
		stx	str_len+1
		bne	loop_add

		ldy	term_y
		bne	loop

	error10:
		; 10 Syntax error.
		lda	#10
		bne	error

	error77:
		; 77 + : Concatenated string too large.
		lda	#77

	error:
		ldy	lex_prev_y
		sec
		rts

	end:
		; Recopie param1 dans string
		ldx	#$ff
	loop_end:
		inx
		lda	param1,x
		sta	string,x
		bne	loop_end

		clc
		rts
.endproc

