
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
.include "case.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
; From yacc.s
.import token_start

.import ident
.import string
.importzp pfac
.import bcd_value
.import logic_value
.import param_type

.import var_search
.import var_list
.import var_getvalue
.import var_set_callback

.import clear_entry

.importzp object
.import entry
.import keylen

.import fn_str
.import fn_dtoc
.import fn_ltoc

.import _find_cmnd
.import submit_line

.import opt_display

; From cmnd_display_status
.import cmnd_display_status

; From fn_isopen.s
;.import fn_isopen

; From cmnd_set.s
.import get_option

; From dbf.lib
.import dbf_isopen
.import dbf_display_struct
.import dbf_display_header
.import dbf_display_record
.import dbf_list_record
.import dbf_display_headings

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_display

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
		unsigned short work_ptr

	.segment "DATA"
;		unsigned char save_a
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
; DISPLAY <> | FILES | HISTORY | MEMORY | STATUS | STRUCTURE | <liste>
;
; Entrée:
;	A : token_number (n° de la commande)
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
.proc cmnd_display
;		sty	save_y

;		lda	param_type
;		beq	display_memory
		lda	ident
		beq	display_record

		ldx	#$ff
	loop_id:
		inx
		lda	ident,x
		sta	submit_line,x
		bne	loop_id

		lda	#<opt_display
		ldy	#>opt_display
		ldx	#$00
		jsr	_find_cmnd
		bcs	variable

		; 0: "FILES"
		; 1: "HISTORY"
		; 2: "MEMORY"
		; 3: "STATUS"
		; 4: "STRUCTURE"
		cmp	#$02
		; bne	error10
		beq	display_memory

		cmp	#$03
		beq	display_status

		cmp	#$04
		beq	display_structure

		jmp	variable

	display_memory:
		; Initialise la routine d'affichage d'une entrée
		lda	#<display_entry
		ldy	#>display_entry
		jsr	var_set_callback

		jsr	var_list
	end_noerror:
		clc
		rts

	display_status:
	;	jsr	dbf_isopen
	;	bne	error52

	;	jsr	dbf_display_header
	;	clc
	;	rts
		jmp	cmnd_display_status

	display_structure:
		jsr	dbf_isopen
		bne	error52
		jsr	dbf_display_header
		jsr	dbf_display_struct
		cmp	#EOK
		beq	end_noerror

		; 52: No databse is in USE.
	error52:
		lda	#52
		bne	end_error

	variable:

		; Initialise entry
		jsr	clear_entry
		; On suppose que sizeof(ident) = keylen
		ldx	#$ff
	loop:
		inx
		lda	ident,x
		sta	entry,x
		bne	loop

;		lda	#$00
;	loop1:
;		cpx	keylen
;		bcs	display_var
;		inx
;		sta	entry,x
;		jmp	loop1

	display_var:
		lda	#<entry
		sta	object
		ldy	#>entry
		sty	object+1

		jsr	var_search
		bne	error12

		jsr	var_getvalue
		jsr	display_entry
		clc
		rts

	display_record:
		jsr	dbf_isopen
	;	bcs	error52
		bne	error52
		; [ Affichage en ligne (DISPLAY)
		lda	#OPT_HEADINGS
		jsr	get_option
		beq	no_headings

		jsr	dbf_display_headings

	no_headings:
		jsr	dbf_list_record
		; ]
		; [ Affichage en colonne
		;jsr	dbf_display_record
		; ]
		clc
		rts

	error12:
		;prints	"unknown variable: "
		;print	ident
		; 12 Variable not found.
		lda	#12
	end_error:
		ldy	token_start
		sec
		rts

;	error10:
;		; 10 Syntax error.
;		lda	#10
;		ldy	token_start
;		sec
;		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	object: pointeur vers la variable
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
.proc display_entry
		; Passe le nom de la variable en minuscules
		; [ save to
;		ldx	#$ff
;		ldy	#st_entry::name
;		dey
;	loop:
;		inx
;		iny
;		lda	(object),y
;		sta	string,x
;		bne	loop
;
;		jsr	fn_lower
;
;		print	string
;		cputc	' '
;		cputc	'='
;		cputc	' '
		; ]
		; [ display
		print	(object)
	loopTab:
		cputc	' '
		ldx	SCRX
		cpx	#(IDENT_LEN+2)
		bcc	loopTab
		; ]


		; Pointeur vers la donnée
		ldy	#st_entry::data_ptr
		lda	(object),y
		sta	work_ptr
		iny
		lda	(object),y
		sta	work_ptr+1

		; Type de la variable
		ldy	#st_entry::type
		lda	(object),y
		and	#$7f

		; [ display
		pha

		cputc
		cputc	' '

		; Affiche la taille de la variable
		ldy	#st_entry::len
		lda	(object),y
		ldy	#$00
		ldx	#$01
		.byte	$00, XDECIM

		cputc	' '
		pla
		; ]

		do_case
			case_of 'C'
					; [ display
					cputc	'"'
					; ]
					ldy	#$ff
				loopC:
					iny
					lda	(work_ptr),y
					sta	string,y
					bne	loopC
					sec

			case_of 'N'
					ldy	#$03
				loopN:
					lda	(work_ptr),y
					sta	pfac,y
					dey
					bpl	loopN

					jsr	fn_str

			case_of 'D'
					ldy	#$03
				loopD:
					lda	(work_ptr),y
					sta	bcd_value,y
					dey
					bpl	loopD

					jsr	fn_dtoc

			case_of 'L'
					ldy	#$00
					lda	(work_ptr),y
					sta	logic_value

					jsr	fn_ltoc
		end_case

		; [ save to
;		print	string
		; ]
		; [ display
		php
		print	string
		plp

		bcc	end

		cputc	'"'
		; ]

	end:
		crlf

		rts
.endproc

