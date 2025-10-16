
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

; From lex
.import ident
.import get_ident
.import skip_spaces
.import lex_save_y

.import on_off_flag

; From fns
.import fn_isopen

; From cmnd_set
.import opt_num
.import cmnd_set

; From dbf.lib
.import fieldname_to_fieldnum
.import dbf_set_fields
.import dbf_set_fields_all
.import field

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_set_fields

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
.if 1
	.proc cmnd_set_fields
			jsr	fn_isopen
			bcs	error52

			; OFF?
			cmp	#$00
			beq	fields_off

			; ON?
			cmp	#$01
			bne	set_fields

		fields_on:
			ldx	#$ff

		fields_on_off:
			jsr	dbf_set_fields
			bcs	error47
			rts

		fields_off:
			tax
			; Saut inconditionnel
			beq	fields_on_off

		error47:
			; fichier au format dBase II, pas de champ SET_FIELD
			; 47: No fields to process.
			lda	#47
			rts

		error10:
			; 10: Syntax error
			lda	#10
			bne	end_error

		error48:
			; 12: Field not found
			lda	#12
			bne	end_error

		error52:
			; 52: No database is in USE.
			lda	#52

		end_error:
		save_y:
			ldy	#$ff
		end_err:
			sec
			rts

			; TO
		set_fields:
			lda	(line_ptr),y
			beq	set_default

		; loopFields:
			; Attend un identificateur
			; C=0 -> délimiteur = n'importe quel caractère non alphanum
			; V=0 -> conversion minuscules / MAJUSCULES
			ldx	line_ptr+1

		loopFields:
			; Inutile de restaure X dans la boucle, on revient ici après un jsr skip_space
			lda	line_ptr
			clc
			clv
			jsr	get_ident
			bcs	error10

			; Sauvegarde A pour optimisation
			sta	save_a+1
			sty	save_y+1

			; Initialise 'field'
			ldx	#11
			lda	#$00
		loop_clear:
			sta	field,x
			dex
			bpl	loop_clear

			; ldx	#$ff
		loop:
			inx
			lda	ident,x
			sta	field,x
			bne	loop

			jsr	fieldname_to_fieldnum
			bcs	error48

			; X: numéro du champ
			jsr	dbf_set_fields

			;       A: type du champ
			;       Y: longueur du champ
			;       X: numéro du champ
			;       C: 0-> trouvé, 1-> non trouvé
			;       fn_zptr: pointeur vers la donnée
			;       field_value: donnée

			; Ne dois pas arriver
			bcs	error48

			; Fin de la ligne?
		save_a:
			; Optimisation
			lda	save_a
			beq	end

			; Saute les espaces
			ldy	save_y+1
			lda	line_ptr
			ldx	line_ptr+1
			jsr	skip_spaces
			beq	end

			; ','?
			cmp	#','
			bne	err10

			; Saute les espaces
			iny
			lda	line_ptr
			jsr	skip_spaces
			bne	loopFields

		err10:
			lda	#10
			bne	end_err

		end:
			; Force SET FIELDS ON
			; Note: fait cmnd_set -> cmnd_set_fields
			lda	#OPT_FIELDS
			sta	opt_num
			lda	#$01
			sta	on_off_flag
			jmp	cmnd_set
			; clc
			; rts

		set_default:
			jsr	dbf_set_fields_all
			clc
			rts
	.endproc
.else
	.proc cmnd_set_fields
			jsr	fn_isopen
			bcs	error52

			; Initialise 'field'
			ldx	#11
			lda	#$00
		loop_clear:
			sta	field,x
			dex
			bpl	loop_clear

			; ldx	#$ff
		loop:
			inx
			lda	ident,x
			sta	field,x
			bne	loop

			jsr	fieldname_to_fieldnum
			bcs	error12

			; X: numéro du champ
			jsr	dbf_set_fields

			;       A: type du champ
			;       Y: longueur du champ
			;       X: numéro du champ
			;       C: 0-> trouvé, 1-> non trouvé
			;       fn_zptr: pointeur vers la donnée
			;       field_value: donnée

			; Ne dois pas arriver
			bcs	error12

		end:
			clc
			rts

		error48:
			; 12: Variable not found
			lda	#12
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
.endif

