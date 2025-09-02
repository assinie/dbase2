
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
.import get_ident
.import skip_spaces

.import token_start
.import cmnd_procedure

.import input_mode
.importzp line_ptr

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_label

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
; :<ident>
;
; Note: compatibilité submit
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
.proc cmnd_label
		lda	input_mode
		bne	define_proc
		; Pour debug
		beq	define_proc

	error95:
		; 95 Valid only in programs.
		lda	#95
		sec
		rts

	define_proc:
		iny
		sty	token_start
		lda	line_ptr
		ldx	line_ptr+1
		jsr	get_ident
		bcs	error

		lda	line_ptr
		ldx	line_ptr+1
		jsr	skip_spaces
		cmp	#$00
		bne	error10

		jmp	cmnd_procedure

	error10:
		; 10 Syntax error.
		lda	#$00
		sec

	error:
		rts
.endproc

