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
; From tables
.import func_table
.import func_addr
.import lex_tbl
.import func_yacc_tbl

; From utils
.import _find_cmnd

; From lex
.importzp lex_ptr
.import lex_save_a
.import lex_save_x
.import lex_save_y
.import lex_prev_y

.import param_type

.import skip_spaces

.import get_param

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_expr

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
; TOKEN_TYPE=22			; Défini dans dbase.inc

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
; "<string>" | '<string>' | <val_num> | <var> | <function>(<expr>)
; Entrée:
;	AX: adresse ligne
;	Y: offset
; Sortie:
;	C: 0->Ok, 1->Erreur
;
; Variables:
;	Modifiées:
;		- lex_ptr
;		- lex_prev_a
;		- lex_save_x
;		- lex_save_y
;		- param_type
;	Utilisées:
;		- func_table
;		- funv_addr
;		- func_yacc_tbl
;		- lex_tbl
; Sous-routines:
;	- get_param
;	- _find_cmnd
;----------------------------------------------------------------------
.proc get_expr
		sta	lex_ptr
		stx	lex_ptr+1
		sty	lex_prev_y

		; "<string>" | '<string>' | <val_num> | <var>
		jsr	get_param
		bcs	is_function
		rts

	is_function:
		; Fonction?

		; Sauvegarde le code erreur de get_param au cas où
		; 31 Invalid function name.
		; sta	lex_save_a
		cmp	#31
		bne	errorxx

		sty	lex_save_y
		ldx	lex_save_y
		lda	#<func_table
		ldy	#>func_table
		jsr	_find_cmnd

		; Replace l'offset dans la ligne dans Y
		stx	lex_save_y
		ldy	lex_save_y
		bcc	function

;		bcs	error31
;
;		lda	(lex_ptr),y
;		cmp	#'('
;		beq	function

	error31:
		; 31 Invalid function name.
		lda	#31

	errorxx:
		; Restaure le code erreur de get_param
		; lda	lex_save_a
		sec
		rts

	error:
		ldy	lex_prev_y
	error10:
		; 10: Syntax error.
		lda	#10
		sec
		rts

;		; Restaure ident
;	store:
;		ldx	#$ff
;	loop1:
;		inx
;		lda	ident_dst,x
;		sta	ident,x
;		bne	loop1
;		; jmp	cmnd_store
;		rts

.ifdef OLD_PARAM
	function:
		; N° de fonction
		sta	lex_save_a
		; Nombre de paramètres
		tax
		lda	func_param_count,x
		sta	lex_save_x
		beq	ok

		; Sauvegarde du nombre de paramètres et du n° de fonction
		; (appel récursif)
		;sta	lex_save_a
		pha
		lda	lex_save_a
		pha

		lda	lex_ptr
		ldx	lex_ptr+1
		jsr	skip_spaces
		sty	lex_save_y
		lda	lex_ptr
		; jsr	get_param
		jsr	get_expr

		; Restaure le nombre de paramètres et le n° de fonction
		pla
		sta	lex_save_a
		pla
		sta	lex_save_x

		;bcs	error
		bcc	ok

		; Saute le paramètre [valable uniquement pour TYPE()]
		; [
		lda	lex_save_a
		cmp	#TOKEN_TYPE
		bne	error

		lda	lex_ptr
		sta	lex_work_ptr
		lda	lex_ptr+1
		sta	lex_work_ptr+1
		dey
	loop2:
		iny
		lda	(lex_work_ptr),y
		beq	error
		cmp	#')'
		bne	loop2
		iny
		; Indique paramètre inconnu
		lda	#'U'
		sta	param_type
		; ]

	ok:
;		sty	lex_save_y
		lda	lex_ptr
		ldx	lex_ptr+1
		jsr	skip_spaces

		; Autres paramètres?
		dec	lex_save_x
		beq	end

		bmi	end_no_param

		sty	lex_prev_y
		cmp	#','
		bne	error10

		iny

		lda	lex_save_x
		pha
		lda	lex_ptr
		ldx	lex_ptr+1
		jsr	get_expr
		bcs	error3

		pla
		sta	lex_save_x
		jmp	ok

	error3:
		pla
		lda	#$04
		rts

	end_no_param:
	end:
		cmp	#')'
		bne	error10

;	end_no_param:
		iny
;		sty	lex_save_y

		lda	lex_save_a
		asl
		tax
		lda	func_addr,x
		sta	_jsr+1
		lda	func_addr+1,x
		sta	_jsr+2
	_jsr:
		jmp	$ffff
.else
	function:
		ldx	#$ff

	next_step:
		inx

		; Sauvegarde n° de pas
		stx	lex_save_x

		; Sauvegarde n° de fonction
		sta	lex_save_a

		; Paramètre
		asl
		tax
		lda	func_yacc_tbl,x
		sta	get_step+1
		lda	func_yacc_tbl+1,x
		sta	get_step+2

		lda	lex_ptr
		ldx	lex_ptr+1
		jsr	skip_spaces
		sty	lex_save_y

		ldx	lex_save_x
	get_step:
		lda	$ffff,x
		bmi	literal

		asl
		tax
		lda	lex_tbl,x
		sta	jsr_param+1
		lda	lex_tbl+1,x
		sta	jsr_param+2

		; Sauvegarde n° de fonction
		lda	lex_save_a
		pha
		; Sauvegarde n° de pas
		lda	lex_save_x
		pha

		lda	lex_ptr
		ldx	lex_ptr+1
	jsr_param:
		jsr	$ffff

		; TODO: Pb, en cas d'erreur on perd le code erreur
		; avec les PLA/TAX
		;       Placer le code dans une variable
		pla
		tax
		pla
		sta	lex_save_a

		bcc	next_step

		; Instruction TYPE?
		cmp	#TOKEN_TYPE
		bne	error

		; Cherche ')'
		dey
	loop:
		iny
		lda	(lex_ptr),y
		beq	error10

		cmp	#')'
		bne	loop

;		iny
;		lda	(lex_ptr),y
;		bne	set_param_type
;		dey

	set_param_type:
		lda	#'U'
		sta	param_type
		; Récupère le n° de fonction
		lda	lex_save_a
		jmp	next_step


	literal:
		cmp	#$fe			; EOI
		beq	end_function
		and	#$7f
		cmp	(lex_ptr),y
		bne	error10
		iny
		lda	lex_save_a
		jmp	next_step

	end_function:
		lda	lex_save_a
		asl
		tax
		lda	func_addr,x
		sta	_jsr+1
		lda	func_addr+1,x
		sta	_jsr+2
	_jsr:
		jmp	$ffff
.endif

.endproc

