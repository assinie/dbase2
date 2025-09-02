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

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export skip_spaces

.export ident
.export ident1
.export string
.export stringz_flg
.export value
.export bcd_value
.export logic_value
.export param_type
.export param1_type
.export param1
.exportzp pfac1

.export on_off_flag
.export opt_num
.export comp_oper

.export lex_save_a
.export lex_save_x
.export lex_save_y
.export lex_prev_y

.export lex_delim
.export lex_strict

.exportzp lex_ptr
.exportzp lex_work_ptr

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
		unsigned short lex_ptr
		unsigned short lex_work_ptr

		unsigned long pfac1
.popseg

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "DATA"
		unsigned char lex_save_a
		unsigned char lex_save_x
		unsigned char lex_save_y
		unsigned char lex_prev_y

		unsigned char lex_delim
		unsigned char lex_strict

		; [ exports
		unsigned char ident[IDENT_LEN+1]
		unsigned char string[128]
		unsigned char stringz_flg
		unsigned char value[VALUE_LEN+1]
		unsigned char bcd_value[(VALUE_LEN>>1)]
		unsigned char logic_value
		unsigned char param_type

		unsigned char ident1[IDENT_LEN+1]
		unsigned char param1[128]
		; unsigned long pfac1
		unsigned char param1_type

		unsigned char on_off_flag
		unsigned char opt_num
		unsigned char comp_oper
		; ]

		; Pour get_vargs
		unsigned char param_nb
		unsigned char save_a2
		unsigned char save_x2
		unsigned char save_y2

		; Pour get_term_xxx
		unsigned char term_a
		unsigned char term_x
		unsigned char term_y

;		unsigned char prev_y
;		unsigned char strict
;		unsigned char var_type
;		unsigned char filename[FILENAME_LEN]
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
;	AX: adresse de la ligne
;	Y: offset dans la ligne
;
; Sortie:
;	A: dernier caractère lu
;	Y: offset vers le dernier caractère lu
;	Z: 1-> fin sur EOL, 0-> autre caractère (dans ce cas C -> comparaison par rapport à ' ')
;	X: inchangé
;	C: 0
;
; Variables:
;	Modifiées:
;		prt
;
;	Utilisées:
;		-
;
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc skip_spaces
		sta	lex_ptr
		stx	lex_ptr+1

		dey
	loop:
		iny
		lda	(lex_ptr),y
		beq	end
		cmp	#' '
		beq	loop
		cmp	#"\t"
		beq	loop

	end:
		clc
		rts

.endproc

