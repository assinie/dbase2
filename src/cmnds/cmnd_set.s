
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
.import global_cursor

; From get_tokens
.import on_off_flag
.import opt_num

.import date_fmt

; From debug
.import PrintHexByte

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_set
.export get_option

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
OPT_CENTURY = 24
OPT_CURSOR = 25

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"

	.segment "DATA"
		unsigned char options[4]

.popseg

;----------------------------------------------------------------------
;			Chaines statiques
;----------------------------------------------------------------------
.pushseg
	.segment "RODATA"
		bits_table_1:
			.byte	%00000001
			.byte	%00000010
			.byte	%00000100
			.byte	%00001000
			.byte	%00010000
			.byte	%00100000
			.byte	%01000000
			.byte	%10000000

		bits_table_0:
			.byte	%11111110
			.byte	%11111101
			.byte	%11111011
			.byte	%11110111
			.byte	%11101111
			.byte	%11011111
			.byte	%10111111
			.byte	%01111111

.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"

.if 0
;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A,X: Modifiés
;	Y  : Inchangé
;	C  : 0
;
; Variables:
;	Modifiées:
;		date_fmt
;
;	Utilisées:
;		opt_num
;		on_off_flag
;
; Sous-routines:
;	cursor
;----------------------------------------------------------------------
.proc cmnd_set
;		prints	"Option #"
;		lda	set_opt_num
;		jsr	PrintHexByte
;		prints	" := "
;		lda	on_off_flag
;		jsr	PrintHexByte
;		crlf

		lda	opt_num
		cmp	#OPT_CENTURY
		bne	_cursor

		lda	date_fmt
		ldx	on_off_flag
		beq	century_off

		ora	#$10
		sta	date_fmt
		clc
		rts

	century_off:
		and	#$ef
		sta	date_fmt

	_cursor:
		cmp	#OPT_CURSOR
		bne	end

		ldx	on_off_flag
		beq	cursor_off

		cursor	on
		clc
		rts

	cursor_off:
		cursor	off
		clc
		rts

	end:
		clc
		rts
.endproc
.endif

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A,X,Y: Modifiés
;	C: 0
;
; Variables:
;	Modifiées:
;		options
;
;	Utilisées:
;		opt_num
;		on_off_flag
;		bits_table
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc cmnd_set
		lda	opt_num
		jsr	get_option_byte

		lda	on_off_flag
		beq	off

		; ON
		lda	options,x
		ora	bits_table_1,y
		sta	options,x

		; Traitement spécifique pour le curseur
		lda	opt_num
		cmp	#OPT_CURSOR
		bne	end

		sta	global_cursor

	end:
		clc
		rts

	off:
		; Off
		; lda	bits_table_1,y
		; ora	#$ff
		lda	bits_table_0,y
		and	options,x
		sta	options,x

		; Traitement spécifique pour le curseur
		lda	opt_num
		cmp	#OPT_CURSOR
		bne	end

		lda	#$00
		sta	global_cursor
		clc
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	A: N° de l'option
;
; Sortie:
;	A: octet contenant l'option
;	X: index de l'octet contenant l'option
;	Y: n° du bit correspondant à l'option dans l'octet
;	C: 0
;
; Variables:
;	Modifiées:
;		options
;
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc get_option_byte
		; Sauvegarde A dans Y
		tay

		; Index de l'octet contenant l'option
		lsr
		lsr
		lsr
		tax

		; Restaure A
		tya

		; Index du bit correspondant à l'option
		and	#$07
		tay

		lda	options,x

		clc
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	A: N° de l'option
;
; Sortie:
;	A: 0 -> Off, Autre -> On
;	Z: 1 -> Off, 0 -> On
;	C: 0
;	X,Y: Inchangés
;
; Variables:
;	Modifiées:
;		-
;
;	Utilisées:
;		bits_table_1
;
; Sous-routines:
;	get_options_byte
;----------------------------------------------------------------------
.proc get_option
		stx	save_x+1
		sty	save_y+1

		jsr	get_option_byte
		and	bits_table_1,y
		php

	save_x:
		ldx	#$ff
	save_y:
		ldy	#$ff

		plp
		rts
.endproc
