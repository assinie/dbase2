
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

.import param1_type
.import param1
.importzp pfac1

.import is_pfac_byte
.import fn_str
.import fn_upper

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_transform

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
		cr_msg: .byte "CR"
		db_msg: .byte "DB"
.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"

;----------------------------------------------------------------------
; TRANSFORM(<expN>|<expC1>, <expC2>)
; utilisable uniquement avec: ?, ??, DISPLAY, LABEL, LIST, REPORT
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
.proc fn_transform
		; param1 = expC1
		; pfac1 = expN1
		; string = expC2
		sty	save_y+1

		lda	param1_type
		and	#$7f
		cmp	#'C'
		beq	fn_str

		cmp	#'N'
		beq	fn_num

	;	cmp	#'L'
	;	beq	fn_logic

	;	cmp	#'D'
	;	beq	fn_date
	error11:
		; 11: Invalid function argument.
		lda	#11
		sec
		rts

	fn_logic:

	fn_date:

	fn_str:
		lda	string
		cmp	#'@'
		bne	picture_str
		jsr	transform_str
	picture_str:
		jmp	end

	fn_num:
		lda	string
		cmp	#'@'
		bne	picture_num
		jsr	transform_num
	picture_num:
		jmp	end

	end:
		; string: chaine de sortie
		lda	#'C'
		sta	param_type

	save_y:
		ldy	#$ff
		clc
		rts
.endproc

;----------------------------------------------------------------------
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
.proc transform_num
		; Copie pfac1 dans pfac
		ldx	#03
	loop:
		lda	pfac1,x
		sta	pfac,x
		dex
		bpl	loop

		lda	pfac+3
		bmi	transform_negative
.endproc

;----------------------------------------------------------------------
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
; dBase: seule la fonction 'C' modifie l'affichage d'une valeur
;----------------------------------------------------------------------
.proc transform_positive
		; On commence à 0+1 (ici le premier caractère est '@')
		ldx	#$00
	loop_pos:
		inx
		lda	string,x
		beq	end

		; Conversion minusucles / MAJUSCULES
		and	#$df

		cmp	#'C'
		bne	loop_pos

		; Y est préservé dans fns_save_y par fn_str
		ldy	#$00

	num_crdb:
		; Conversion numérique -> caractères
		jsr	fn_str

		; Cherche la fin de la chaine
		ldx	#$ff
	@loop:
		inx
		lda	string,x
		bne	@loop

		; Ajoute ' CR'
		lda	#' '
		sta	string,x

		lda	cr_msg,y
		sta	string+1,x

		lda	cr_msg+1,y
		sta	string+2,x

		lda	#$00
		sta	string+3,x

	end:
		rts
.endproc

;----------------------------------------------------------------------
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
; dBase: si il y a plusieurs fonctions de formatage, on ne prend que
;        la dernière
;----------------------------------------------------------------------
.proc transform_negative
		lda	#$00
		sta	format+1

		; On commence à 0+1 (ici le premier caractère est '@')
		ldx	#$00
	loop_neg:
		inx
		lda	string,x
		beq	end_format

		cmp	#'('
		bne	_db
		sta	format+1
		beq	loop_neg

	_db:
		; Conversion minuscules / MAJUSCULES
		and	#$df

		cmp	#'X'
		bne	loop_neg

		sta	format+1
		beq	loop_neg

	end_format:
		; Conversion numérique -> caractères
		jsr	fn_str

	format:
		lda	#$ff
		beq	end

		; Efface le signe '-' au début de la chaine
		ldx	#' '
		stx	string

		cmp	#'('
		bne	fmt_db

		; Cherche la fin de la chaine
		; et le copie dans string
		ldx	#$ff
	@loop:
		inx
		lda	string,x
		bne	@loop

		; Ajoute ')' à la fin de la ligne
		lda	#')'
		sta	string+1,x
		lda	#$00
		sta	string+2,x

		; Décale la chaine
	loop_mv:
		lda	string-1,x
		sta	string,x
		dex
		bne	loop_mv

		; Place '(' au début de la chaine
		lda	#'('
		sta	string

	end:
		rts


	fmt_db:
		ldy	#(db_msg-cr_msg)
		; bne	num_crdb

		; Cherche la fin de la chaine
		ldx	#$ff
	@loop:
		inx
		lda	string,x
		bne	@loop

		; Ajoute ' DB'
		lda	#' '
		sta	string,x

		lda	cr_msg,y
		sta	string+1,x

		lda	cr_msg+1,y
		sta	string+2,x

		lda	#$00
		sta	string+3,x
		rts
.endproc

;----------------------------------------------------------------------
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
.proc transform_str
		; On commence à 0+1 (ici le premier caractère est '@')
		ldx	#$00
	loop:
		inx
		lda	string,x
		beq	end

		cmp	#'!'
		bne	loop

		; Copie la chaine dans string
		ldx	#$ff
	loopCopy:
		inx
		lda	param1,x
		sta	string,x
		bne	loopCopy

		jsr	fn_upper

	end:
		rts
.endproc

