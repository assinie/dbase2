
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
; From yacc.s
.import token_start

; From lex
.import string

; Form math.s
.importzp multiplier
.importzp multiplicand

; From fn_isopen.s
;.import fn_isopen

; From cmnd_set_message
.import status_display

; From cmnd_set.s
.import get_option

; From dbf.lib
.import dbf_list
.import dbf_isopen
.import dbf_display_headings

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_list

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------

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
.proc cmnd_list
		jsr	dbf_isopen
		bne	error52
		; bcs	error52

		lda	#OPT_HEADINGS
		jsr	get_option
		beq	no_headings

		jsr	dbf_display_headings

	no_headings:
		; dbf_goto utilise une multiplcation 16x16
		; mais math.s fait une 32x32
		lda	#$00
		sta	multiplicand+2
		sta	multiplicand+3
		sta	multiplier+2
		sta	multiplier+3
		jsr	dbf_list
		; cmp	#EOK
		; bne	error

	end:
		; clc
		; rts
		jmp	status_display

	error52:
		; 52: No database is in USE
		lda	#52
		ldy	token_start
		sec
		rts
.endproc


