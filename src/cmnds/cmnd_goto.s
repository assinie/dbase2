
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
.include "errno.inc"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "include/dbase.inc"
.include "macros/readline.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
; From main
.import main_input_mode
.import global_status

; From cmnd_set_message
.import status_display

; From lex
.import param_type

; From math.s
.importzp pfac
.importzp multiplier
.importzp multiplicand

; From dbf.lib
.import dbf_isopen
.import dbf_goto
.import dbf_goto_top

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_goto
.export cmnd_goto_top

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
.proc cmnd_goto
		sty	save_y+1

		jsr	dbf_isopen
		bne	error52

		lda	param_type
		and	#$7f
		cmp	#'N'
		bne	error27

		; Offset négatif?
		lda	pfac+3
		bmi	error5

		; Offset > 65535?
		ora	pfac+2
		bne	error5

		; dbf_goto fait une multiplication 16x16
		; lda	#$00
		sta	multiplicand+2
		sta	multiplicand+3
		sta	multiplier+2
		sta	multiplier+3

		lda	pfac
		ldx	pfac+1
		jsr	dbf_goto
		cmp	#EOK
		bne	error

	end:
		; clc
		; rts
		jmp	status_display

	error:
		cmp	#ERANGE
		beq	error5

		; EIO

		; 64: Internal error:"
		lda	#64
		bne	end_error

	error5:
		; Pas d'erreur en mode programme en cas BOF ou EOF
		lda	main_input_mode
		bne	end

		; 5: Record is out of range.
		lda	#$5
		bne	end_error

	error27:
		; 27: Not a numeric expression.
		lda	#27
		bne	end_error

	error52:
		; 52: No database is in USE.
		lda	#52

	end_error:
	save_y:
		ldy	#$ff
		sec
		rts
.endproc

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
.proc cmnd_goto_top
		jsr	dbf_goto_top
		jmp	status_display
.endproc

