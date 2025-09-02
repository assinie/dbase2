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
; Chaines statiques
;.import set_opt
.importzp yacc_ptr

; From main
.import submit_line

; From utils
.import _find_cmnd

; From lex
.import opt_num
.import lex_save_y
;.importzp lex_work_ptr

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_opt
.export get_optz

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
;
;
; Entrée:
;	AX: adresse de la ligne
;	Y: offset dans la ligne
;
; Sortie:
;	A: dernier caractère lu
;	Y: offset vers le dernier caractère lu
;	C: 0-> Ok, 1->erreur (premier caractère non numérique)
;	Z: fonction du dernier caractère lu (Z=1 -> EOL)
;
; Variables:
;	Modifiées:
;		string
;		prt
;
;	Utilisées:
;		-
;
; Sous-routines:
;	-
;----------------------------------------------------------------------
.if 0
.proc get_set_opt
		sty	lex_save_y
		ldx	lex_save_y
		lda	#<set_opt
		ldy	#>set_opt
		jsr	_find_cmnd
		bcs	error

		; Sortie:
		; A = caractère suivant la commande
		; Y = offset du caractère après la commande
		sta	set_opt_num
		stx	lex_save_y
		ldy	lex_save_y
		lda	submit_line,y
		rts

		clc
		rts
	error:
		ldy	lex_save_y
		; Syntax error.
		lda	#10
		sec
		rts
.endproc
.endif
.proc get_opt
		sty	lex_save_y
;		ldx	lex_save_y

		; Récupère l'adresse de la table
		ldy	#$00
		lda	(yacc_ptr),y
		tax
		iny
		lda	(yacc_ptr),y
		tay

		; incrémente le pointeur yacc
		clc
		lda	yacc_ptr
		adc	#$02
		sta	yacc_ptr
		lda	#$00
		adc	yacc_ptr+1
		sta	yacc_ptr+1

		; Recherche l'option
		txa
		ldx	lex_save_y
;		lda	#<set_opt
;		ldy	#>set_opt
		jsr	_find_cmnd
		bcs	error

		; Sortie:
		; A = caractère suivant la commande
		; Y = offset du caractère après la commande
		sta	opt_num
		stx	lex_save_y
		ldy	lex_save_y
		lda	submit_line,y
		rts

		clc
		rts
	error:
		ldy	lex_save_y
		; Syntax error.
		lda	#10
		sec
		rts
.endproc

;----------------------------------------------------------------------
;
;
; Entrée:
;	AX: adresse de la ligne
;	Y: offset dans la ligne
;
; Sortie:
;	A: dernier caractère lu
;	Y: offset vers le dernier caractère lu
;	C: 0-> Ok, 1->erreur (premier caractère non numérique)
;	Z: fonction du dernier caractère lu (Z=1 -> EOL)
;
; Variables:
;	Modifiées:
;		yacc_ptr
;		opt_num
;
;	Utilisées:
;		submit_line
;
; Sous-routines:
;	get_opt
;----------------------------------------------------------------------
.proc get_optz
;		sta	lex_work_ptr
;		stx	lex_work_ptr+1
;		lda	(lex_work_ptr),y

		lda	submit_line,y
		;beq	end
		;jmp	get_opt
		bne	get_opt

	end:
		lda	#$ff
		sta	opt_num

		; incrémente le pointeur yacc
		clc
		lda	yacc_ptr
		adc	#$02
		sta	yacc_ptr
		lda	#$00
		adc	yacc_ptr+1
		sta	yacc_ptr+1

		lda	#$00

		clc
		rts
.endproc

