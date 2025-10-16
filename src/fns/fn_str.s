
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

.import is_pfac_byte

.import binstr

.ifndef INLINE_ABS
	.import fn_abs
.endif

.importzp fns_ptr
.import fns_save_y

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_str

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
; str(<expN>)
; TODO: str(<expN1>, [<expN2>], [<expN3>])
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		- fns_save_y
;		- string
;		- pfac
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
; dBase III: retourne une chaine de 10 caractères complétée à gauche
;            par des ' ' par défaut.
;            <expN2> permet de limiter le nombre total de caractères
;                    '.' 'et signe '-' inclus
;            <expN3> indique le nombre de décimales
;
;            <expN2> >= 2 + <expN3> sinon erreur 63
;
; retourne un chaine avec des '*' si la longueur de la chaine est
; supérieure à <expN1>
;
; retourne un erreur 63: "STR(): Out of range." si <expN2> et <expN3>
; sont incohérents:
; str(num,1,2) => Erreur, 2 décimales nécessitent au moins 4 caractères
;                 un chiffre au minimum avant la virgule + '.' + 2
;                 décimales.
;----------------------------------------------------------------------
.proc fn_str
		sty	fns_save_y

;		lda	param_type
;		and	#$7f
;		cmp	#'N'
;		beq	numeric
;
;	error:
;		sec
;		rts

	numeric:
		lda	#$00
		sta	string

		lda	pfac+3
		bpl	positive
		lda	#'-'
		sta	string

	.ifndef INLINE_ABS
		jsr	fn_abs
	.else
		; [ code équivalent à fn_abs
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
		lda	#$80
		ldx	#<pfac
		ldy	#>pfac
		jsr	binstr

		stx	fns_ptr
		sty	fns_ptr+1

		tay
		; [ Modification pour tenir compte des valeurs négtives
		tax
		lda	string
		beq	@loop

		inx
		; ]

	@loop:
		lda	(fns_ptr),y
		; [ Modification pour tenir compte des valeurs négtives
		sta	string,x
		dex
		; ]
		; [ sinon (valeur non signée)
		; sta	string,y
		; ]
		dey
		bpl	@loop

	end:
		lda	#'C'
		sta	param_type

		ldy	fns_save_y

		clc
		rts
.endproc

