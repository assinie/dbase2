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
.import string

.importzp lex_ptr
.import lex_delim
.import lex_strict

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_string

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
; ("[^"]*") | ('[^']*') | .+$
;
; Entrée:
;	AX: adresse de la ligne
;	Y: offset dans la ligne
;	C: 0-> délimiteurs facultatifs, 1-> délimiteurs obligatoires
;
; Sortie:
;	A: dernier caractère lu
;	X: longueur de la chaine
;	Y: offset vers le dernier caractère lu
;	C: 0-> Ok (delimiteur trouvé), 1->erreur (délimiteur non trouvé)
;	Z: fonction du dernier caractère lu (Z=1 -> EOL)
;
; Variables:
;	Modifiées:
;		string
;		lex_ptr
;
;	Utilisées:
;		-
;
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc get_string
		sta	lex_ptr
		stx	lex_ptr+1

		lda	#$00
		sta	lex_delim
		sta	string

		tax

		; Flag délimiteurs facultatifs
		ror
		sta	lex_strict

		lda	(lex_ptr),y

		; Si on ne demande aucun délimiteur spécifique, supprimer les
		; instructions suivantes jusqu'au label loop

		; Si uniquement délimiteur '"'
		; [
		; cmp	#'"'
		; bne	no_delim
		; ]

		; Si délimiteurs '"' et "'"
		cmp	#'"'
		beq	set_delim

		cmp	#"'"
		bne	no_delim

		; Si délimiteurs dBase '"', "'" et '[' ']'
		; [
		; cmp	#'"'
		; beq	set_delim
		;
		; cmp	#"'"
		; beq	set_delim
		;
		; cmp	#'['
		; bne	no_delim
		;
		; lda	#']'
		; ]

	set_delim:
		sta	lex_delim
		; iny
		; bne	loop
		beq	loop

	no_delim:
		bit	lex_strict
		bmi	error45
		; Compense le iny
		dey

	loop:
		iny
		lda	(lex_ptr),y
		sta	string,x

		cmp	lex_delim
		beq	end_delim

		; Au cas où le délimiteur n'est pas EOL et qu'on ne l'a pas vu
		; avant la fin de la ligne
		cmp	#$00
		beq	eol
		inx
		bne	loop

	eol:
		sta	string,x

	error35:
		; 35 Unterminated string.
		lda	#35
		sec
		rts

	error45:
		; 45 Not a Character expression.
		lda	#45
		sec
		rts

	end_delim:
		cmp	#$00
		beq	end

		; Le délimiteur n'est pas EOL, on ajoute un \00 à la fin de la chaine
		; et on incréente Y
		lda	#$00
		sta	string,x
		iny
		lda	(lex_ptr),y

	end:
		clc
		rts
.endproc

