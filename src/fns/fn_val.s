
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

.import fns_save_y
.import fns_save_a

.import strbin
.import skip_spaces
.import fn_abs

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_val

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
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc fn_val
		lda	param_type
		and	#$7f
		cmp	#'C'
		bne	error

		; Sauvegarde Y
		sty	fns_save_y

		; [ Saute les espaces au début de la chaîne
		ldy	#$00
		lda	#<string
		ldx	#>string
		jsr	skip_spaces
		; ici on peut faire beq null (chaine vide)

		; Si le premier caractère est un '-', on le saute
		sta	fns_save_a
		cmp	#'-'
		bne	@skip
		iny
	@skip:
		tya
		ldy	#>string
		clc
		adc	#<string
		tax
		bcc	conv
		iny
	conv:
		; ]

		; Conversion de la chaine
		; C=1 si erreur de conversion (impossible en principe)
		; Y=longueur de la chaine convertie
;		ldx	#<string
;		ldy	#>string
		jsr	strbin

		; Si une erreur de conversion doit provoquer une erreur
		; [
		; bcs	error_cnv
		; ]
		; sinon on prend ce qui a été converti (façon BASIC)
		; [
		; ]

		lda	fns_save_a
		cmp	#'-'
		bne	end
		; Complémnent à 2
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

	end:
		; Type = Numerique
		lda	#'N'
		sta	param_type

		; Restaure Y
		ldy	fns_save_y

		clc
		rts

	error_cnv:
		; Y indique le caractère invalide dand la chaine
		; Restaure Y pour indiquer où est l'erreur dans la ligne
		ldy	fns_save_y

	error:
		sec
		rts
.endproc

