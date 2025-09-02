
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

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "include/dbase.inc"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
; From main.s
.importzp line_ptr

; From cond_expr.s
.import cond_expr

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_iif

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
;	C: 1 -> erreur
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		line_ptr
; Sous-routines:
;	cond_expr
;----------------------------------------------------------------------
.proc cmnd_iif
;		lda	input_mode
;		beq	error95

		; Pour compatibilité submit, il faut vérifier ici qu'il y a
		; quelque chose après la condition sinon si la condition est
		; fausse la syntaxe complète de la commande ne sera pas vérifiée
		; if <condiftion> <instruction>

		lda	(line_ptr),y
		beq	error10

		jsr	cond_expr
		bcs	error

		beq	false

	true:
		bit	sev

	false:
	sev:
		rts


;	error95:
;		; 95 Valid only in programs.
;		lda	#95
;		ldy	#$00
;		sec
;		rts

	error10:
		; 10 Syntax error.
		lda	#10
		sec
	error:
		rts
.endproc

