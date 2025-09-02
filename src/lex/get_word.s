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
.import ident

.importzp lex_ptr
.import lex_delim

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_word

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
; Demande un identifiant délimité par un ' ' ou EOL
; Similaire à get_ident mais n'autorise que les caractères alphabétiques
; À voir si on autorise toujours le '_'
;
; [A-Za-z_]+
;
; Entrée:
;	AX: adresse de la ligne
;	Y: offset dans la ligne
;	C: 0 -> accepte n'importe quel caractère non alphanumérique comme
;	   délimiteur
;	   1 -> accepte uniquement un ' '
;	V: 0-> conversion minuscules/MAJUSCULES
;	   1 -> pas de conversion
;
; Sortie:
;	A: dernier caractère lu
;	X: longueur de la variable
;	Y: offset vers le dernier caractère lu
;	C: 0-> Ok (fin sur ' ' ou EOL), 1->erreur (caractère interdit trouvé)
;	Z: fonction du dernier caractère lu (Z=1 -> EOL)
;
; Variables:
;	Modifiées:
;		varname
;		prt
;
;	Utilisées:
;		-
;
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc get_word
		sta	lex_ptr
		stx	lex_ptr+1

		ldx	#$00

		; Option délimiteur
		txa
		ror
		sta	lex_delim
.if 0
		lda	(lex_ptr),y
		sta	ident,x
		; ]

		; Le premier caractère doit être alphabétique
		; ou '_'
		cmp	#'_'
		beq	loop2

		cmp	#'A'
		bcc	error

		and	#$DF

		; Si on veut convertir minuscules -> MAJUSCULES
		bvs	skip
		sta	ident,x

	skip:
		cmp	#'Z'+1
		bcs	error
.endif
		dex
		dey

	loop2:
		; TODO: vérifier la longueur maximale
		inx

		; Les caractères suivants doivent être alphanumériques
		iny
		lda	(lex_ptr),y
		sta	ident,x

		; Fin de ligne?
		beq	eol

		; Espace?
		cmp	#' '
		beq	eos

.if 0
		; On doit avoir un caractère alphanumérique ou '_'
		cmp	#'0'
		bcc	ident_end

		cmp	#'9'+1
		bcc	loop2
.endif
		cmp	#'_'
		beq	loop2

		and	#$DF

		; Si on veut une conversion minuscules -> MAJUSCULES
		bvs	skip2
		sta	ident,x

	skip2:
		cmp	#'A'
		bcc	ident_end

		cmp	#'Z'+1
		bcc	loop2

		; Caractère non alphanumérique au delà de 'Z'
		; C=1
	ident_end:
		; Instruction suivante nécessaire dans le cas où on arrive ici
		; après le and #$DF
		lda	(lex_ptr),y

		pha
		lda	#$00
		sta	ident, x

		; Accepte uniquement ' ' comme délimiteur?
		clc
		bit	lex_delim
		bpl	end
		sec
	end:
		pla
		rts

	error:
		pha
		lda	#$00
		sta	ident, x
		pla
		sec
		rts

	eol:
		; Le clc est en principe inutile (à vérifier)
		clc
		rts

	eos:
		lda	#$00
		sta	ident,x
		lda	#' '
		clc
		rts
.endproc


