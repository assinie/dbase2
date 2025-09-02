
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
.include "macros/utils.mac"
.include "macros/readline.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
; From main
.importzp line_ptr
.import submit_line
.import input_mode

; From readline
.import readline

; From utils
.import _find_cmnd

; From file
.import fgetline

; From submit
.import submit

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_text

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
		endtext:
			string80	"ENDTEXT"
			.byte	$00
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
.proc cmnd_text
		lda	input_mode
		bne	from_file

	from_keyboard:
		; Mode interractif
		input	"...>", ::LINE_MAX_SIZE, line_ptr

		cpx	#$00
		beq	from_keyboard

;		; Copie de _argv dans submit_line
;		ldy	#$ff
;	loop:
;		iny
;		lda	(line_ptr),y
;		sta	submit_line,y
;		bne	loop
;
	is_endtext:
		jsr	submit

	.ifdef SUBMIT
		; ENDTEXT peut être indenté

	.else
		; Si ENDTEXT doit être uniquement en début de ligne
		; (dBase III)
		ldx	#$00
	.endif

		lda	#<endtext
		ldy	#>endtext
		jsr	_find_cmnd
		bcc	end

	display_line:
		print	(line_ptr)
		crlf
		jmp	cmnd_text

		; Mode programme
	from_file:
;		lda	#<submit_line
;		sta	line_ptr
;		ldy	#>submit_line
;		sty	line_ptr+1
;		jsr	fgets
;		ldx	#::LINE_MAX_SIZE
		jsr	fgetline
		sta	line_ptr
		sty	line_ptr+1
		bcc	is_endtext

		; Erreur de lecture du fichier
		; TODO: trouver un code erreur EOF
		lda	#EIO
		sec
		rts

	end:
		; Il faudrait vérifier qu'il n'y a pas d'autres caractères après le ENDTEXT
		clc
		rts
.endproc


