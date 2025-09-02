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
.import skip_spaces

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export init_argv
.export get_argv

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
MAX_ARGS = 10

;----------------------------------------------------------------------
;				Page Zéro
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"
		unsigned short ptr
.popseg

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "DATA"
		unsigned char delim

		; Nombre d'arguments
		unsigned char argc

		; Tableau des offsets vers chaque argument
		unsigned char argv[MAX_ARGS]

		; Copie de la ligne de commande
		; TODO: ne copier que les arguments sans les ' ' superflus
		unsigned char cmndline[80]
.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"

;----------------------------------------------------------------------
;
; Entrée:
;	AY: adresse ligne de commande
;
; Sortie:
;	A: argc
;
; Variables:
;	Modifiées:
;		ptr
;		argv
;		argc
;		delim
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc init_argv
		sta	ptr
		sty	ptr+1

		ldy	#$00
		sty	argv
		ldx	#$ff
		stx	argc

	loop:
		; Saute les espaces
		lda	ptr
		ldx	ptr+1
		jsr	skip_spaces
		beq	end

		inc	argc

		; Sauvegarde l'offset de début de l'argument dans le tableau argv
		pha
		ldx	argc
		tya
		sta	argv,x
		pla

		; Argument de type chaîne?
		cmp	#'''
		beq	arg_str
		cmp	#'"'
		beq	arg_str

		; Copie l'argument dans le tableau
		dey
	loop_arg:
		iny
		lda	(ptr),y
		sta	cmndline,y
		beq	end

		cmp	#' '
		bne	loop_arg

		lda	#$00
		; sta	(ptr),y
		sta	cmndline,y
		beq	loop
;		inc	argc
;		bne	loop

	arg_str:
		; Argument chaîne
		sta	delim
		inc	argv,x

	loop_str:
		iny
		lda	(ptr),y
		sta	cmndline,y
		beq	end

		cmp	delim
		bne	loop_str

		lda	#$00
		; sta	(ptr),y
		sta	cmndline,y
		iny
		bne	loop
;		inc	argc
;		iny
;		bne	loop

	end:
		inc	argc
		lda	argc
		clc
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	X: n° argument
;
; Sortie:
;	AY: adresse du paramètre
;	C: 0-> Ok, 1-> erreur
;
; Variables:
;	Modifiées:
;		delim
;	Utilisées:
;		ptr
;		argc
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc get_argv
		cpx	argc
		bcs	error

		ldy	#>cmndline
		lda	#<cmndline
		adc	argv,x
		bcc	end
		iny
	end:
		clc
		rts

	error:
		sec
		rts
.endproc

