
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
.include "case.mac"

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

; From cond_expr
.import cond_value

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_iif

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
.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A: mofidié
;	X: modifié
;	Y: inchangé
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc fn_iif
		lda	param_type
		and	#$7f
		sta	param_type

		lda	param1_type
		and	#$7f

		cmp	param_type
		bne	error11

		; Si exprL est faux => renvoie expr2
	;	ldx	logic_value
		ldx	cond_value
		beq	false

		and	#$7F

		do_case
			case_of 'N'
					; Variable numérique, on recopie pfac
					ldx	#$03
				loopN:
					lda	pfac1,x
					sta	pfac,x
					dex
					bpl	loopN

			case_of 'L'
				; Variable Logique, on peut avoir YyNnTtFf ou ? si non initialisée
				; On considère '?' comme 'F', vérifier ce que fait dBase dans ce cas
					lda	param1
					sta	logic_value

			case_of 'D'
				; Variable date, on recopie dans bcd_value
					ldx	#$04
				loopD:
					lda	param1,x
					sta	bcd_value,x
					dex
					bpl	loopD

			case_of 'C'
				; Variable chaine, on recopie dans string
					ldx	#$ff
				loopC:
					inx
					lda	param1,x
					sta	string,x
					bne	loopC

			; Erreur si type inconnu?

		end_case

	false:
		clc
		rts

	error11:
		; 11 Invalid function argument.
		lda	#11
		sec
		rts
.endproc

