
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
.include "macros/readline.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.import param_type

; From cmnd_set_message
.import status_display

; From math.s
.importzp pfac

; From cmnd_goto.s
.import cmnd_goto

; From fns.lib
.import fn_recno

; From dbf.lib
.import dbf_isopen
.import dbf_skip

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_skip

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
		unsigned char save_y
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
; SKIP [<expN>]
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
.proc cmnd_skip
		sty	save_y

		jsr	dbf_isopen
		bne	error52

		lda	param_type
		bne	skip_n

		; [
		; Valeur par défaut: 1
	;	lda	#$01
	;	sta	pfac
	;	lda	#$00
	;	sta	pfac+1
	;	sta	pfac+2
	;	sta	pfac+3

	;	; Indique valeur numérique (pour cmnd_goto)
	;	lda	#'N'
	;	sta	param_type
		; ]
		; [
		jsr	dbf_skip
		cmp	#EOK
		bne	error
		; clc
		; rts
		jmp	status_display

	error:
		cmp	#ERANGE
		beq	error4

		; 64 Internal error
		lda	#64
		bne	end_err

	error4:
		; 5: Record is out of range.
		; 4: End of file encountered.
		lda	#4

	end_err:
		sec
		rts

		; ]
	skip_n:
		jsr	fn_recno

		clc
		adc	pfac
		sta	pfac
		tya
		adc	pfac+1
		sta	pfac+1
		lda	#$00
		adc	pfac+2
		sta	pfac+2
		lda	#$00
		adc	pfac+3
		sta	pfac+3

		ldy	save_y
		jmp	cmnd_goto

	error52:
		; 52: No database is in USE.
		lda	#52
		ldy	save_y
		sec
		rts
.endproc


