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
;.importzp lex_ptr
.import lex_save_y

.import param_type
;.import param1_type
.import ident
.import logic_value
.import bcd_value
.import string
.importzp pfac

;.import ident1
;.importzp pfac1
.import param

;.import get_expr
; From strbin.s
.import strbin

; From dbf.lib
.import fieldname_to_fieldnum
.import field

; From fns.lib
.import fn_field_value
.import field_value

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_field

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
; Entrée:
;	ident: nom du champ
;	Y: offset
; Sortie:
;	C: 0->Ok, 1->Erreur
;
; Variables:
;	Modifiées:
;		- field
;	Utilisées:
;		- lex_save_y
; Sous-routines:
;	- fieldname_to_fieldnum
;----------------------------------------------------------------------
.proc get_field
		; Initialise 'field'
		ldx	#11
		lda	#$00
	loop_clear:
		sta	field,x
		dex
		bpl	loop_clear

		; ldx	#$ff
	loop:
		inx
		lda	ident,x
		sta	field,x
		bne	loop

		jsr	fieldname_to_fieldnum
		bcs	end

		; X: numéro du champ
		jsr	fn_field_value

		;       A: type du champ
		;       Y: longueur du champ
		;       X: numéro du champ
		;       C: 0-> trouvé, 1-> non trouvé
		;       fn_zptr: pointeur vers la donnée
		;       field_value: donnée

		; Ne dois pas arriver
		bcs	end

		sta	param_type

	get_param_value:
		do_case
			case_of 'N'
				; Variable numérique, conversion ASCII -> binaire
					ldx	#<field_value
					ldy	#>field_value

					; On saute les espaces pour strbin
					sty	@chkspc+2
					dex
				@skipspc:
					inx
				@chkspc:
					lda	$ff00,x
					beq	@no_value
					cmp	#' '
					beq	@skipspc
				@no_value:

					; /!\ ATTENTION: strbin retourne une erreur si valeur décimale
					;     (ie: ne prend en compte que la partie entière)
					jsr	strbin
					; [ Si erreur de conversion -> C=1 -> fin, pas un champ de la base
					; bcs	end
					; ]
					; [ Si on ne remonte pas l'erreur, le champ aura pour valeur 0
					; ]

			case_of 'L'
				; Variable Logique, on peut avoir YyNnTtFf ou ? si non initialisée
				; On considère '?' comme 'F', vérifier ce que fait dBase dans ce cas
					lda	field_value

					; Conversion minuscule -> MAJUSCULE
					and	#$DF
					tax

					lda	#$ff

					cpx	#'T'
					; C=1 si 'T' ou 'Y' => A=$00
					; C=0 si 'F' ou 'N' ou '?' => A=$FF
					adc	#$00

					; Inversion du résultat
					eor	#$ff
					sta	logic_value

			case_of 'D'
				; Variable date, on recopie dans bcd_value
				loopD:
					lda	field_value,y
					sta	bcd_value,y
					dex
					bpl	loopD

			case_of 'C'
				; Variable chaine, on recopie dans string
					ldx	#$ff
				loopC:
					inx
					; [ Ajout test dépassement de capacité
					cpx	#$80-1
					bcs	end_C
					; ]
					lda	field_value,x
					sta	string,x
					bne	loopC
					; [ Ajout test dépassement de capacité
				end_C:
					lda	#$00
					sta	string,x
					; ]
			; Erreur si type inconnu?

		end_case
		clc
	end:
		ldy	lex_save_y
		rts
.endproc

