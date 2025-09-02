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
.import strbin

.import value

.importzp lex_ptr
.import lex_delim

.import lex_save_a
.import lex_save_x
.import lex_save_y

.import fn_abs

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_int

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
; [+-]?[0-9]+ | [0-9]+
;
; TODO: autoriser les préfixes pris en compte par strbin (" %@$")
;
; Entrée:
;	AX: adresse de la ligne
;	Y: offset dans la ligne
;	C: 0-> valeur non signée, 1-> valeur signée
;	V: 0-> élimine les '0' , 1-> conserve les '0'
;
; Sortie:
;	A: dernier caractère lu
;	X: longueur de la chaine
;	Y: offset vers le dernier caractère lu
;	C: 0-> Ok, 1->erreur (premier caractère non numérique)
;	Z: fonction du dernier caractère lu (Z=1 -> EOL)
;
; Variables:
;	Modifiées:
;		string
;		prt
;		pfac
;
;	Utilisées:
;		-
;
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc get_int
		sta	lex_ptr
		stx	lex_ptr+1

		lda	#$00
		sta	lex_delim

		tax
		sta	value

		; Premier caractère
		; TODO: sauter les '0' inutiles au début?
		lda	(lex_ptr),y

		; Si on veut un éventuel signe avant le chiffre
		; (supprimer sinon)
		; [
		bcc	no_sign

		cmp	#'+'
		beq	get_value

		cmp	#'-'
		bne	no_sign

		sta	value,x
		inx

	get_value:
		iny
		lda	(lex_ptr),y
	no_sign:
		; ]

		; Si on élimine les '0' inutiles
		; (supprimer sinon)
		; [
		bvs	no_zero

		cmp	#'0'
		bne	no_zero

		; On place un '0' dans value au cas où il n'y aurait que des '0'
		sta	value,x
		inx
		dey
	loop:
		iny
		lda	(lex_ptr),y
		beq	end
		cmp	#'0'
		beq	loop
		; On a vu au moins un '0', on prend les chiffres suivants mais
		; on élimine celui mis dans value
		dex
		; On peut remplacer le jmp par beq si on ne veut pas d'un éventuel
		; signe
		jmp	test_val
		; ]

	no_zero:
		cmp	#'0'
		bcc	error

		cmp	#'9'+1
		bcs	error

		dey
	loop1:
		iny
		lda	(lex_ptr),y
		sta	value,x
		beq	end

	test_val:
		sta	value,x

		cmp	#'0'
		bcc	end

		cmp	#'9'+1
		bcs	end

		inx
		cpx	#VALUE_LEN+1
		bne	loop1

	err_overflow:
		dex
		lda	#$04
		bne	error

	end:
		sta	lex_save_a
		stx	lex_save_x
		sty	lex_save_y

		; Marque la fin de la chaîne (utile?)
		lda	#$00
		sta	value,x

		ldx	#<value
		ldy	#>value

		lda	value
		cmp	#'-'
		bne	conv

		inx
		bne	conv
		iny
	conv:
		; Conversion de la chaine
		; C=1 si erreur de conversion (impossible en principe)
;		ldx	#<value
;		ldy	#>value
		jsr	strbin
		bcs	error

		lda	value
		cmp	#'-'
		bne	positive

	.ifndef INLINE_NEG
		; /!\ ATTENTION en cas de modification de fn_abs
		jsr	fn_abs+4
	.else
		; [ code équivalent
		clc
		lda	pfac
		eor	#$ff
		adc	#$01
		sta	pfac

		ldx	#$01
	loop:
		lda	pfac,x
		eor	#$ff
		adc	#$00
		sta	pfac,x
		inx
		cpx	#$04
		bne	loop
		; ]
	.endif

	positive:
		ldx	lex_save_x
		ldy	lex_save_y
		lda	lex_save_a

		clc
		rts

	error:
		ldy	lex_save_y

		pha
		lda	#$00
		sta	value,x
		pla
		sec
		rts
.endproc

