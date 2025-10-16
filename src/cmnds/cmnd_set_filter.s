
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
; From main.s
.importzp line_ptr
.import submit_line

; From lex
.importzp lex_ptr
.import cond_value
.import get_expr_logic

; From fns
.import fn_isopen

; From cmnd_set
.import opt_num

; From dbf.lib
.import dbf_set_callback_list
.import dbf_set_callback_filter
.import dbf_list_record
.import dbf_record_filter

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_set_filter

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
		; unsigned char filter[128]
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
; SET FILTER TO [<condition>] | [FILE <filename> | ?]
;
; Entrée:
;	A: numéro option (OFF, ON, TO)
;	X: -
;	Y: offset vers le paramètre
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
.proc cmnd_set_filter
		sty	save_y+1

		jsr	fn_isopen
		bcc	set_filter

	error52:
		; 52: No database is in USE.
		lda	#52

	end_error:
		sec
	save_y:
		ldy	#$ff
	end_err:
		rts

	error10:
		; 10: Syntax error
		lda	#10
		bne	end_error

		; TO
	set_filter:
		lda	(line_ptr),y
		beq	set_default

		; Filtre = ''
		lda	#$00
		sta	dbf_record_filter
		; Vérifie la syntaxe du filter
		jsr	get_expr_logic
		bcs	end_err

		; Fin de ligne après le filtre?
		lda	(line_ptr),y
		bne	error10

		; Sauvegarde l'offset
		tya
		tax

		; Copie du filtre
		ldy	save_y+1
		stx	save_y+1
		ldx	#$ff
		dey
	loop:
		iny
		inx
		lda	(line_ptr),y
		sta	dbf_record_filter,x
		bne	loop

		; Callback pour dbf_list
		lda	#<record_filter
		ldy	#>record_filter
	;	lda	#<list_filter
	;	ldy	#>list_filter
		jsr	dbf_set_callback_filter
		; Restaure l'offset
		txa
		tay
		clc
		rts

	set_default:
		sta	dbf_record_filter
		; Restaure callback par défaut
		tay
		jsr	dbf_set_callback_filter

		; Restaure l'offset
		ldy	save_y+1
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
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
; /!\ ATTENTION: écrase submit_line
;----------------------------------------------------------------------
.proc record_filter
		lda	lex_ptr
		pha
		lda	lex_ptr+1
		pha

		; Copie le filtre dans submit_line
		ldy	#$ff
	loop:
		iny
		lda	dbf_record_filter,y
		sta	submit_line,y
		bne	loop

		lda	#<submit_line
		sta	lex_ptr
		lda	#>submit_line
		sta	lex_ptr+1

		ldy	#$00
		jsr	get_expr_logic
		bcs	error

		lda	cond_value
	;	beq	end

	;	; [ HACK TEMPORAIRE, il faudrait récupérer la routine
	;	;  active avant le dbf_set_callback
	;	jsr	dbf_list_record
	;	; ]
		clc

	end:
	error:
		; Sauvegarde le code erreur
		tax

		; Restaure lex_ptr
		pla
		sta	lex_ptr+1
		pla
		sta	lex_ptr

		; Restaure le code erreur
		txa
		; sec
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	-
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
; /!\ ATTENTION: écrase submit_line
;----------------------------------------------------------------------
.proc list_filter
		jsr	record_filter
		bcs	error

		beq	end

		jsr	dbf_list_record

	end:
	error:
		rts
.endproc

