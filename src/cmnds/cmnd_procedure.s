
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
.import main_input_mode
.import ident

.import token_start
.import submit_line

.import linenum

.import fpos_text

.import _find_cmnd


; Pour debug
; .import PrintHexByte

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_procedure
.export reset_labels

.export forward_label, label_num
.export label_offsets, labels, label_line

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
; DEBUG = 1

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"

	.segment "DATA"
		; Offset dans la table labels
		unsigned char label_ofs
		; Table des labels
		unsigned char labels[LABEL_TABLE_SIZE]

		unsigned char label_num
		unsigned long label_offsets[MAX_LABELS]
		unsigned short label_line[MAX_LABELS]

		unsigned char forward_label

		; Pour debug
		unsigned char save_x
		unsigned char ptr
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
.proc cmnd_procedure
		lda	main_input_mode
		bne	define_proc
		; Pour debug
		beq	define_proc

	error95:
		; 95 Valid only in programs.
		lda	#95
		ldy	token_start
		sec
		rts

	define_proc:
		; token_start pointe sur le premier caractère du nom
		; de la procédure
		; Copie ident dans submit_line
		ldx	#$ff
	loop:
		inx
		lda	ident,x
		sta	submit_line,x
		bne	loop

		lda	#<labels
		ldy	#>labels
		ldx	#$00
		jsr	_find_cmnd
		bcc	found

	not_found:
		; Nombre maximal de labels atteint?
		lda	label_num
		cmp	#MAX_LABELS
		bcs	error105

		ldy	label_ofs
		dey
		ldx	#$ff

	loop_not_found:
		inx
		iny
		lda	ident,x
		sta	labels, y
		bne	loop_not_found

		; Dernier caractère +$80
		dey
		lda	labels, y
		ora	#$80
		sta	labels, y

		; Marque la fin de la table
		iny
		lda	#$00
		sta	labels, y

		sty	label_ofs

		; Sauvegarde le numéro de la ligne suivante du label
		lda	label_num
		asl
		tax
		lda	linenum
		sta	label_line,x
		lda	linenum+1
		sta	label_line+1,x

		; Sauvegarde l'offset de la ligne suivant le label
		txa
		asl
		tax
		lda	fpos_text
		sta	label_offsets,x
		lda	fpos_text+1
		sta	label_offsets+1,x
		lda	fpos_text+2
		sta	label_offsets+2,x
		lda	fpos_text+3
		sta	label_offsets+3,x

		inc	label_num
	end:
		clc
		rts

	found:
		asl
		asl
		tax
		lda	fpos_text
		cmp	label_offsets,x
		bne	error144

		lda	fpos_text+1
		cmp	label_offsets+1,x
		bne	error144

		lda	fpos_text+2
		cmp	label_offsets+2,x
		bne	error144

		lda	fpos_text+3
		cmp	label_offsets+3,x
		bne	error144

		clc
		rts

	error43:
		; 43 Insufficient memory.

	error64:
		; 64 Internal error:

	error105:
		; 105 Table is full.
		lda	#105
		ldy	token_start
		sec
		rts

	error144:
		; 144 Unauthorized duplicate.
		lda	#144
		ldy	token_start
		sec
		rts
.endproc

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
.proc reset_labels
		lda	#$00
		sta	label_ofs
		sta	label_num
		sta	labels
		lda	#$01
		sta	forward_label

		clc

		rts
.endproc

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
.ifdef DEBUG
	.export cmnd_dump
	.proc cmnd_dump
			ldx	#$00
			stx	ptr
			stx	save_x

			lda	label_num
			beq	end

		again:
			; Affiche la ligne du label
			lda	labels,x
			beq	end
			lda	ptr
			asl
			tax
			; [ si linenum en binaire
			lda	label_line+1,x
			tay
			lda	label_line,x
			ldx	#$03
			.byte	$00, XDECIM
			; ]
			; [ si linenum en BCD
			; lda	label_line+1,x
			; jsr	PrintHexByte
			; lda	label_line,x
			; jsr	PrintHexByte
			; ]
			cputc	':'

			ldx	save_x
		loop:
			lda	labels,x
			beq	end
			bmi	last
			cputc
			inx
			bne	loop
			beq	end

		last:
			and	#$7f
			cputc
			inx
			stx	save_x


			; Affiche l'offset du label
	;		lda	ptr
	;		asl
	;		asl
	;		tax
	;		lda	label_offsets+1,x
	;		tay
	;		lda	label_offsets, x
	;		ldx	#$03
	;		.byte	$00, XDECIM

			crlf

			inc	ptr
			ldx	save_x
			bne	again

		end:
			prints	"\r\nTable size: "
			lda	save_x
			ldy	#$00
			ldx	#$02
			.byte	$00, XDECIM
			cputc	'/'

			lda	#LABEL_TABLE_SIZE
			ldy	#$00
			ldx	#$02
			.byte	$00, XDECIM

			crlf

			clc
			rts
	.endproc
.endif
