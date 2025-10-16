
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
.import global_status
.import global_dbaserr
.importzp line_ptr

; From get_tokens
.import on_off_flag
.import opt_num

; From cmnd_set_fields.s
.import cmnd_set_fields

; From cmnd_set_date
.import cmnd_set_date

; From cmnd_set_filter.s
.import cmnd_set_filter

; From cmnd_set_message.s
.import cmnd_set_message
.import message_display
.import status_display

; From debug
.import PrintHexByte

; From dbf.lib
;.import dbf_set_fields
.import set_deleted

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

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"

	.segment "DATA"
		; 4x8 = 32 options possibles
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
; SET ALTERNATE | BELL | CARRY | CATALOG | COLON | CONFIRM | CONSOLE
;     DEBUG | DELETE | DELIMITERS | ECHO | EJECT | ENCRYPT | ESCAPE
;     EXACT | FIELDS | FIXED | HEADING | HELP | HISTORY | INTENSITY
;     MENUS | LINKAGE | PRINT | STATUS | STEP | TALK | TITLE
;     DELETED | DOHISTORY | SAFETY | SCOREBOARD | UNIQUE | CENTURY
;     CURSOR
;
; Entrée:
;	A: n° de token 'SET'
;	X: offset des paramètres (ON, OFF, TO)
;	Y: offset vers la fin de la ligne ou l'argument du paramètre (TO ...)
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
		; TO?
		lda	on_off_flag
		cmp	#$02
		beq	set_to

		; SET OPTION <expr>
		cmp	#$ff
		bne	set1
		jmp	set_

		; Ici syntaxe: SET option ON | OFF
	set1:
		lda	opt_num
		cmp	#_OPT_TO_
		bcs	error10

		; Vérifie qu'il n'y a rien après ON | OFF
		lda	(line_ptr),y
		bne	error10

		lda	opt_num
		jsr	get_option_byte

		; OFF?
		lda	on_off_flag
		beq	set_off

	set_on:
		lda	options,x
		ora	bits_table_1,y
		sta	options,x

		; Traitements spécifiques
		lda	opt_num
		jmp	set_option_on

	error10:
		; 10 Syntax error.
		sec
		lda	#10
		rts

	set_off:
		; Off
		; lda	bits_table_1,y
		; ora	#$ff
		lda	bits_table_0,y
		and	options,x
		sta	options,x

		; Traitements spécifiques
		lda	opt_num
		jmp	set_option_off

	set_to:
		; ALTERNATE | CATALOG | DATE | DELIMITERS | DEVICE | FIELDS | HEADING |
		; HISTORY | PRINT | MARK
		lda	opt_num
		cmp	#_OPT_ON_OFF_TO_
		bcc	error10

		cmp	#_OPT_TO_
		bcc	set_on_off_to

		cmp	#_OPT_EXPR_
		bcs	set_

		; Ici syntaxe: SET xxx TO...
		cmp	#OPT_FILTER
		bne	set_message
		jmp	cmnd_set_filter

	set_message:
		cmp	#OPT_MESSAGE
		bne	error10
		jmp	cmnd_set_message

	set_:
		; Ici syntaxe: SET OPTION <expr>
		lda	opt_num
		cmp	#OPT_DATE
		bne	error10

		jmp	cmnd_set_date
	;	clc
	;	rts

	set_on_off_to:
		lda	opt_num
		cmp	#OPT_FIELDS
		bne	error10

		lda	on_off_flag
		jmp	cmnd_set_fields

	;	; SET xxx ON | OFF | TO
	;	lda	(line_ptr),y
	;	beq	set_to_default

	;	; SET xxx TO ...

	;set_to_default:
	;	; SET xxx TO
	;	clc
	;	rts
.endproc


;----------------------------------------------------------------------
;
; Entrée:
;	-
;
; Sortie:
;	-
;
; Variables:
;	Modifiées:
;		-
;
;	Utilisées:
;		-
;
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc set_option_on

	fields_on:
		cmp	#OPT_FIELDS
		bne	status_on

		lda	on_off_flag
		jmp	cmnd_set_fields

	status_on:
		cmp	#OPT_STATUS
		bne	cursor_on
		; 24 lignes
		cputc	$0c
		lda	#$18
		sta	SCRFY

		lda	#$ff
		sta	global_status
		; Affiche le message de statut
		; Fait dans la boucle principale
		jsr	status_display
		jsr	message_display

		clc
		rts

	cursor_on:
		cmp	#OPT_CURSOR
		bne	deleted_on

		sta	global_cursor
		clc
		rts

		; Traitement spécifique pour set_deleted
	deleted_on:
		cmp	#OPT_DELETED
		bne	dbaserr_on

		; /!\ set_deleted de dbf.lib est à 0 si actif
		lda	#$00
		sta	set_deleted
		clc
		rts

		; Ajout perso
	dbaserr_on:
		cmp	#OPT_DBASERR
		bne	end

		lda	#$ff
		sta	global_dbaserr

	end:
		clc
		rts
.endproc


;----------------------------------------------------------------------
;
; Entrée:
;	-
;
; Sortie:
;	-
;
; Variables:
;	Modifiées:
;		-
;
;	Utilisées:
;		-
;
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc set_option_off
	fields_off:
		cmp	#OPT_FIELDS
		bne	status_off

		lda	on_off_flag
		jmp	cmnd_set_fields

	status_off:
		cmp	#OPT_STATUS
		bne	cursor_off
		; 27 lignes
		lda	#$1b
		sta	SCRFY
		cputc	$0c

		lda	#$00
		sta	global_status

		clc
		rts

		; Traitement spécifique pour le curseur
	cursor_off:
		cmp	#OPT_CURSOR
		bne	deleted_off

		lda	#$00
		sta	global_cursor
		clc
		rts

		; Traitement spécifique pour set deleted
	deleted_off:
		cmp	#OPT_DELETED
		bne	dbaserr_off

		; /!\ set_deleted de dbf.lib est <> 0 si inactif
		lda	#$ff
		sta	set_deleted
		clc
		rts

		; Ajout perso
	dbaserr_off:
		cmp	#OPT_DBASERR
		bne	end

		lda	#$00
		sta	global_dbaserr
	end:
		clc
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	-
;
; Sortie:
;	-
;
; Variables:
;	Modifiées:
;		-
;
;	Utilisées:
;		-
;
; Sous-routines:
;	-
;----------------------------------------------------------------------
;.proc set_fields
;		cmp	#$00
;		beq	fields_off
;
;		cmp	#$01
;		beq	fields_on
;
;		jmp	cmnd_set_fields
;
;	fields_off:
;		ldx	#$00
;		jmp	dbf_set_fields
;
;	fields_on:
;		ldx	#$ff
;		jmp	dbf_set_fields
;.endproc

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
