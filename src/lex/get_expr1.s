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
; From lex
.importzp lex_ptr
.import lex_save_a

.import param_type
.import param1_type
.import ident
.import logic_value
.import bcd_value
.import string
.importzp pfac

.import ident1
.importzp pfac1
.import param1

.import get_expr

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_expr1

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
; TODO: Ajouter la sauvegarde de l'offset del'expression dans la ligne
;        pour remonter une erreur avec le curseur au bon endroit.
;
; Entrée:
;	AX: adresse ligne
;	Y: offset
; Sortie:
;	C: 0->Ok, 1->Erreur
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc get_expr1
		jsr	get_expr
		bcs	end

		lda	param_type
		sta	param1_type
;		bpl	end

		bpl	get_param_value

		and	#$7f
		sta	lex_save_a

		; Copie l'identifiant de la variable
		; /?\ Utile?
		ldx	#$ff
	loop:
		inx
		lda	ident,x
		sta	ident1,x
		bne	loop

		lda	lex_save_a

	get_param_value:
		do_case
			case_of 'N'
				; Variable numérique, on recopie pfac
					ldx	#$03
				loopN:
					lda	pfac,x
					sta	pfac1,x
					dex
					bpl	loopN

			case_of 'L'
				; Variable Logique, on recopie logic_value
					lda	logic_value
					sta	param1

			case_of 'D'
				; Variable date, on recopier bcd_value
					ldx	#$03
				loopD:
					lda	bcd_value,x
					sta	param1,x
					dex
					bpl	loopD

			case_of 'C'
				; Variable chaine, on recopie string
					ldx	#$ff
				loopC:
					inx
					lda	string,x
					sta	param1,x
					bne	loopC
		end_case
		clc
	end:
		rts


;		; Si il s'agit d'une variable, sa valeur n'est pas récupérée
;		; à ce stade
;		ldx	#$ff
;	loop:
;		inx
;		lda	ident,x
;		sta	ident1,x
;		bne	loop
;
;	end:
;		rts
.endproc

