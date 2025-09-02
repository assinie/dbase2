;----------------------------------------------------------------------
;			includes cc65
;----------------------------------------------------------------------
.feature string_escapes

.include "telestrat.inc"
.include "errno.inc"

;----------------------------------------------------------------------
;			includes SDK
;----------------------------------------------------------------------
.include "SDK.mac"
.include "types.mac"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.import fp


;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fputs

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;				Page Zéro
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"
		unsigned short address

	.segment "DATA"
		unsigned short line_length
.popseg

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "DATA"

.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"

;----------------------------------------------------------------------
;
; Entrée:
;	AY: Adresse du tampon
;
; Sortie:
;	A  : 0 ou code erreur
;	X  : Modifié
;	Y  : Longueur de la ligne
;	C=0: Ok
;	C=1: Erreur
;
; Variables:
;       Modifiées:
;               address
;		line_length
;       Utilisées:
;               -
; Sous-routines:
;       fwrite
;----------------------------------------------------------------------
.proc fputs
		sta	address
		sty	address+1

		; Calcul de la taille de la ligne
		ldy	#$ff
	loop:
		iny
		lda	(address),y
		bne	loop

		sta	line_length+1

		; Remplace le \00 final par un <LF>
		lda	#$0a
		sta	(address),y

		iny
		sty	line_length

		fwrite	(address), (line_length), 1, fp
		ldy	line_length
		dey

		cmp	line_length
		bne	error56

		cpx	line_length+1
		bne	error56

		lda	#$00
		sta	(address),y

		clc
		rts

	error56:
		lda	#$00
		sta	(address),y

		; 55 Memory Variable file is invalid.
		lda	#56
		sec
		rts
.endproc
