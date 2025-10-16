
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
; From cmnd_set_message
.import status_display

; From Lex
.import opt_num

; From dbf.lib
.import dbf_close

; From ndx.lib
;.import ndx_close

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_close

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
		;opt_close:
		;	string80	"ALL"
		;	string80	"ALTERNATE"
		;	string80	"DATABASES"
		;	string80	"FORMAT"
		;	string80	"INDEX"
		;	string80	"PROCEDURE"

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
.proc cmnd_close
		; Option
		lda	opt_num
		beq	close_all
		cmp	#$02
		beq	close_databases

		clc
		rts

	close_all:

	close_alternate:

	close_databases:
		jsr	dbf_close
		jsr	status_display
	;	lda	opt_num
	;	bne	end

	close_format:

	;close_index:
	;	jsr	ndx_close
	;	lda	opt_num
	;	bne	end

	close_procedure:

	end:
		rts
.endproc


