
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
; From main.s
.importzp line_ptr

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_set_function

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
		; F1: help;
		; F2: assist;
		; F3: list;
		; F4: dir;
		; F5: display structure;
		; F6: display status;
		; F7: display memory;
		; F8: append;
		; F9: edit;
.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"

;----------------------------------------------------------------------
; SET FUNCTION <expN>/<expC1> TO <expC2>
; <expN>: [1, FKMAX()]
; <expC1>: ["F2","F<fkmax()>"]
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
.proc cmnd_set_function
		prints	"xxx"
		crlf

		clc
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	AY: Adresse du buffer
;	X : code Funct+<touche>
;
; Sortie:
;	C: 0-> retour au programme appelant, 1-> retour à readline
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.import PrintRegs
.pushseg
	.segment "RODATA"
		funct_msg:
			.asciiz "clear"
.popseg

.proc function_callback
		jsr PrintRegs

		sta	line_ptr
		sty	line_ptr+1

		ldy	#$ff
	loop:
		iny
		lda	funct_msg,y
		sta	(line_ptr),y
		bne	loop

		; readline/accept_line sort avec
		; AY: adresse pointeur
		;  X: longueur de la chaine
		;  Z: 1 si chaine vide
		tya
		tax

		lda	line_ptr
		ldy	line_ptr+1

		; Retour au programme principal
		clc

		rts
.endproc

