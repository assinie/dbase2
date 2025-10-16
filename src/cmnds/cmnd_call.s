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
; From main.s
.import main_input_mode

; From yacc.S
.import token_start

; From cmnd_goto.S
.import cmnd_goto

; From file.s
.import file_push
.import file_pop

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_call
.export cmnd_return

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------

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
;	X: offset sur le premier caractère suivant la commande
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	push
;	cmnd_goto
;----------------------------------------------------------------------
.proc cmnd_call
		jsr	file_push
		bcs	error
		jmp	cmnd_goto

	error:
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	X: offset sur le premier caractère suivant la commande
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	pop
;----------------------------------------------------------------------
.proc cmnd_return
		lda	main_input_mode
		bne	return
		; Pour debug
		; beq	return

	error95:
		; 95 Valid only in programs.
		lda	#95
		; ldy	token_start
		sec
		rts

	return:
		jsr	file_pop
		bcs	error

	error:
		rts
.endproc

