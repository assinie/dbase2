
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
; From main
.importzp work_ptr

; From dbase2.inc
.import set_opt

; From cmnd_set
.import get_option

; From lex
.import string

; From cmnd_on
.import on_error
.import on_escape
.import on_key

; From dbf.lib
.import dbf_isopen
.import dbf_display_header

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_display_status

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
.proc cmnd_display_status
		; crlf

		lda	on_error
		beq	escape

		prints	"On Error:     "
		print	on_error
		crlf

	escape:
		lda	on_escape
		beq	key

		prints	"On Escape:    "
		print	on_escape
		crlf

	key:
		lda	on_key
		beq	suite

		prints	"On Keystroke: "
		print	on_key
		crlf

	suite:
		crlf

		; Place '- \0' à la fin de string
		lda	#'-'
		sta	string+10
		lda	#' '
		sta	string+11
		lda	#$00
		sta	string+12

		jsr	dbf_isopen
		bne	display_sets

		jsr	dbf_display_header

	display_sets:
		lda	#<set_opt
		sta	work_ptr
		lda	#>set_opt
		sta	work_ptr+1

		ldx	#$00
	again:
		ldy	#$ff
	loop:
		iny
		lda	(work_ptr),y
		beq	end

		sta	string,y
		bpl	loop

		and	#$7f
		sta	string,y

		; Ajuste work_ptr
		clc
		iny
		tya
		adc	work_ptr
		sta	work_ptr
		bcc	skip
		inc	work_ptr+1

	skip:
		lda	#' '

	loop1:
		sta	string,y
		iny
		cpy	#10
		bcc	loop1

		; Récupère la valeur de l'option
	get_opt:
		txa
		jsr	get_option
		php

		stx	save_x+1

		; Affiche l'option
		print	string

		plp
		beq	off
	on:
		prints	"ON"
		jmp	next

	off:
		prints	"OFF"

	next:
		crlf

	save_x:
		ldx	#$ff
		inx
		; Les OPTIONS au delà de _OPT_EXPR_ ne sont pas ON/OFF
		cpx	#_OPT_TO_
		bne	again

	end:
		; crlf
		clc
		rts
.endproc


