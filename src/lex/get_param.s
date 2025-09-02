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
.import entry

; From simple_list
.import var_search
.import var_getvalue
.importzp object

; From strbin
.importzp pfac

; From utils
.import clear_entry

; From lex
.importzp lex_ptr
.importzp lex_work_ptr
.import lex_save_y
.import lex_prev_y

.import param_type
.import ident
.import string
.import bcd_value
.import logic_value

.import get_ident
.import get_string
.import get_int

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_param

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
; "<string>" | '<string>' | <val_num> | <var>
;
; Entrée:
;	AX: adresse de la ligne
;	Y: offset
;
; Sortie:
;	A: si C=1:
;		 2: type inconnu
;		10: erreur de syntaxe
;		12: variable inconnue
;		31: fonction possible
;	Y: offset vers le prochain caractère
;	C: 0->Ok, 1->Erreur
;
;	param_type: type du paramètre
;	ident: nom de la variable
;	string: chaine
;	value: valeur numérique
;
; Variables:
;	Modifiées:
;		lex_save_y
;		lex_prev_y
;		lex_ptr
;		entry
;
;		param_type
;		ident
;		string
;		value
;		object
;	Utilisées:
;		-
; Sous-routines:
;	get_ident
;	get_int
;	get_string
;	var_search
;	var_getvalue
;	clear_entry
;----------------------------------------------------------------------
.proc get_param
		sta	lex_ptr
		stx	lex_ptr+1
		sty	lex_save_y
		sty	lex_prev_y

		; Logique?
		lda	(lex_ptr),y
		cmp	#'.'
		beq	logic

		; Chaine?
		cmp	#'"'
		beq	_string
		cmp	#'''
		beq	_string

		; Nombre?
		lda	lex_ptr
		jsr	get_int
		bcs	function

	number:
		lda	#'N'
		sta	param_type
		clc
		rts

	_string:
		lda	lex_ptr
		jsr	get_string
		bcs	error_y

		lda	#'C'
		sta	param_type
		clc
		rts

	logic:
		iny
		iny
		lda	(lex_ptr),y
		cmp	#'.'
		beq	true_false
	error10:
		; 10 Syntax error.
		lda	#10
		sec
		rts

	true_false:
		lda	#'L'
		sta	param_type
		lda	#$ff
		sta	logic_value

		dey
		lda	(lex_ptr),y
		and	#$df
		cmp	#'T'
		beq	true

		cmp	#'Y'
		beq	true

		cmp	#'F'
		beq	false

		cmp	#'N'
		bne	error10

	false:
		lda	#$00
		sta	logic_value
	true:
		iny
		iny
		clc
		rts

	error:
		ldy	lex_save_y
	error_y:
		sec
		rts

	function:
		; Variable ou fonction?
		clc
		lda	lex_ptr
		ldx	lex_ptr+1
		jsr	get_ident
		bcs	error
		sty	lex_save_y

		; Si A='(' on doit chercher une fonction et non une variable
		cmp	#'('
		bne	variable

	error31:
		; 31 Invalid function name.
		lda	#31
		ldy	lex_prev_y
		; Ici C=1 (résultat du cmp)
		; sec
		rts


	variable:
		; Variable existante?
		jsr	clear_entry
		ldx	#$ff
	@loop:
		inx
		lda	ident,x
		sta	entry+st_entry::name,x
		bne	@loop

		lda	#<entry
		sta	object
		lda	#>entry
		sta	object+1
		jsr	var_search
		bne	error12

		; Récupère la variable et renvoi son type +$80
		jsr	var_getvalue

		; Pointeur vers les data
		lda	entry+st_entry::data_ptr
		sta	lex_work_ptr
		lda	entry+st_entry::data_ptr+1
		sta	lex_work_ptr+1

		; Type de la variable
		ldy	#st_entry::type
		lda	(object),y
		ora	#$80
		sta	param_type

		; Numérique?
		cmp	#'N'+$80
		beq	var_num

		; Logique?
		cmp	#'L'+$80
		beq	var_logic

		; Chaine?
		cmp	#'C'+$80
		beq	var_string

		; Date?
		cmp	#'D'+$80
		bne	err_type

	var_date:
		; Copier la valeur BCD
		ldy	#st_entry::len
		lda	(object),y
		tay
	@loop:
		lda	(lex_work_ptr),y
		sta	bcd_value,y
		dey
		bpl	@loop
		ldy	lex_save_y
		clc
		rts

	var_string:
		; Copier la chaine
		ldy	#st_entry::len
		lda	(object),y

		; Sauvegarde la longueur de la chaine dans X
		tax

		tay
	@loop:
		lda	(lex_work_ptr),y
		sta	string,y
		dey
		bpl	@loop
		ldy	lex_save_y
		clc
		rts

	var_logic:
		; La valeur est dans data_ptr
		;lda	lex_work_ptr
		ldy	#$00
		lda	(lex_work_ptr),y
		sta	logic_value
		ldy	lex_save_y
		clc
		rts

	var_num:
		; La valeur est dans data_ptr
		; Copier la chaine
		ldy	#st_entry::len
		lda	(object),y
		tay
	@loop:
		lda	(lex_work_ptr),y
		; sta	value,y
		sta	pfac,y
		dey
		bpl	@loop
		ldy	lex_save_y
		clc
		rts

	error12:
		; 12 Variable not found.
		lda	#12
		ldy	lex_prev_y
		sec
		rts

	err_type:
		lda	#$02
		ldy	lex_save_y
		sec
		rts
.endproc

