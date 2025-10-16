.ifdef SUBMIT
	;----------------------------------------------------------------------
	;			includes cc65
	;----------------------------------------------------------------------
	.feature string_escapes

	.include "telestrat.inc"
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

	;----------------------------------------------------------------------
	;				imports
	;----------------------------------------------------------------------
	.ifdef LABEL_CHR
		.import cmnd_label
	.else
		.import cmnd_table
	.endif

	.import skip_spaces
	.import submit

	.importzp line_ptr

	.import token_start
	.import input_mode

	.import ident
	.import ident1
	.import submit_line

	.import find_cmnd
	.import _find_cmnd

	.import fgetline
	.import buffer_reset
	.import fpos
	.import fpos_text
	.import fpos_prev
	.import push
	.import pop

	.import linenum

	.import labels
	.import label_num
	.import label_offsets
	.import label_line
	.import forward_label

	;----------------------------------------------------------------------
	;				exports
	;----------------------------------------------------------------------
	.export cmnd_goto

	;----------------------------------------------------------------------
	;			Defines / Constantes
	;----------------------------------------------------------------------
	;.ifndef SUBMIT
	;	; Défini dans dbase.inc
	;	TOKEN_PROCEDURE = 23
	;.endif

	;----------------------------------------------------------------------
	;				Variables
	;----------------------------------------------------------------------
	.pushseg
		.segment "DATA"
	.popseg

	;----------------------------------------------------------------------
	;			Programme principal
	;----------------------------------------------------------------------
	.segment "CODE"

	;----------------------------------------------------------------------
	;
	; Entrée:
	;	-
	; Sortie:
	;	-
	; Variables:
	;	Modifiées
	;		-
	;	Utilisées:
	;		-
	; Sous-routines:
	;	-
	;----------------------------------------------------------------------
	.proc cmnd_goto
			lda	input_mode
			bne	search_proc
			; Pour debug
			beq	search_proc

		error95:
			; 95 Valid only in programs.
			lda	#95
			ldy	token_start
			sec
			rts

		search_proc:
			lda	token_start
			sta	my_token_start+1

			; Copie ident dans submit_line et dans ident1
			ldx	#$ff
		loop:
			inx
			lda	ident,x
			sta	ident1,x
			sta	submit_line,x
			bne	loop

			; Table des labels vide?
			lda	label_num
			beq	not_found

			lda	#<labels
			ldy	#>labels
			ldx	#$00
			jsr	_find_cmnd
			bcs	not_found

		found:
			; Récupère le numéro de ligne
			asl
			tax
			lda	label_line,x
			sta	linenum
			lda	label_line+1,x
			sta	linenum+1

			; Récupère l'offser du label
			txa
			asl
			tax
			lda	label_offsets,x
			sta	fpos
			sta	fpos_text
			lda	label_offsets+1,x
			sta	fpos+1
			sta	fpos_text+1
			lda	label_offsets+2,x
			sta	fpos+2
			sta	fpos_text+2
			lda	label_offsets+3,x
			sta	fpos+3
			sta	fpos_text+3

			jsr	buffer_reset

			clc
			rts


		not_found:
			; On parcourt le fichier jusqu'à ce qu'on trouve le label
			; ou la fin du fichier
			lda	forward_label
			beq	error82

			; [ Sauvegarde la position de l'instruction goto en cas d'erreur
	;		ldy	#$03
	;	loop_fpos:
	;		lda	fpos_prev,y
	;		sta	fpos_text,y
	;		dey
	;		bpl	loop_fpos
			; ]

			jsr	push

		next:
			jsr	fgetline
			bcs	error82b

			ldx	#LINE_MAX_SIZE
			sta	line_ptr
			sty	line_ptr+1
	;		jsr	submit
	;		bcs	error82b

	;		lda	line_ptr
	;		ldx	line_ptr+1
	;		ldy	#$00
	;		jsr	skip_spaces

			; Ligne vide
			ldy	#$00
			lda	(line_ptr),y
			beq	next

	;		cmp	#REM_CHR
	;		beq	next

		.ifdef LABEL_CHR
				; [ Specifique submit
				; ':' obligatoirement en première colonne
				cmp	#LABEL_CHR
				bne	next

				; Expansion des variables (compatibilité submit)
				;ldx	#LINE_MAX_SIZE
				;sta	line_ptr
				;sty	line_ptr+1
				jsr	submit
				bcs	error82b

				; Définition du label
				lda	line_ptr
				ldx	line_ptr+1
				ldy	#$00
				jsr	cmnd_label
				bcs	error
				; ]
		.else
				; [ sinon
				; Expansion des variables
				;ldx	#LINE_MAX_SIZE
				;sta	line_ptr
				;sty	line_ptr+1
				jsr	submit
				bcs	error82b

				lda	line_ptr
				ldx	line_ptr+1
				ldy	#$00
				jsr	skip_spaces

				; Ligne vide?
				lda	(line_ptr),y
				beq	next

				cmp	#REM_CHR
				beq	next

				; Chercher dans la table cmnd_table et vérifier
				; si il s'agit de l'instruction PROCEDURE
				lda	#<cmnd_table
				ldx	#>cmnd_table
				jsr	find_cmnd
				bcs	error
				cmp	#TOKEN_PROCEDURE
				bne	error
				; ]
		.endif

			ldx	#$ff
		loop1:
			inx
			lda	ident1,x
			sta	submit_line,x
			bne	loop1

			lda	#<labels
			ldy	#>labels
			ldx	#$00
			jsr	_find_cmnd
			bcs	next
			jsr	pop
			bcs	error82b
			jmp	found

		error82b:
			jsr	pop
			jsr	fgetline

		error82:
			; 13 ALIAS not found.
			; 31 Invalid function name.
			; 54 Label file invalid.

			; 82 ** Not Found **
			lda	#82

			; token_start pointe sur le premier caractère du nom
			; de la procédure
		my_token_start:
			ldy	#$00
			sec
			rts

		error:
			pha
			jsr	error82b
			pla
			rts
	.endproc
.endif
