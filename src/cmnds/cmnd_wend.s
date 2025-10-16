
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
; From scan.s
.import flow_stack
.import flow_loop

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_wend
.export cmnd_loop := cmnd_wend

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
;	A: n° de token de WEND ou LOOP
;	X: offset des paramètres
;	Y: offset vers la fin de la ligne
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
.proc cmnd_wend
		; Sauvegarde le n° de token
		tax

		; WEND marque la fin du bloc
		lda	flow_stack
		beq	error96

		; On poistionne C en fonction du token
		cpx	#TOKEN_LOOP
		jsr	flow_loop
		rts

	error96:
		; 96 Mismatched DO WHILE and ENDDO.
		lda	#96
		sec
		rts
.endproc


