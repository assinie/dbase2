
;----------------------------------------------------------------------
;			includes cc65
;----------------------------------------------------------------------
.feature string_escapes

.include "telestrat.inc"
.include "fcntl.inc"

;----------------------------------------------------------------------
;			includes SDK
;----------------------------------------------------------------------
.include "SDK.mac"
.include "types.mac"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "include/dbase.inc"
.include "macros/readline.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.import string
.import stringz_flg
.import ident

; [ Compatibilité submit
.importzp pfac
; ]

.import param_type

.import cmnd_store

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_wait

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
		; [ Compatibilité submit getkey
		unsigned char clear_flag
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
.proc cmnd_wait
		sty	clear_flag

		lda	stringz_flg
		bne	disp_string

	.ifndef SUBMIT
		; Utiliser message 7,9
		prints	"Appuyez sur une touche pour continuer"
	.else
		prints	"\x1bLPress any key to continue."
	.endif

		jmp	wait

	disp_string:
		print	string
		; [ compatibilité submit getkey
		ldy	string
		sty	clear_flag
		; ]

	wait:
		cgetc
		; Sauvegarde le code ASCII de la touche
		tax

		; Identificateur?
		lda	ident
		beq	end

		; Place le code de la touche dans la variable indiquée

	.ifndef SUBMIT
		; [ Si alpha (dBASE III)
		stx	string
		lda	#$00
		sta	string+1

		; Type de variable: Caractère
		lda	#'C'
		sta	param_type
		; ]
	.else
		; [ si numérique (submit)
		stx	pfac
		lda	#$00
		sta	pfac+1
		sta	pfac+2
		sta	pfac+3

		; Type de variable: Numérique
		lda	#'N'
		sta	param_type
		; ]
	.endif

		jsr	cmnd_store

	end:
		; Efface la ligne
		; [ compatibilité submit getkey
		lda	clear_flag
		beq	no_clear
		; ]

		prints  "\r\x0e"

	no_clear:
		clv
		clc
		rts
.endproc


